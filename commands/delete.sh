#!/usr/bin/env bash

delete_main() {
  require_csv

  local currency_code=""
  local arg

  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --code)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --code"
        currency_code="${1^^}"
        ;;
      *)
        fail "Unknown option for delete: $arg"
        ;;
    esac
    shift
  done

  [[ -n "$currency_code" ]] || fail "--code is required"

  local tmp_file before_count after_count
  tmp_file="$(mktemp)"
  before_count="$(csv_row_count)"

  awk -F',' -v code="$currency_code" '
  NR == 1 || index($1, code) == 0 { print $0 }
' "$CSV_FILE" >"$tmp_file"

  mv "$tmp_file" "$CSV_FILE"
  after_count="$(csv_row_count)"

  if [[ "$after_count" -eq "$before_count" ]]; then
    fail "Currency not found in CSV: $currency_code"
  fi

  log "Deleted row for $currency_code"
}
