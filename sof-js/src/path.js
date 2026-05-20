import { default as fhirpath } from 'fhirpath'
import { default as fhirpath_r4_model } from 'fhirpath/fhir-context/r4/index.js'
import fhirpath_types from 'fhirpath/src/types.js'

const { FP_Date, FP_DateTime, FP_Time } = fhirpath_types

const identity = (ctx, v) => [v]

function getResourceKey(nodes) {
  return nodes.flatMap((node) => {
    return [node.id]
  })
}

function getReferenceKey(nodes, opts) {
  let resource = opts?.name
  return nodes.flatMap((node) => {
    const parts = node.reference.replaceAll('//', '').split('/_history')[0].split('/')
    const type = parts[parts.length - 2]
    const key = parts[parts.length - 1]
    if (!resource) {
      return [key]
    } else if (resource && resource == type) {
      return [key]
    } else {
      return []
    }
  })
}

function ofType(ctx, nodes, a1, a2, a3) {
  console.log('of type nodes', nodes, a1, a2, a3)
  return 'ups'
}

function rewrite_path(path) {
  if (path.startsWith('$this')) {
    path = 'identity()' + path.slice('$this'.length)
  }
  const ofTypeRegex = /\.ofType\(([^)]+)\)/g
  let match
  // HACK: fhirpath.js only knows that `Observation.value.ofType(Quantity)`
  // refers to `Observation.valueQuantity` if load FHIR models... which
  // we otherwise don't need. So here, just wrestle into explicit properties.
  while ((match = ofTypeRegex.exec(path)) !== null) {
    const replacement = match[1].charAt(0).toUpperCase() + match[1].slice(1)
    path = path.replace(match[0], `${replacement}`)
  }
  return path
}

let fhirpath_options = {
  userInvocationTable: {
    getResourceKey: { fn: getResourceKey, arity: { 0: [] } },
    getReferenceKey: {
      fn: getReferenceKey,
      arity: { 0: [], 1: ['TypeSpecifier'] },
    },
    identity: { fn: (nodes) => nodes, arity: { 0: [] } },
  },
}

function wrap_constant_value(key, val) {
  // Wrap date/time-typed constants in FHIRPath type instances so that they
  // compare correctly against resource fields once the FHIR model is loaded.
  switch (key) {
    case 'valueDate':
      return new FP_Date(null, val)
    case 'valueDateTime':
    case 'valueInstant':
      return new FP_DateTime(null, val)
    case 'valueTime':
      return new FP_Time(null, val)
    default:
      return val
  }
}

function process_constants(constants) {
  return constants.reduce((acc, x) => {
    let name, val
    for (const key in x) {
      if (key === 'name') {
        name = x[key]
      }
      if (key.startsWith('value')) {
        val = wrap_constant_value(key, x[key])
      }
    }
    acc[name] = val
    return acc
  }, {})
}

/**
 * Evaluates a FHIRPath expression against data with support for constants and
 * environment variables.
 *
 * @param {object} data - The FHIR data to evaluate against.
 * @param {string} path - The FHIRPath expression to evaluate.
 * @param {Array} constants - Array of constant definitions from the ViewDefinition.
 * @param {object} envVars - Additional environment variables (e.g., { rowIndex: 0 }).
 * @returns {Array} The result of the FHIRPath evaluation.
 */
export function fhirpath_evaluate(data, path, constants = [], envVars = {}) {
  const context = process_constants(constants)
  // Merge environment variables into context.
  Object.assign(context, envVars)
  return fhirpath.evaluate(data, rewrite_path(path), context, fhirpath_r4_model, fhirpath_options)
}

export function fhirpath_validate(path) {
  try {
    fhirpath.compile(path, fhirpath_r4_model, fhirpath_options)
    return true
  } catch (e) {
    return false
  }
}
