#!/usr/bin/env bash

list_main() {
  require_csv

  local limit=10
  local arg

  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --limit)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --limit"
        limit="$1"
        is_numeric "$limit" || fail "--limit must be numeric"
        ;;
      *)
        fail "Unknown option for list: $arg"
        ;;
    esac
    shift
  done

  print_table_header
  awk -F',' -v limit="$limit" '
    NR == 1 { next }
    NR <= limit + 1 {
      printf "%-8s %-14s %-14s\n", $1, $2, $3
    }
  ' "$CSV_FILE"
}
