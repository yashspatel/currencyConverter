#!/usr/bin/env bash

convert_main() {
  require_csv

  local amount=""
  local from_currency=""
  local to_currency=""
  local arg

  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --amount)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --amount"
        amount="$1"
        ;;
      --from)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --from"
        from_currency="${1^^}"
        ;;
      --to)
        shift
        [[ $# -gt 0 ]] || fail "Missing value for --to"
        to_currency="${1^^}"
        ;;
      *)
        fail "Unknown option for convert: $arg"
        ;;
    esac
    shift
  done

  [[ -n "$amount" ]] || fail "--amount is required"
  [[ -n "$from_currency" ]] || fail "--from is required"
  [[ -n "$to_currency" ]] || fail "--to is required"
  is_numeric "$amount" || fail "--amount must be numeric"

  local base_currency rate_from rate_to
  base_currency="$(current_base_currency)"
  [[ -n "$base_currency" ]] || fail "CSV contains no data rows"

  if [[ "$from_currency" == "$base_currency" ]]; then
    rate_from="1"
  else
    rate_from="$(lookup_rate "$from_currency")"
  fi

  if [[ "$to_currency" == "$base_currency" ]]; then
    rate_to="1"
  else
    rate_to="$(lookup_rate "$to_currency")"
  fi

  [[ -n "${rate_from:-}" ]] || fail "Currency not found in CSV: $from_currency"
  [[ -n "${rate_to:-}" ]] || fail "Currency not found in CSV: $to_currency"

  awk -v amount="$amount" -v rate_from="$rate_from" -v rate_to="$rate_to" -v from="$from_currency" -v to="$to_currency" '
    BEGIN {
      converted = (amount / rate_from) * rate_to
      printf "%.6f %s = %.6f %s\n", amount, from, converted, to
    }
  '
}
