/**
 * Reference implementation of the `$sqlquery-run` operation.
 *
 * Resolves a SQLQuery Library, materialises each ViewDefinition dependency
 * into a temporary in-memory SQLite table named after the artifact's `label`,
 * executes the Library's SQL with named parameter bindings, and returns the
 * result in the requested format (json, ndjson, csv, fhir).
 *
 * Author: John Grimes
 */

import sqlite3 from 'sqlite3'
import { read, search } from './db.js'
import { evaluate } from '../index.js'
import { layout } from './ui.js'
import { isHtml, renderOperationDefinition, wrapBundle } from './utils.js'

// Map a FHIR Library.parameter.type to the corresponding `value[x]` field
// name on a Parameters.parameter entry.
const fhirTypeToValueField = {
  string: 'valueString',
  code: 'valueCode',
  integer: 'valueInteger',
  integer64: 'valueInteger64',
  decimal: 'valueDecimal',
  boolean: 'valueBoolean',
  date: 'valueDate',
  dateTime: 'valueDateTime',
  time: 'valueTime',
  instant: 'valueInstant',
}

// Map a ViewDefinition column type to a SQLite column-affinity declaration
// used when creating temp tables.
const fhirTypeToSqliteAffinity = {
  boolean: 'INTEGER',
  integer: 'INTEGER',
  integer64: 'INTEGER',
  decimal: 'REAL',
}

// Map a ViewDefinition column type to the `value[x]` field used when
// encoding rows for the `_format=fhir` response.
const viewTypeToValueField = {
  boolean: 'valueBoolean',
  integer: 'valueInteger',
  integer64: 'valueInteger64',
  decimal: 'valueDecimal',
  string: 'valueString',
  code: 'valueString',
  date: 'valueDate',
  dateTime: 'valueDateTime',
  time: 'valueTime',
  instant: 'valueInstant',
  base64Binary: 'valueBase64Binary',
}

class SqlQueryRunError extends Error {
  constructor(status, code, message) {
    super(message)
    this.status = status
    this.code = code
  }
}

function operationOutcome(code, message) {
  return {
    resourceType: 'OperationOutcome',
    issue: [{ severity: 'error', code, diagnostics: message }],
  }
}

function sendError(res, err) {
  if (err instanceof SqlQueryRunError) {
    res.status(err.status).json(operationOutcome(err.code, err.message))
    return
  }
  console.error('$sqlquery-run unexpected error', err)
  res.status(500).json(operationOutcome('exception', err.message || String(err)))
}

// Pick a single named input from a Parameters resource.
function getInputParameter(parametersResource, name) {
  if (!parametersResource || !Array.isArray(parametersResource.parameter)) return null
  return parametersResource.parameter.find((p) => p.name === name) || null
}

/**
 * Read the SQL string from the Library's first content entry.
 * Prefers the `sql-text` extension, falls back to base64-decoded `data`.
 *
 * @param {object} library - SQLQuery Library resource.
 * @returns {string} the SQL text.
 * @throws {SqlQueryRunError} when no SQL can be located.
 */
export function extractSql(library) {
  const content = library?.content?.[0]
  if (!content) {
    throw new SqlQueryRunError(422, 'invalid', 'Library has no content[0] entry with SQL')
  }
  const sqlTextExt = (content.extension || []).find(
    (e) => e.url === 'https://sql-on-fhir.org/ig/StructureDefinition/sql-text',
  )
  if (sqlTextExt && typeof sqlTextExt.valueString === 'string') {
    return sqlTextExt.valueString
  }
  if (typeof content.data === 'string') {
    return Buffer.from(content.data, 'base64').toString('utf8')
  }
  throw new SqlQueryRunError(422, 'invalid', 'Library content[0] has no sql-text extension or data')
}

/**
 * Resolve the SQLQuery Library to execute.
 *
 * Resolution priority:
 *   1. instance route `id` → server-stored Library by id.
 *   2. `queryReference` → reference like "Library/<id>" or canonical URL.
 *   3. `queryResource` → inline Library resource.
 */
async function resolveLibrary({ id, queryReference, queryResource, config }) {
  if (id) {
    const library = await read(config, 'Library', id)
    if (!library) {
      throw new SqlQueryRunError(404, 'not-found', `Library/${id} not found`)
    }
    return library
  }
  if (queryReference) {
    const ref = queryReference.reference || queryReference
    if (typeof ref !== 'string') {
      throw new SqlQueryRunError(400, 'invalid', 'queryReference must be a Reference with a reference string')
    }
    // Match either "Library/<id>" or a canonical URL whose final segment is the id.
    const segment = ref.split('/').pop()
    const libraries = await search(config, 'Library', 1000)
    const byUrl = libraries.find((l) => l.url === ref)
    if (byUrl) return byUrl
    const byId = libraries.find((l) => l.id === segment)
    if (byId) return byId
    throw new SqlQueryRunError(404, 'not-found', `Library not found for reference '${ref}'`)
  }
  if (queryResource) {
    if (queryResource.resourceType !== 'Library') {
      throw new SqlQueryRunError(400, 'invalid', 'queryResource must be a Library resource')
    }
    return queryResource
  }
  throw new SqlQueryRunError(
    400,
    'required',
    'Provide queryReference, queryResource, or use the instance route',
  )
}

/**
 * Resolve a ViewDefinition referenced from a Library.relatedArtifact entry.
 * Tries an exact url match first, then falls back to id by trailing segment.
 */
async function resolveViewDefinition(config, ref) {
  const all = await search(config, 'ViewDefinition', 1000)
  const byUrl = all.find((v) => v.url === ref)
  if (byUrl) return byUrl
  const segment = (ref || '').split('/').pop()
  const byId = all.find((v) => v.id === segment)
  if (byId) return byId
  return null
}

// Pull rows for a ViewDefinition by reading its source resources and
// applying the existing `evaluate()` engine.
async function evaluateView(config, viewDef) {
  const data = await search(config, viewDef.resource, 1000)
  return evaluate(viewDef, data)
}

// Build column metadata for a ViewDefinition by walking its select tree.
// Returns an array of { name, type } in column order.
function viewColumns(viewDef) {
  const cols = []
  const walk = (node) => {
    if (!node) return
    if (Array.isArray(node.column)) {
      node.column.forEach((c) => cols.push({ name: c.name || c.path, type: c.type || 'string' }))
    }
    if (Array.isArray(node.select)) node.select.forEach(walk)
    if (Array.isArray(node.unionAll)) node.unionAll.forEach(walk)
    if (Array.isArray(node.forEach)) node.forEach.forEach(walk)
  }
  if (Array.isArray(viewDef.select)) viewDef.select.forEach(walk)
  return cols
}

function columnAffinity(type) {
  return fhirTypeToSqliteAffinity[type] || 'TEXT'
}

// Coerce a JS value into something SQLite accepts (booleans → 0/1).
function coerceForSqlite(value) {
  if (value === null || value === undefined) return null
  if (typeof value === 'boolean') return value ? 1 : 0
  if (typeof value === 'object') return JSON.stringify(value)
  return value
}

// Execute a SQLite operation and return its result as a Promise.
function dbRun(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err)
      else resolve(this)
    })
  })
}

function dbAll(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err)
      else resolve(rows)
    })
  })
}

function dbClose(db) {
  return new Promise((resolve) => db.close(() => resolve()))
}

/**
 * Materialise each `relatedArtifact[type=depends-on]` ViewDefinition into a
 * table on the supplied SQLite connection. Returns a map of label → column
 * metadata used later for the `_format=fhir` response.
 */
async function materialiseDependencies(library, config, queryDb) {
  const labelToColumns = {}
  const deps = (library.relatedArtifact || []).filter((a) => a.type === 'depends-on')
  for (const dep of deps) {
    const label = dep.label
    if (!label) {
      throw new SqlQueryRunError(
        422,
        'invalid',
        `relatedArtifact for ${dep.resource} is missing required 'label'`,
      )
    }
    const viewDef = await resolveViewDefinition(config, dep.resource)
    if (!viewDef) {
      throw new SqlQueryRunError(404, 'not-found', `ViewDefinition '${dep.resource}' not found`)
    }
    const columns = viewColumns(viewDef)
    if (columns.length === 0) {
      throw new SqlQueryRunError(422, 'invalid', `ViewDefinition '${dep.resource}' declares no columns`)
    }
    labelToColumns[label] = columns

    const colDdl = columns.map((c) => `"${c.name}" ${columnAffinity(c.type)}`).join(', ')
    await dbRun(queryDb, `CREATE TABLE "${label}" (${colDdl})`)

    const rows = await evaluateView(config, viewDef)
    if (rows.length > 0) {
      const placeholders = columns.map(() => '?').join(', ')
      const colList = columns.map((c) => `"${c.name}"`).join(', ')
      const insertSql = `INSERT INTO "${label}" (${colList}) VALUES (${placeholders})`
      // Use a transaction so the inserts are batched.
      await dbRun(queryDb, 'BEGIN')
      try {
        for (const row of rows) {
          const values = columns.map((c) => coerceForSqlite(row[c.name]))
          await dbRun(queryDb, insertSql, values)
        }
        await dbRun(queryDb, 'COMMIT')
      } catch (err) {
        await dbRun(queryDb, 'ROLLBACK').catch(() => {})
        throw err
      }
    }
  }
  return labelToColumns
}

/**
 * Bind nested Parameters input to SQLite named-parameter values.
 * Validates that each name matches a Library.parameter declaration and that
 * the supplied value[x] type matches the declared type.
 */
export function bindParameters(library, parametersResource) {
  if (!parametersResource) return {}
  if (parametersResource.resourceType !== 'Parameters') {
    throw new SqlQueryRunError(400, 'invalid', "'parameters' input must be a Parameters resource")
  }
  const declared = library.parameter || []
  const bindings = {}
  for (const part of parametersResource.parameter || []) {
    const decl = declared.find((p) => p.name === part.name)
    if (!decl) {
      throw new SqlQueryRunError(
        400,
        'invalid',
        `Unknown parameter '${part.name}' (not declared in Library.parameter)`,
      )
    }
    const expectedField = fhirTypeToValueField[decl.type]
    if (!expectedField) {
      throw new SqlQueryRunError(
        400,
        'invalid',
        `Unsupported declared parameter type '${decl.type}' for '${part.name}'`,
      )
    }
    if (part[expectedField] === undefined) {
      throw new SqlQueryRunError(
        400,
        'invalid',
        `Parameter '${part.name}' expects ${expectedField} (declared type ${decl.type})`,
      )
    }
    let value = part[expectedField]
    if (decl.type === 'boolean') value = value ? 1 : 0
    else if (decl.type === 'integer64') {
      // FHIR JSON serialises integer64 as a string; coerce to a numeric
      // value so SQLite stores it with INTEGER affinity.
      const numeric = Number(value)
      if (!Number.isFinite(numeric)) {
        throw new SqlQueryRunError(
          400,
          'invalid',
          `Parameter '${part.name}' valueInteger64 '${value}' is not a valid integer`,
        )
      }
      value = numeric
    }
    bindings[`:${part.name}`] = value
  }
  return bindings
}

// Format an array of row objects in one of the supported flat formats.
function formatRows(rows, format, includeHeader) {
  if (format === 'json') {
    return { contentType: 'application/fhir+json', body: JSON.stringify(rows, null, 2) }
  }
  if (format === 'ndjson') {
    const body = rows.map((r) => JSON.stringify(r)).join('\n') + (rows.length ? '\n' : '')
    return { contentType: 'application/ndjson', body }
  }
  if (format === 'csv') {
    if (rows.length === 0) {
      return { contentType: 'text/csv', body: '' }
    }
    const cols = Object.keys(rows[0])
    const lines = []
    if (includeHeader) lines.push(cols.join(','))
    for (const row of rows) {
      lines.push(cols.map((c) => csvEscape(row[c])).join(','))
    }
    return { contentType: 'text/csv', body: lines.join('\n') }
  }
  throw new SqlQueryRunError(400, 'invalid', `Unsupported _format '${format}'`)
}

function csvEscape(value) {
  if (value === null || value === undefined) return ''
  const s = String(value)
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return '"' + s.replace(/"/g, '""') + '"'
  }
  return s
}

/**
 * Pick the FHIR `value[x]` field for a column, preferring the source
 * ViewDefinition column type and falling back to SQLite's runtime
 * typeof() for computed columns.
 */
function chooseFhirValueField(column, viewType, runtimeType) {
  if (viewType && viewTypeToValueField[viewType]) return viewTypeToValueField[viewType]
  switch (runtimeType) {
    case 'integer':
      return 'valueInteger'
    case 'real':
      return 'valueDecimal'
    case 'text':
      return 'valueString'
    case 'blob':
      return 'valueBase64Binary'
    case 'null':
      return null
    default:
      throw new SqlQueryRunError(
        422,
        'not-supported',
        `Unsupported SQL column type for '${column}' (runtime typeof '${runtimeType}')`,
      )
  }
}

// Build a Parameters resource for `_format=fhir` using per-column type info.
function formatFhir(rows, columnFhirTypes) {
  if (rows.length === 0) {
    return {
      contentType: 'application/fhir+json',
      body: JSON.stringify({ resourceType: 'Parameters' }, null, 2),
    }
  }
  const out = { resourceType: 'Parameters', parameter: [] }
  for (const row of rows) {
    const part = []
    for (const colName of Object.keys(row)) {
      const value = row[colName]
      if (value === null || value === undefined) continue
      const field = columnFhirTypes[colName]
      if (!field) {
        throw new SqlQueryRunError(
          422,
          'not-supported',
          `No FHIR type mapping resolved for column '${colName}'`,
        )
      }
      let coerced = value
      if (field === 'valueBoolean') coerced = !!value
      part.push({ name: colName, [field]: coerced })
    }
    out.parameter.push({ name: 'row', part })
  }
  return { contentType: 'application/fhir+json', body: JSON.stringify(out, null, 2) }
}

// Resolve, for each result column, the FHIR value[x] field to use.
// Combines source ViewDefinition column types (carried via labelToColumns)
// with SQLite runtime typeof() inspection of the first non-null sample.
async function resolveColumnFhirTypes(queryDb, sql, bindings, rows, labelToColumns) {
  if (rows.length === 0) return {}
  const colNames = Object.keys(rows[0])
  // Build a lookup of column-name → declared view type. Same column name
  // appearing in multiple views is rare in practice; first match wins.
  const viewTypeByName = {}
  for (const cols of Object.values(labelToColumns)) {
    for (const c of cols) {
      if (!(c.name in viewTypeByName)) viewTypeByName[c.name] = c.type
    }
  }
  // Probe runtime types using a single SELECT typeof(...) round-trip.
  const probeSelects = colNames.map((c) => `typeof("${c}") AS "${c}"`).join(', ')
  const probeSql = `SELECT ${probeSelects} FROM (${sql}) LIMIT 1`
  let runtimeRow = {}
  try {
    const probeRows = await dbAll(queryDb, probeSql, bindings)
    runtimeRow = probeRows[0] || {}
  } catch {
    // If the runtime probe fails (e.g. column quoting issue with computed
    // names), fall back to JS-level inference per-row.
    runtimeRow = inferRuntimeTypesFromRows(rows, colNames)
  }
  const fhirTypes = {}
  for (const c of colNames) {
    fhirTypes[c] = chooseFhirValueField(c, viewTypeByName[c], runtimeRow[c])
  }
  return fhirTypes
}

function inferRuntimeTypesFromRows(rows, colNames) {
  const guess = {}
  for (const c of colNames) {
    let runtime = 'null'
    for (const row of rows) {
      const v = row[c]
      if (v === null || v === undefined) continue
      if (typeof v === 'number') runtime = Number.isInteger(v) ? 'integer' : 'real'
      else if (typeof v === 'boolean') runtime = 'integer'
      else if (typeof v === 'string') runtime = 'text'
      else if (Buffer.isBuffer(v)) runtime = 'blob'
      else runtime = 'text'
      break
    }
    guess[c] = runtime
  }
  return guess
}

/**
 * Core execution: build an in-memory SQLite database, materialise dependencies,
 * bind parameters, run the SQL, format the response.
 */
async function executeSqlQueryRun({ library, parametersResource, format, header, config }) {
  const queryDb = new sqlite3.Database(':memory:')
  try {
    const labelToColumns = await materialiseDependencies(library, config, queryDb)
    const bindings = bindParameters(library, parametersResource)
    const sql = extractSql(library)
    let rows
    try {
      rows = await dbAll(queryDb, sql, bindings)
    } catch (err) {
      throw new SqlQueryRunError(422, 'processing', `SQL execution failed: ${err.message}`)
    }
    if (format === 'fhir') {
      const columnFhirTypes = await resolveColumnFhirTypes(queryDb, sql, bindings, rows, labelToColumns)
      return formatFhir(rows, columnFhirTypes)
    }
    return formatRows(rows, format, header)
  } finally {
    await dbClose(queryDb)
  }
}

// Pull the request inputs into a normalised shape for the core executor.
function extractInputs(parametersBody) {
  if (!parametersBody || parametersBody.resourceType !== 'Parameters') {
    throw new SqlQueryRunError(400, 'invalid', 'Request body must be a Parameters resource')
  }
  const formatParam = getInputParameter(parametersBody, '_format')
  if (!formatParam || !formatParam.valueCode) {
    throw new SqlQueryRunError(400, 'required', "Missing required input parameter '_format'")
  }
  const headerParam = getInputParameter(parametersBody, 'header')
  const queryRefParam = getInputParameter(parametersBody, 'queryReference')
  const queryResourceParam = getInputParameter(parametersBody, 'queryResource')
  const parametersParam = getInputParameter(parametersBody, 'parameters')
  return {
    format: formatParam.valueCode,
    header: headerParam ? headerParam.valueBoolean !== false : true,
    queryReference: queryRefParam?.valueReference || null,
    queryResource: queryResourceParam?.resource || null,
    parametersResource: parametersParam?.resource || null,
  }
}

async function postSqlQueryRun(req, res, { id } = {}) {
  try {
    const inputs = extractInputs(req.body)
    const library = await resolveLibrary({
      id,
      queryReference: inputs.queryReference,
      queryResource: inputs.queryResource,
      config: req.config,
    })
    const result = await executeSqlQueryRun({
      library,
      parametersResource: inputs.parametersResource,
      format: inputs.format,
      header: inputs.header,
      config: req.config,
    })
    res.setHeader('Content-Type', result.contentType)
    res.status(200).send(result.body)
  } catch (err) {
    sendError(res, err)
  }
}

export async function postSqlQueryRunSystem(req, res) {
  await postSqlQueryRun(req, res)
}

export async function postSqlQueryRunType(req, res) {
  await postSqlQueryRun(req, res)
}

export async function postSqlQueryRunInstance(req, res) {
  await postSqlQueryRun(req, res, { id: req.params.id })
}

// Escape user-supplied or resource-derived strings before inserting them into
// the HTML form output.
function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

// Pick the HTML input type that best fits a FHIR primitive parameter type.
function inputTypeForFhirType(type) {
  switch (type) {
    case 'integer':
    case 'integer64':
    case 'decimal':
      return 'number'
    case 'boolean':
      return 'checkbox'
    case 'date':
      return 'date'
    case 'dateTime':
    case 'instant':
      return 'datetime-local'
    case 'time':
      return 'time'
    default:
      return 'text'
  }
}

// Render a per-parameter input row for the instance form, driven by the
// declared `Library.parameter` entries.
function renderInstanceParameterFields(library) {
  const params = library.parameter || []
  if (params.length === 0) {
    return `<p class="text-sm text-gray-500">This Library declares no parameters.</p>`
  }
  const rows = params
    .map((p) => {
      const inputType = inputTypeForFhirType(p.type)
      const fieldName = `param_${p.name}`
      const input =
        inputType === 'checkbox'
          ? `<input type="checkbox" name="${escapeHtml(fieldName)}" value="true" />`
          : `<input type="${inputType}" name="${escapeHtml(fieldName)}" />`
      return `
        <tr>
          <td><code>${escapeHtml(p.name)}</code></td>
          <td>${escapeHtml(p.type)}</td>
          <td>${input}</td>
          <td class="text-xs text-gray-500">${escapeHtml(p.documentation || '')}</td>
        </tr>
      `
    })
    .join('')
  return `
    <table class="mt-2">
      <thead>
        <tr>
          <th>Name</th>
          <th>Type</th>
          <th>Value</th>
          <th>Documentation</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  `
}

// Generic free-text fallback used when the user has not picked a stored
// Library from the dropdown.
function renderParametersJsonTextarea() {
  return `
    <p class="text-sm text-gray-500">
      Optional: a FHIR Parameters resource bound to the Library's declared
      inputs. Pick a Library above to see typed inputs instead.
    </p>
    <textarea name="parametersJson" rows="6" cols="80"
      placeholder='{"resourceType":"Parameters","parameter":[{"name":"...","valueString":"..."}]}'></textarea>
  `
}

// Build the breadcrumb header for the form page.
function renderBreadcrumbs(scope, library) {
  if (scope === 'instance') {
    return `
      <a href="/">Home</a>
      <span class="text-gray-500">/</span>
      <a href="/Library">Library</a>
      <span class="text-gray-500">/</span>
      <a href="/Library/${escapeHtml(library.id)}">${escapeHtml(library.id)}</a>
      <span class="text-gray-500">/</span>
      <span class="text-gray-700">$sqlquery-run</span>
    `
  }
  return `
    <a href="/">Home</a>
    <span class="text-gray-500">/</span>
    <a href="/Library">Library</a>
    <span class="text-gray-500">/</span>
    <span class="text-gray-700">$sqlquery-run</span>
  `
}

// Render the SQLQuery Run form. Used at system, type, and instance scopes.
async function renderForm(req, res, { scope, library }) {
  const operation = await read(req.config, 'OperationDefinition', '$sqlquery-run')
  const libraries = scope === 'instance' ? [] : await search(req.config, 'Library', 100)

  const formAction =
    scope === 'instance'
      ? `/Library/${library.id}/$sqlquery-run/form`
      : scope === 'type'
        ? '/Library/$sqlquery-run/form'
        : '/$sqlquery-run/form'

  const sourceFields =
    scope === 'instance'
      ? `<p class="text-sm text-gray-500">Library: <a href="/Library/${escapeHtml(library.id)}">${escapeHtml(library.id)}</a></p>`
      : `
          <p class="text-sm text-gray-500">
            Choose a stored Library or paste an inline Library JSON. If both
            are provided, the inline resource takes precedence.
          </p>
          <table class="mt-2">
            <tr>
              <th>queryReference</th>
              <td>
                <select name="queryReference"
                        hx-get="${formAction}/parameters"
                        hx-target="#parameter-fields"
                        hx-swap="innerHTML"
                        hx-trigger="change">
                  <option value="">- choose -</option>
                  ${libraries
                    .map((l) => `<option value="Library/${escapeHtml(l.id)}">${escapeHtml(l.id)}</option>`)
                    .join('')}
                </select>
              </td>
            </tr>
            <tr>
              <th>queryResource</th>
              <td>
                <textarea name="queryResource" rows="10" cols="80"
                  placeholder='Paste a Library resource JSON, e.g. {"resourceType":"Library", ...}'></textarea>
              </td>
            </tr>
          </table>
        `

  // For instance scope the Library is already known, so render its declared
  // parameter inputs directly. For system/type scope, the inputs are swapped
  // in by htmx after the user picks a Library from the dropdown.
  const parameterFields =
    scope === 'instance'
      ? renderInstanceParameterFields(library)
      : `<div id="parameter-fields">${renderParametersJsonTextarea()}</div>`

  res.setHeader('Content-Type', 'text/html')
  res.send(
    layout(`
      <div class="container mx-auto p-4">
        <div class="flex items-center gap-4">${renderBreadcrumbs(scope, library)}</div>
        <h1 class="mt-4">SQLQuery Run</h1>
        <p class="mb-4">${escapeHtml(operation?.description || '')}</p>
        <form
          hx-post="${formAction}"
          hx-target="#sqlquery-result"
          hx-swap="innerHTML">
          <h3 class="font-bold mt-4">Library source</h3>
          ${sourceFields}

          <h3 class="font-bold mt-4">Library parameters</h3>
          ${parameterFields}

          <h3 class="font-bold mt-4">Output</h3>
          <table class="mt-2">
            <tr>
              <th>_format</th>
              <td>
                <select name="_format">
                  <option value="json">json</option>
                  <option value="ndjson">ndjson</option>
                  <option value="csv">csv</option>
                  <option value="fhir">fhir</option>
                </select>
              </td>
            </tr>
            <tr>
              <th>header</th>
              <td>
                <label>
                  <input type="checkbox" name="header" value="true" checked />
                  Include CSV header (only applies to csv output)
                </label>
              </td>
            </tr>
          </table>

          <div class="mt-4">
            <button class="btn" type="submit">Run</button>
          </div>
        </form>
        <div id="sqlquery-result" class="mt-4"></div>

        <details class="mt-8">
          <summary class="text-sky-600 hover:text-sky-700 cursor-pointer">OperationDefinition</summary>
          <div class="mt-2">${operation ? await renderOperationDefinition(req, operation) : ''}</div>
        </details>
      </div>
    `),
  )
}

// Translate per-parameter form fields into a Parameters resource using the
// Library's declared parameter types.
function buildInstanceParametersResource(library, form) {
  const declared = library.parameter || []
  const parts = []
  for (const decl of declared) {
    const fieldName = `param_${decl.name}`
    const raw = form[fieldName]
    if (decl.type === 'boolean') {
      // Unchecked boolean inputs send no field at all; treat as omitted unless
      // the user explicitly ticked the box.
      if (raw === undefined) continue
      parts.push({ name: decl.name, valueBoolean: raw === 'true' || raw === 'on' })
      continue
    }
    if (raw === undefined || raw === null || raw === '') continue
    const valueField = fhirTypeToValueField[decl.type]
    if (!valueField) {
      throw new SqlQueryRunError(
        400,
        'invalid',
        `Unsupported parameter type '${decl.type}' for '${decl.name}'`,
      )
    }
    let value = raw
    if (decl.type === 'integer' || decl.type === 'decimal') {
      const n = Number(raw)
      if (!Number.isFinite(n)) {
        throw new SqlQueryRunError(
          400,
          'invalid',
          `Parameter '${decl.name}' value '${raw}' is not a valid number`,
        )
      }
      value = n
    } else if (decl.type === 'integer64') {
      // FHIR JSON serialises integer64 as a string; bindParameters coerces it
      // back to a numeric SQLite binding.
      const n = Number(raw)
      if (!Number.isFinite(n)) {
        throw new SqlQueryRunError(
          400,
          'invalid',
          `Parameter '${decl.name}' value '${raw}' is not a valid integer`,
        )
      }
      value = String(n)
    }
    parts.push({ name: decl.name, [valueField]: value })
  }
  if (parts.length === 0) return null
  return { resourceType: 'Parameters', parameter: parts }
}

// Send the rendered result region back to the browser. htmx swaps inner HTML
// of #sqlquery-result; non-htmx callers get a fully laid-out page.
function sendFormResult(req, res, result) {
  const html = `
    <div>
      <h2 class="text-xl font-bold">Result</h2>
      <p class="text-xs text-gray-500 mt-1">Content-Type: <code>${escapeHtml(result.contentType)}</code></p>
      <pre class="mt-2">${escapeHtml(result.body)}</pre>
    </div>
  `
  res.setHeader('Content-Type', 'text/html')
  if (req.headers['hx-request']) {
    res.send(html)
  } else {
    res.send(layout(`<div class="container mx-auto p-4">${html}</div>`))
  }
}

function sendFormError(req, res, err) {
  let status = 500
  let code = 'exception'
  let message = err?.message || String(err)
  if (err instanceof SqlQueryRunError) {
    status = err.status
    code = err.code
  } else {
    console.error('$sqlquery-run form unexpected error', err)
  }
  const html = `
    <div class="bg-red-50 border border-red-300 rounded-md p-4">
      <h2 class="text-xl font-bold text-red-700">Error</h2>
      <p class="text-sm text-red-700 mt-1">
        <code>${escapeHtml(code)}</code>: ${escapeHtml(message)}
      </p>
    </div>
  `
  res.setHeader('Content-Type', 'text/html')
  // htmx swaps on 2xx responses by default; send 200 so the error region
  // replaces the previous result without extra configuration.
  if (req.headers['hx-request']) {
    res.status(200).send(html)
  } else {
    res.status(status).send(layout(`<div class="container mx-auto p-4">${html}</div>`))
  }
}

// Shared form-submit handler. Resolves the library, builds a Parameters
// resource, runs the operation, and renders the result.
async function handleFormSubmit(req, res, { scope, id }) {
  try {
    const form = req.body || {}
    const format = form._format || 'json'
    const header = form.header === 'true'

    let library
    let parametersResource

    if (scope === 'instance') {
      library = await read(req.config, 'Library', id)
      if (!library) {
        throw new SqlQueryRunError(404, 'not-found', `Library/${id} not found`)
      }
      parametersResource = buildInstanceParametersResource(library, form)
    } else {
      let queryResource = null
      let queryReference = null
      if (form.queryResource && form.queryResource.trim()) {
        try {
          queryResource = JSON.parse(form.queryResource)
        } catch (parseErr) {
          throw new SqlQueryRunError(400, 'invalid', `queryResource is not valid JSON: ${parseErr.message}`)
        }
      } else if (form.queryReference) {
        queryReference = { reference: form.queryReference }
      } else {
        throw new SqlQueryRunError(400, 'required', 'Provide either a queryReference or a queryResource')
      }
      library = await resolveLibrary({
        queryReference,
        queryResource,
        config: req.config,
      })
      // The htmx fragment swaps the parametersJson textarea out for typed
      // per-parameter inputs once the user picks a Library. Detect that case
      // by looking for any `param_*` field; otherwise fall back to the JSON
      // textarea path.
      const hasParamFields = Object.keys(form).some((k) => k.startsWith('param_'))
      if (hasParamFields) {
        parametersResource = buildInstanceParametersResource(library, form)
      } else if (form.parametersJson && form.parametersJson.trim()) {
        try {
          parametersResource = JSON.parse(form.parametersJson)
        } catch (parseErr) {
          throw new SqlQueryRunError(400, 'invalid', `parametersJson is not valid JSON: ${parseErr.message}`)
        }
      } else {
        parametersResource = null
      }
    }

    const result = await executeSqlQueryRun({
      library,
      parametersResource,
      format,
      header,
      config: req.config,
    })
    sendFormResult(req, res, result)
  } catch (err) {
    sendFormError(req, res, err)
  }
}

export async function getSqlQueryRunFormSystem(req, res) {
  await renderForm(req, res, { scope: 'system', library: null })
}

export async function getSqlQueryRunFormType(req, res) {
  await renderForm(req, res, { scope: 'type', library: null })
}

export async function getSqlQueryRunFormInstance(req, res) {
  const id = req.params.id
  const library = await read(req.config, 'Library', id)
  if (!library) {
    res.status(404)
    res.setHeader('Content-Type', 'text/html')
    res.send(
      layout(`
        <div class="container mx-auto p-4">
          <h1>SQLQuery Run</h1>
          <p>Library/${escapeHtml(id)} not found</p>
        </div>
      `),
    )
    return
  }
  await renderForm(req, res, { scope: 'instance', library })
}

// htmx fragment: render parameter inputs for a given queryReference, used by
// the system/type forms when the dropdown selection changes.
export async function getSqlQueryRunFormParameters(req, res) {
  res.setHeader('Content-Type', 'text/html')
  const ref = req.query.queryReference
  if (!ref) {
    res.send(renderParametersJsonTextarea())
    return
  }
  const segment = String(ref).split('/').pop()
  const library = await read(req.config, 'Library', segment)
  if (!library) {
    res.send(`<p class="text-sm text-red-600">Library not found: ${escapeHtml(String(ref))}</p>`)
    return
  }
  res.send(renderInstanceParameterFields(library))
}

export async function postSqlQueryRunFormSystem(req, res) {
  await handleFormSubmit(req, res, { scope: 'system' })
}

export async function postSqlQueryRunFormType(req, res) {
  await handleFormSubmit(req, res, { scope: 'type' })
}

export async function postSqlQueryRunFormInstance(req, res) {
  await handleFormSubmit(req, res, { scope: 'instance', id: req.params.id })
}

// Render a Library list page mirroring the ViewDefinition list, with a column
// linking each row to the per-Library $sqlquery-run form.
function renderLibrariesHtml(res, libraries) {
  const rows = libraries
    .map((lib) => {
      const name = lib.name || lib.id
      const title = lib.title || ''
      const url = lib.url || ''
      return `
        <tr>
          <td class="border border-gray-200 p-2">
            <a class="text-blue-500 hover:text-blue-700"
               href="/Library/${escapeHtml(lib.id)}">
              ${escapeHtml(name)}
            </a>
          </td>
          <td class="border border-gray-200 p-2">${escapeHtml(title)}</td>
          <td class="border border-gray-200 p-2 text-xs">${escapeHtml(url)}</td>
          <td class="border border-gray-200 p-2">
            <a class="text-blue-500 hover:text-blue-700"
               href="/Library/${escapeHtml(lib.id)}/$sqlquery-run/form">
              $sqlquery-run
            </a>
          </td>
        </tr>
      `
    })
    .join('')

  res.setHeader('Content-Type', 'text/html')
  res.send(
    layout(`
      <div class="container mx-auto p-4">
        <div class="flex items-center space-x-4">
          <a href="/" class="text-blue-500 hover:text-blue-700">Home</a>
          <span class="text-gray-500">/</span>
        </div>
        <div class="mt-4 flex items-center space-x-4 border-b border-gray-200 pb-2">
          <h1 class="flex-1 text-2xl font-bold">SQL queries</h1>
          <a href="/Library/$sqlquery-run/form" class="btn">$sqlquery-run</a>
        </div>
        <table class="mt-4 table-auto border-collapse border border-gray-200">
          <thead>
            <tr>
              <th class="bg-gray-100 border border-gray-200 p-2">Name</th>
              <th class="bg-gray-100 border border-gray-200 p-2">Title</th>
              <th class="bg-gray-100 border border-gray-200 p-2">URL</th>
              <th class="bg-gray-100 border border-gray-200 p-2">Run</th>
            </tr>
          </thead>
          <tbody>${rows}</tbody>
        </table>
      </div>
    `),
  )
}

export async function getLibraryListEndpoint(req, res) {
  const libraries = await search(req.config, 'Library', 1000)
  if (isHtml(req)) {
    renderLibrariesHtml(res, libraries)
  } else {
    res.setHeader('Content-Type', 'application/fhir+json')
    res.json(wrapBundle(libraries))
  }
}

export function mountRoutes(app) {
  // API endpoints. POST a Parameters resource and receive query results.
  app.post('/\\$sqlquery-run', postSqlQueryRunSystem)
  app.post('/Library/\\$sqlquery-run', postSqlQueryRunType)
  app.post('/Library/:id/\\$sqlquery-run', postSqlQueryRunInstance)

  // Interactive HTML form endpoints.
  app.get('/\\$sqlquery-run/form', getSqlQueryRunFormSystem)
  app.get('/Library/\\$sqlquery-run/form', getSqlQueryRunFormType)
  app.get('/Library/:id/\\$sqlquery-run/form', getSqlQueryRunFormInstance)
  app.post('/\\$sqlquery-run/form', postSqlQueryRunFormSystem)
  app.post('/Library/\\$sqlquery-run/form', postSqlQueryRunFormType)
  app.post('/Library/:id/\\$sqlquery-run/form', postSqlQueryRunFormInstance)

  // htmx fragment used by the system and type forms to render typed parameter
  // inputs once a Library is selected.
  app.get('/\\$sqlquery-run/form/parameters', getSqlQueryRunFormParameters)
  app.get('/Library/\\$sqlquery-run/form/parameters', getSqlQueryRunFormParameters)

  // Custom Library list page (overrides the generic FHIR resource list for
  // /Library). Mounted before the FHIR catch-all in server.js.
  app.get('/Library', getLibraryListEndpoint)
}
