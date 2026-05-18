import { fhirpath_evaluate } from './path.js'
import { errors as verrors, validate } from './validate.js'

export let errors = verrors

function assert(condition, message) {
  if (!condition) {
    throw message || 'Assertion failed'
  }
}

export function merge(a, b) {
  return Object.assign({}, a, b)
}

export function row_product(parts) {
  if (parts.length == 1) {
    return parts[0]
  }

  let rows = [{}]
  let new_rows = null

  parts.forEach((partial_rows) => {
    new_rows = []
    partial_rows.forEach((partial_row) => {
      rows.forEach((row) => {
        new_rows.push(merge(partial_row, row))
      })
    })
    rows = new_rows
  })
  return rows
}

function forEach(select_expr, node, def, envVars = {}) {
  assert(select_expr.forEach, 'forEach required')
  let nodes = fhirpath_evaluate(node, select_expr.forEach, def.constant, envVars)
  return nodes.flatMap((node, index) => {
    // Each element gets its own rowIndex within this iteration level.
    const childEnvVars = { ...envVars, rowIndex: index }
    return select({ select: select_expr.select }, node, def, childEnvVars)
  })
}

function forEachOrNull(select_expr, node, def, envVars = {}) {
  assert(select_expr.forEachOrNull, 'forEachOrNull required')
  let nodes = fhirpath_evaluate(node, select_expr.forEachOrNull, def.constant, envVars)
  if (nodes.length == 0) {
    // For empty collections, produce a single null row with rowIndex 0.
    nodes = [{}]
  }
  return nodes.flatMap((node, index) => {
    // Each element gets its own rowIndex within this iteration level.
    const childEnvVars = { ...envVars, rowIndex: index }
    return select({ select: select_expr.select }, node, def, childEnvVars)
  })
}

function recursiveTraverse(paths, node, def, envVars = {}) {
  const result = []

  const traverse = (currentNode, isRoot = false) => {
    // Don't add the root node to results, only its children.
    if (!isRoot) {
      result.push(currentNode)
    }

    // Recursively traverse using each path expression.
    paths.forEach((path) => {
      const childNodes = fhirpath_evaluate(currentNode, path, def.constant, envVars)
      childNodes.forEach((childNode) => {
        if (childNode && typeof childNode === 'object') {
          traverse(childNode, false)
        }
      })
    })
  }

  traverse(node, true)

  return result
}

function repeat(select_expr, node, def, envVars = {}) {
  assert(select_expr.repeat, 'repeat required')
  assert(Array.isArray(select_expr.repeat), 'repeat must be an array')

  // Use recursiveTraverse to get all nodes at all depths.
  const nodes = recursiveTraverse(select_expr.repeat, node, def, envVars)

  return nodes.flatMap((node, index) => {
    // Each element in the flattened repeat gets its own rowIndex.
    const childEnvVars = { ...envVars, rowIndex: index }
    return select({ select: select_expr.select }, node, def, childEnvVars)
  })
}

function column(select_expr, node, def, envVars = {}) {
  assert(select_expr.column, 'column required')
  let record = {}
  select_expr.column.forEach((c) => {
    let vs = fhirpath_evaluate(node, c.path, def.constant, envVars)
    if (c.collection) {
      record[c.name || c.path] = vs
    } else if (vs.length <= 1) {
      let v = vs[0]
      record[c.name || c.path] = v === undefined ? null : v
    } else {
      throw new Error('Collection value for ' + c.path + ' => ' + JSON.stringify(vs))
    }
  })
  return [record]
}

function arrays_eq(a, b) {
  if (a.length !== b.length) {
    return false
  }

  for (let i = 0; i < a.length; ++i) {
    if (a[i] !== b[i]) {
      return false
    }
  }

  return true
}

function arrays_unique(arrays) {
  return arrays.reduce((acc, value) => {
    if (acc.length === 0) {
      return [value]
    }

    for (const x of acc) {
      if (arrays_eq(x, value)) {
        return acc
      }
    }

    return acc.concat([value])
  }, [])
}

function unionAll(select_expr, node, def, envVars = {}) {
  assert(select_expr.unionAll, 'unionAll')
  const result = select_expr.unionAll.flatMap((d) => do_eval(d, node, def, envVars))

  // TODO ideally, this should be done during the validation.
  const unique = arrays_unique(result.map((x) => Object.keys(x)))
  // TODO how can unique be === []?
  assert(unique.length <= 1, new Error(`Union columns mismatch: ${JSON.stringify(unique)}`))

  return result
}

function select(select_expr, node, def, envVars = {}) {
  assert(select_expr.select, 'select')
  if (select_expr.where) {
    let include = select_expr.where.every((w) => {
      const val = fhirpath_evaluate(node, w.path, def.constant, envVars)[0]
      assert(val === undefined || typeof val === 'boolean', "'where' expression path should return 'boolean'")
      return val
    })
    if (!include) {
      return []
    }
  }
  if (select_expr.resource) {
    if (select_expr.resource !== node.resourceType) {
      return []
    }
  }
  return row_product(
    select_expr.select.map((s) => {
      return do_eval(s, node, def, envVars)
    }),
  )
}

// * foreach    / column / [select(..)]   -> foreach select[column, ..]
// * foreach    / union / [select(..)]     -> foreach select[union, ..]
// * foreach    / select(..)               -> foreach select[..]
// * repeat     / column / [select(..)]   -> repeat select[column, ..]
// * repeat     / union / [select(..)]    -> repeat select[union, ..]
// * repeat     / select(..)              -> repeat select[..]
// * select[..] / union                    -> select [union, ..]
// * select[..] / column                  -> select [column, ..]
// * union      / column                  -> select [column, union]
function normalize(def) {
  if (def.forEach) {
    def.select ||= []
    def.type = 'forEach'

    if (def.unionAll) {
      def.select.unshift({ unionAll: def.unionAll })
      delete def.unionAll
    }

    if (def.column) {
      def.select.unshift({ column: def.column })
      delete def.column
    }

    def.select = def.select.map((s) => normalize(s))
    return def
  } else if (def.forEachOrNull) {
    def.select ||= []
    def.type = 'forEachOrNull'

    if (def.unionAll) {
      def.select.unshift({ unionAll: def.unionAll })
      delete def.unionAll
    }

    if (def.column) {
      def.select.unshift({ column: def.column })
      delete def.column
    }

    def.select = def.select.map((s) => normalize(s))
    return def
  } else if (def.repeat) {
    def.select ||= []
    def.type = 'repeat'

    if (def.unionAll) {
      def.select.unshift({ unionAll: def.unionAll })
      delete def.unionAll
    }

    if (def.column) {
      def.select.unshift({ column: def.column })
      delete def.column
    }

    def.select = def.select.map((s) => normalize(s))
    return def
  } else if (def.column && def.select && def.unionAll) {
    def.type = 'select'
    def.select.unshift({ column: def.column })
    def.select.unshift({ unionAll: def.unionAll })
    delete def.column
    delete def.unionAll

    def.select = def.select.map((s) => normalize(s))
    return def
  } else if (def.unionAll && def.select) {
    def.type = 'select'
    def.select.unshift({ unionAll: def.unionAll })
    delete def.unionAll

    def.select = def.select.map((s) => normalize(s))
    return def
  } else if (def.select && def.column) {
    def.select.unshift({ column: def.column })
    delete def.column

    def.type = 'select'
    def.select = def.select.map((s) => normalize(s))
    return def
  } else if (def.unionAll && def.column) {
    def.select ||= []
    def.select.unshift({ unionAll: def.unionAll })
    def.select.unshift({ column: def.column })
    delete def.unionAll
    delete def.column

    def.type = 'select'
    def.select = def.select.map((s) => normalize(s))
    return def
  } else if (def.select) {
    def.type = 'select'
    def.select = def.select.map((s) => normalize(s))
    return def
  } else {
    if (def.unionAll) {
      def.type = 'unionAll'
      def.unionAll = def.unionAll.map((s) => normalize(s))
    } else if (def.column) {
      def.type = 'column'
    } else if (def.forEach) {
      def.type = 'forEach'
    } else if (def.forEachOrNull) {
      def.type = 'forEachOrNull'
    } else if (def.repeat) {
      def.type = 'repeat'
    } else if (def.select) {
      def.type = 'select'
    }
    return def
  }
}

let fns = {
  forEach: forEach,
  forEachOrNull: forEachOrNull,
  repeat: repeat,
  unionAll: unionAll,
  select: select,
  column: column,
  unknown: () => {
    return []
  },
}

function do_eval(select_expr, node, def, envVars = {}) {
  let f = fns[select_expr.type] || fns['unknown']
  return f(select_expr, node, def, envVars)
}

function collect_columns(acc, def) {
  switch (def.type) {
    case 'select':
    case 'forEach':
    case 'forEachNull':
    case 'repeat':
      return def.select.reduce((acc, s) => {
        return collect_columns(acc, s)
      }, acc)
    case 'unionAll':
      let unions = def.unionAll.map((s) => {
        return collect_columns([], s)
      })

      if (unions.length > 1) {
        let first = unions[0]
        for (let i = 1; i < unions.length; ++i) {
          if (!arrays_eq(first, unions[i])) {
            throw new Error(`Union columns mismatch: ${JSON.stringify(unions)}`)
          }
        }
      }

      return acc.concat(unions[0])
    case 'column':
      return def.column.reduce((acc, c) => {
        acc.push(c.name || c.path)
        return acc
      }, acc)
    default:
      return acc
  }
}

// collect columns in a right order
export function get_columns(def) {
  return collect_columns([], normalize(structuredClone(def)))
}

export function evaluate(def, node, for_test = true) {
  if (!Array.isArray(node)) {
    return evaluate(def, [node])
  }

  const validation = validate(def, for_test)
  if ((validation.errors || []).length > 0) {
    throw new Error('Incorrect view definition:\n'.concat(JSON.stringify(validation.errors, null, 2)))
  }

  const normal_def = normalize(structuredClone(def))

  // console.log("=======  NORM =========")
  // console.dir(normal_def, {depth: null})

  // Initialise rowIndex to 0 at the top level (resource level).
  const initialEnvVars = { rowIndex: 0 }
  return node.flatMap((n) => do_eval(normal_def, n, def, initialEnvVars))
}
