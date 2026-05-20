import { read } from './db.js'
import { isHtml, renderNotFound, runOperation, renderOperationDefinition } from './utils.js'
import { layout } from './ui.js'

function renderError(req, res, error) {
  if (isHtml(req)) {
    res.setHeader('Content-Type', 'text/html')
    res.send(
      layout(`
            <div class="container mx-auto p-4">
                <h1>Evaluate ViewDefinition</h1>
                <p>Error: ${error}</p>  
            </div>
        `),
    )
    res.end()
  } else if (req.headers['hx-target']) {
    res.setHeader('Content-Type', 'text/html')
    res.send(
      layout(`
            <div class="container mx-auto p-4 bg-red-100 border border-red-500 rounded-md">
                <h1>Error</h1>
                <p class="text-red-500">${error}</p>  
            </div>
        `),
    )
    res.end()
  } else {
    res.status(500)
    res.json({
      resourceType: 'OperationOutcome',
      issue: [{ code: 'error', message: error.toString() }],
    })
  }
}

export async function getRunFormEndpoint(req, res) {
  const id = req.params.id
  const resource = await read(req.config, 'ViewDefinition', id)
  const operation = await read(req.config, 'OperationDefinition', '$viewdefinition-run')
  if (resource == null) {
    renderNotFound(req, res, `Resource id = "${id}" not found`)
    return
  }
  res.setHeader('Content-Type', 'text/html')
  res.send(
    layout(`
      <div class="container mx-auto p-4">
        <div class="flex items-center gap-4">
          <a  href="/">Home</a>
          <span class="text-gray-500">/</span>
          <a href="/ViewDefinition/">ViewDefinition</a>
          <span class="text-gray-500">/</span>
          <a href="/ViewDefinition/${resource.id}">${resource.id}</a>
          <span class="text-gray-500">/</span>
          <a class="text-gray-700" href="#">$run</a>
        </div>
        <div class="mt-4">
            <form class="mt-4" 
                hx-get="/ViewDefinition/${resource.id}/$run/process"
                hx-target="#run-results"
                hx-swap="innerHTML"
                method="get">  
                ${await renderOperationDefinition(req, operation)}
                <div class="mt-4">
                    <button class="btn" type="submit"> $Run </button>   
                </div>
            </form>
            <div id="run-results" class="mt-4"></div>
        </div>
      </div>
    `),
  )
}

function renderResult(req, res, result, format, includeHeader = true) {
  if (isHtml(req)) {
    res.setHeader('Content-Type', 'text/html')
    res.send(
      layout(`
            <div class="container mx-auto p-4">
                <h1>Evaluate ViewDefinition</h1>
                <pre class="mt-4">${JSON.stringify(req.query, null, 2)}</pre>
                <pre class="mt-4">${JSON.stringify(result, null, 2)}</pre>
            </div>
        `),
    )
  } else if (format === 'json') {
    res.setHeader('Content-Type', 'application/fhir+json')
    res.send(JSON.stringify(result, null, 2))
    res.end()
  } else if (format === 'ndjson') {
    res.setHeader('Content-Type', 'application/ndjson')
    result.forEach((item) => {
      res.write(JSON.stringify(item) + '\n')
    })
    res.end()
  } else if (format === 'csv') {
    res.setHeader('Content-Type', 'text/csv')
    let csvContent = ''
    if (includeHeader && result.length > 0) {
      csvContent = Object.keys(result[0]).join(',') + '\n'
    }
    csvContent += result.map((item) => Object.values(item).join(',')).join('\n')
    res.send(csvContent)
  }
}

export async function getRunEndpoint(req, res) {
  const id = req.params.id
  const resource = await read(req.config, 'ViewDefinition', id)
  if (resource == null) {
    renderNotFound(req, res, `Resource id = "${id}" not found`)
    return
  }
  try {
    const result = await runOperation(req, resource, req.query)
    const format = req.query.format || 'json'
    const includeHeader = req.query.header !== 'false'
    renderResult(req, res, result, format, includeHeader)
  } catch (error) {
    console.error('$run-error', error)
    renderError(req, res, error)
  }
}

function renderRunResults(query, result) {
  if (query.format === 'json') {
    return `<pre>${JSON.stringify(result, null, 2)}</pre>`
  } else if (query.format === 'ndjson') {
    return `<pre>${result.map((item) => JSON.stringify(item)).join('\n')}</pre>`
  } else if (query.format === 'csv') {
    let csvContent = ''
    if (query.header !== 'false' && result.length > 0) {
      csvContent = Object.keys(result[0]).join(',') + '\n'
    }
    csvContent += result.map((item) => Object.values(item).join(',')).join('\n')
    return `<pre>${csvContent}</pre>`
  } else {
    return `<pre>${JSON.stringify(result, null, 2)}</pre>`
  }
}

export async function getRunProcessEndpoint(req, res) {
  const id = req.params.id
  const resource = await read(req.config, 'ViewDefinition', id)
  const result = await runOperation(req, resource, req.query)
  res.setHeader('Content-Type', 'text/html')
  res.send(
    layout(`
        <div>
            <h1>Evaluate ViewDefinition</h1>
            <pre>${JSON.stringify(req.query, null, 2)}</pre>
            <div class="mt-4">
                ${renderRunResults(req.query, result)}
            </div>
        </div>
    `),
  )
}

export function mountRoutes(app) {
  app.get('/ViewDefinition/:id/\\$run/form', getRunFormEndpoint)
  app.get('/ViewDefinition/:id/\\$run/process', getRunProcessEndpoint)
  app.get('/ViewDefinition/:id/\\$run', getRunEndpoint)
}
