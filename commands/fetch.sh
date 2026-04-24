#!/usr/bin/env bash

fetch_main() {
  local base_currency="USD"
  local arg

  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --base)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --base"
        base_currency="${1^^}"
        ;;
      *)
        fail "Unknown option for fetch: $arg"
        ;;
    esac
    shift
  done

  require_dependency curl
  ensure_data_dir

  local tmp_json tmp_csv
  tmp_json="$(mktemp)"
  tmp_csv="$(mktemp)"
  trap 'rm -f "$tmp_json" "$tmp_csv"' RETURN

  log "Fetching exchange rates for base currency $base_currency"
  curl -s "$API_BASE_URL/$base_currency" -o "$tmp_json"

  write_csv_from_json "$tmp_json" "$tmp_csv"
  mv "$tmp_csv" "$CSV_FILE"

  log "Stored $(csv_row_count) rows at $CSV_FILE"
}
