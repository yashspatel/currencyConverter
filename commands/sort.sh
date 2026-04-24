#!/usr/bin/env bash

sort_main() {
  require_csv

  local column=""
  local descending="false"
  local arg

  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --column)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --column"
        column="$1"
        ;;
      --desc)
        descending="true"
        ;;
      *)
        fail "Unknown option for sort: $arg"
        ;;
    esac
    shift
  done

  [[ -n "$column" ]] || fail "--column is required"
  validate_column "$column"

  local index sort_flag
  index="$(column_index "$column")"
  sort_flag=""
  [[ "$descending" == "true" ]] && sort_flag="-r"

  print_table_header
  {
    tail -n +2 "$CSV_FILE" | if [[ "$column" == "rate" ]]; then
  sort -t',' -k"${index},${index}" $sort_flag
else
  sort -t',' -k"${index},${index}" $sort_flag
fi
  } | print_csv_rows
}
