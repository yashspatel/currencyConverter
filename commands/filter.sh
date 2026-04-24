#!/usr/bin/env bash

filter_main() {
  require_csv

  local column=""
  local operator=""
  local value=""
  local arg

  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --column)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --column"
        column="$1"
        ;;
      --op)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --op"
        operator="$1"
        ;;
      --value)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --value"
        value="$1"
        ;;
      *)
        fail "Unknown option for filter: $arg"
        ;;
    esac
    shift
  done

  [[ -n "$column" ]] || fail "--column is required"
  [[ -n "$operator" ]] || fail "--op is required"
  [[ -n "$value" ]] || fail "--value is required"
  validate_column "$column"

  local index
  index="$(column_index "$column")"

  print_table_header
  awk -F',' -v idx="$index" -v op="$operator" -v value="$value" '
    function lower(s) {
      return tolower(s)
    }

    function matches(cell) {
      if (op == "eq") return index(cell, value) > 0
      if (op == "ne") return cell != value
      if (op == "contains") return index(lower(cell), lower(value)) > 0

      if (op == "gt") return cell > value
      if (op == "ge") return cell >= value
      if (op == "lt") return cell < value
      if (op == "le") return cell <= value

      return 0
    }

    NR == 1 { next }
    matches($idx) {
      printf "%-8s %-14s %-14s\n", $1, $2, $3
    }
  ' "$CSV_FILE"
}
