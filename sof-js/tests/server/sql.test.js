import { startServer } from '../../src/server.js'

var server
const port = 3004
const base = `http://localhost:${port}`

beforeAll(async () => {
  server = await startServer({ port })
  console.log('Server started')
  await waitForData()
})

// Poll until the patient_demographics view returns at least one row. Data is
// fetched from a remote NDJSON source the first time the server starts, so
// downstream tests must wait for that load to complete.
async function waitForData(maxAttempts = 60) {
  for (let i = 0; i < maxAttempts; i++) {
    try {
      const res = await fetch(`${base}/ViewDefinition/patient_demographics/$run?format=json`)
      if (res.status === 200) {
        const rows = await res.json()
        if (Array.isArray(rows) && rows.length > 0) return
      }
    } catch {
      // Server not yet listening — keep polling.
    }
    await new Promise((resolve) => setTimeout(resolve, 1000))
  }
  throw new Error('FHIR data did not load within the allotted time')
}

afterAll(async () => {
  console.log('Server stopped')
  server?.close()
})

async function postSqlQueryRun(path, body) {
  return await fetch(`${base}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/fhir+json' },
    body: JSON.stringify(body),
  })
}

function paramsBody(parts) {
  return { resourceType: 'Parameters', parameter: parts }
}

describe('$sqlquery-run operation', () => {
  test('system route returns JSON for a stored Library', async () => {
    const res = await postSqlQueryRun(
      '/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'json' },
        { name: 'queryReference', valueReference: { reference: 'Library/patient-count' } },
      ]),
    )

    expect(res.status).toBe(200)
    expect(res.headers.get('Content-Type')).toContain('application/fhir+json')

    const rows = await res.json()
    expect(Array.isArray(rows)).toBe(true)
    expect(rows.length).toBe(1)
    expect(rows[0].total).toBeGreaterThan(0)
  })

  test('type route with queryReference returns NDJSON', async () => {
    const res = await postSqlQueryRun(
      '/Library/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'ndjson' },
        { name: 'queryReference', valueReference: { reference: 'Library/patient-count' } },
      ]),
    )

    expect(res.status).toBe(200)
    expect(res.headers.get('Content-Type')).toContain('application/ndjson')

    const text = await res.text()
    const lines = text.trim().split('\n')
    expect(lines.length).toBe(1)
    const row = JSON.parse(lines[0])
    expect(row).toHaveProperty('total')
  })

  test('type route with inline queryResource returns CSV with header by default', async () => {
    const inline = inlinePatientCountLibrary()
    const res = await postSqlQueryRun(
      '/Library/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'csv' },
        { name: 'queryResource', resource: inline },
      ]),
    )

    expect(res.status).toBe(200)
    expect(res.headers.get('Content-Type')).toContain('text/csv')

    const text = await res.text()
    const lines = text.split('\n')
    expect(lines[0]).toBe('total')
    expect(lines.length).toBe(2)
  })

  test('type route with inline queryResource returns CSV without header when header=false', async () => {
    const inline = inlinePatientCountLibrary()
    const res = await postSqlQueryRun(
      '/Library/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'csv' },
        { name: 'header', valueBoolean: false },
        { name: 'queryResource', resource: inline },
      ]),
    )

    expect(res.status).toBe(200)
    const text = await res.text()
    const lines = text.split('\n')
    // First line should be data, not the header.
    expect(lines[0]).not.toBe('total')
    expect(Number.isFinite(Number(lines[0]))).toBe(true)
  })

  test('instance route returns Parameters resource under _format=fhir', async () => {
    const res = await postSqlQueryRun(
      '/Library/patient-count/$sqlquery-run',
      paramsBody([{ name: '_format', valueCode: 'fhir' }]),
    )

    expect(res.status).toBe(200)
    expect(res.headers.get('Content-Type')).toContain('application/fhir+json')

    const body = await res.json()
    expect(body.resourceType).toBe('Parameters')
    expect(Array.isArray(body.parameter)).toBe(true)
    expect(body.parameter.length).toBe(1)
    const row = body.parameter[0]
    expect(row.name).toBe('row')
    const totalPart = row.part.find((p) => p.name === 'total')
    expect(totalPart).toBeDefined()
    // COUNT(*) is an integer column.
    expect(typeof totalPart.valueInteger).toBe('number')
  })

  test('parameter binding round-trips a string value', async () => {
    // First, fetch a real patient id by running the patient_demographics view.
    const seedRes = await fetch(`${base}/ViewDefinition/patient_demographics/$run?format=json`)
    expect(seedRes.status).toBe(200)
    const seedRows = await seedRes.json()
    expect(seedRows.length).toBeGreaterThan(0)
    const expectedId = seedRows[0].id
    const expectedGender = seedRows[0].gender

    const res = await postSqlQueryRun(
      '/Library/patient-by-id/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'json' },
        {
          name: 'parameters',
          resource: paramsBody([{ name: 'patient_id', valueString: expectedId }]),
        },
      ]),
    )

    expect(res.status).toBe(200)
    const rows = await res.json()
    expect(rows.length).toBe(1)
    expect(rows[0].id).toBe(expectedId)
    expect(rows[0].gender).toBe(expectedGender)
  })

  test('empty result under _format=fhir returns Parameters with no parameter array', async () => {
    const res = await postSqlQueryRun(
      '/Library/patient-by-id/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'fhir' },
        {
          name: 'parameters',
          resource: paramsBody([{ name: 'patient_id', valueString: 'no-such-patient' }]),
        },
      ]),
    )

    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.resourceType).toBe('Parameters')
    expect(body.parameter).toBeUndefined()
  })

  test('missing _format returns 400', async () => {
    const res = await postSqlQueryRun('/Library/patient-count/$sqlquery-run', paramsBody([]))
    expect(res.status).toBe(400)
    const body = await res.json()
    expect(body.resourceType).toBe('OperationOutcome')
    expect(body.issue[0].code).toBe('required')
  })

  test('unknown nested parameter name returns 400', async () => {
    const res = await postSqlQueryRun(
      '/Library/patient-by-id/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'json' },
        {
          name: 'parameters',
          resource: paramsBody([{ name: 'unknown_param', valueString: 'x' }]),
        },
      ]),
    )

    expect(res.status).toBe(400)
    const body = await res.json()
    expect(body.resourceType).toBe('OperationOutcome')
    expect(body.issue[0].code).toBe('invalid')
  })

  test('parameter type mismatch with declared Library.parameter.type returns 400', async () => {
    // patient-by-id declares patient_id as a string; sending valueInteger
    // should be rejected with a 400 invalid OperationOutcome.
    const res = await postSqlQueryRun(
      '/Library/patient-by-id/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'json' },
        {
          name: 'parameters',
          resource: paramsBody([{ name: 'patient_id', valueInteger: 42 }]),
        },
      ]),
    )

    expect(res.status).toBe(400)
    const body = await res.json()
    expect(body.resourceType).toBe('OperationOutcome')
    expect(body.issue[0].code).toBe('invalid')
    expect(body.issue[0].diagnostics).toContain('valueString')
  })

  test('unknown Library id on instance route returns 404', async () => {
    const res = await postSqlQueryRun(
      '/Library/does-not-exist/$sqlquery-run',
      paramsBody([{ name: '_format', valueCode: 'json' }]),
    )
    expect(res.status).toBe(404)
    const body = await res.json()
    expect(body.resourceType).toBe('OperationOutcome')
    expect(body.issue[0].code).toBe('not-found')
  })

  test('boolean column maps to valueBoolean under _format=fhir', async () => {
    // Use an inline Library that depends on the patient_multiple_birth view,
    // whose multiple_birth column is declared as boolean. The fhir output
    // should encode that column with valueBoolean per the SQL-to-FHIR type
    // mapping.
    const inline = inlinePatientMultipleBirthLibrary()
    const res = await postSqlQueryRun(
      '/Library/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'fhir' },
        { name: 'queryResource', resource: inline },
      ]),
    )

    expect(res.status).toBe(200)
    const body = await res.json()
    expect(body.resourceType).toBe('Parameters')
    expect(Array.isArray(body.parameter)).toBe(true)
    expect(body.parameter.length).toBeGreaterThan(0)

    // Find rows whose multiple_birth part is present and assert it carries
    // valueBoolean rather than a numeric or string encoding.
    const presentParts = body.parameter
      .map((row) => row.part.find((p) => p.name === 'multiple_birth'))
      .filter((part) => part !== undefined)
    expect(presentParts.length).toBeGreaterThan(0)
    for (const part of presentParts) {
      expect(typeof part.valueBoolean).toBe('boolean')
      expect(part.valueInteger).toBeUndefined()
    }
  })

  test('referenced ViewDefinition that cannot be resolved returns 404', async () => {
    const inline = inlineMissingViewLibrary()
    const res = await postSqlQueryRun(
      '/Library/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'json' },
        { name: 'queryResource', resource: inline },
      ]),
    )

    expect(res.status).toBe(404)
    const body = await res.json()
    expect(body.resourceType).toBe('OperationOutcome')
    expect(body.issue[0].code).toBe('not-found')
    expect(body.issue[0].diagnostics).toContain('ViewDefinition')
  })

  test('SQL referencing a non-existent column returns 422', async () => {
    const inline = inlineBadColumnLibrary()
    const res = await postSqlQueryRun(
      '/Library/$sqlquery-run',
      paramsBody([
        { name: '_format', valueCode: 'json' },
        { name: 'queryResource', resource: inline },
      ]),
    )

    expect(res.status).toBe(422)
    const body = await res.json()
    expect(body.resourceType).toBe('OperationOutcome')
    expect(body.issue[0].code).toBe('processing')
  })
})

// Helper builders for inline Library resources used by tests.

function inlinePatientCountLibrary() {
  return {
    resourceType: 'Library',
    status: 'active',
    type: { coding: [{ code: 'sql-query' }] },
    relatedArtifact: [
      {
        type: 'depends-on',
        resource: 'http://myig.org/ViewDefinition/patient_demographics',
        label: 'patient_demographics',
      },
    ],
    content: [
      {
        contentType: 'application/sql',
        extension: [
          {
            url: 'https://sql-on-fhir.org/ig/StructureDefinition/sql-text',
            valueString: 'SELECT COUNT(*) AS total FROM patient_demographics',
          },
        ],
      },
    ],
  }
}

function inlinePatientMultipleBirthLibrary() {
  return {
    resourceType: 'Library',
    status: 'active',
    type: { coding: [{ code: 'sql-query' }] },
    relatedArtifact: [
      {
        type: 'depends-on',
        resource: 'http://myig.org/ViewDefinition/patient_multiple_birth',
        label: 'patient_multiple_birth',
      },
    ],
    content: [
      {
        contentType: 'application/sql',
        extension: [
          {
            url: 'https://sql-on-fhir.org/ig/StructureDefinition/sql-text',
            valueString: 'SELECT id, multiple_birth FROM patient_multiple_birth',
          },
        ],
      },
    ],
  }
}

function inlineMissingViewLibrary() {
  return {
    resourceType: 'Library',
    status: 'active',
    type: { coding: [{ code: 'sql-query' }] },
    relatedArtifact: [
      {
        type: 'depends-on',
        resource: 'http://myig.org/ViewDefinition/no_such_view',
        label: 'no_such_view',
      },
    ],
    content: [
      {
        contentType: 'application/sql',
        extension: [
          {
            url: 'https://sql-on-fhir.org/ig/StructureDefinition/sql-text',
            valueString: 'SELECT 1 AS one FROM no_such_view',
          },
        ],
      },
    ],
  }
}

function inlineBadColumnLibrary() {
  return {
    resourceType: 'Library',
    status: 'active',
    type: { coding: [{ code: 'sql-query' }] },
    relatedArtifact: [
      {
        type: 'depends-on',
        resource: 'http://myig.org/ViewDefinition/patient_demographics',
        label: 'patient_demographics',
      },
    ],
    content: [
      {
        contentType: 'application/sql',
        extension: [
          {
            url: 'https://sql-on-fhir.org/ig/StructureDefinition/sql-text',
            valueString: 'SELECT no_such_column FROM patient_demographics',
          },
        ],
      },
    ],
  }
}
