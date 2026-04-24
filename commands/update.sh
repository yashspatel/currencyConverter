#!/usr/bin/env bash

update_main() {
  require_csv

  local currency_code=""
  local new_rate=""
  local arg

  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --code)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --code"
        currency_code="${1^^}"
        ;;
      --rate)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --rate"
        new_rate="$1"
        ;;
      *)
        fail "Unknown option for update: $arg"
        ;;
    esac
    shift
  done

  [[ -n "$currency_code" ]] || fail "--code is required"
  [[ -n "$new_rate" ]] || fail "--rate is required"
  is_numeric "$new_rate" || fail "--rate must be numeric"

  local tmp_file base_currency
  tmp_file="$(mktemp)"
  base_currency="$(current_base_currency)"

  awk -F',' -v code="$currency_code" -v rate="$new_rate" -v base="$base_currency" '
    BEGIN {
      OFS = ","
      found = 0
    }
    NR == 1 {
      print $0
      next
    }
    $1 ~ code {
      print code, rate, base
      found = 1
      next
    }
    {
      print $0
    }
    END {
      if (found == 0) {
        print code, rate, base
      }
    }
  ' "$CSV_FILE" >"$tmp_file"

  {
    head -n 1 "$tmp_file"
    tail -n +2 "$tmp_file" | sort -t',' -k1,1
  } >"${tmp_file}.sorted"

  mv "${tmp_file}.sorted" "$CSV_FILE"
  rm -f "$tmp_file"

  log "Saved rate for $currency_code"
}
