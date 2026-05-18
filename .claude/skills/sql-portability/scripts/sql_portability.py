#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["sqlglot"]
# ///
"""Analyse SQL portability across database dialects using sqlglot.

Author: John Grimes
"""

import json
import sys

import sqlglot
from sqlglot.dialects import DIALECTS as DIALECT_NAMES
from sqlglot.errors import ErrorLevel

# Use all dialects supported by sqlglot, sorted for consistent output.
DIALECTS = sorted(name.lower() for name in DIALECT_NAMES)


def transpile_to_dialect(sql: str, source_dialect: str, target_dialect: str) -> dict:
    """Transpile SQL from a source dialect to a target dialect.

    Returns a dict with keys: dialect, success, sql, and optionally error.
    """
    try:
        results = sqlglot.transpile(
            sql,
            read=source_dialect,
            write=target_dialect,
            error_level=ErrorLevel.RAISE,
        )
        return {
            "dialect": target_dialect,
            "success": True,
            "sql": results[0] if results else "",
        }
    except Exception as e:
        return {
            "dialect": target_dialect,
            "success": False,
            "sql": "",
            "error": str(e),
        }


def analyse_portability(sql: str, source_dialect: str = "postgres") -> dict:
    """Analyse SQL portability by transpiling to all target dialects.

    Returns a structured report with the original SQL, source dialect,
    and results for each target dialect.
    """
    # First, validate that the SQL parses in the source dialect.
    try:
        sqlglot.transpile(
            sql, read=source_dialect, error_level=ErrorLevel.RAISE
        )
    except Exception as e:
        return {
            "original_sql": sql,
            "source_dialect": source_dialect,
            "parse_error": str(e),
            "results": [],
        }

    results = []
    for dialect in DIALECTS:
        result = transpile_to_dialect(sql, source_dialect, dialect)
        # Flag whether the output differs from the original.
        if result["success"]:
            result["modified"] = result["sql"].strip() != sql.strip()
        results.append(result)

    return {
        "original_sql": sql,
        "source_dialect": source_dialect,
        "results": results,
    }


def main():
    """Read SQL from stdin or arguments and print a portability report."""
    if len(sys.argv) > 1:
        # First argument is source dialect, SQL comes from stdin.
        source_dialect = sys.argv[1]
    else:
        source_dialect = "postgres"

    sql = sys.stdin.read().strip()
    if not sql:
        print(json.dumps({"error": "No SQL provided. Pipe SQL via stdin."}))
        sys.exit(1)

    report = analyse_portability(sql, source_dialect)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
