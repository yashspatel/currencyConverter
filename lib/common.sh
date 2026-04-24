#!/usr/bin/env bash

APP_NAME="fx-data-cli"
APP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${DATA_DIR:-$APP_DIR/data}"
CSV_FILE="${CSV_FILE:-$DATA_DIR/fx_rates.csv}"
API_BASE_URL="${API_BASE_URL:-https://open.er-api.com/v6/latest}"

log() {
  printf '[%s] %s\n' "$APP_NAME" "$*"
}

fail() {
  printf '[%s] ERROR: %s\n' "$APP_NAME" "$*" >&2
  exit 1
}

ensure_data_dir() {
  mkdir -p "$DATA_DIR"
}

require_csv() {
  [[ -f "$CSV_FILE" ]] || fail "CSV not found at $CSV_FILE. Run 'fetch' first."
}

require_dependency() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || fail "Missing required dependency: $command_name"
}

extract_json_string() {
  local key="$1"
  local file="$2"

  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file" | head -n 1
}

extract_json_number() {
  local key="$1"
  local file="$2"

  sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\([-0-9.][0-9.]*\).*/\1/p" "$file" | head -n 1
}

validate_column() {
  case "$1" in
    code|rate|base_currency) ;;
    *) fail "Unsupported column: $1" ;;
  esac
}

column_index() {
  case "$1" in
    code) echo 1 ;;
    rate) echo 2 ;;
    base_currency) echo 3 ;;
    *) fail "Unsupported column: $1" ;;
  esac
}

is_numeric() {
  [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}

csv_row_count() {
  awk 'NR > 1 { count++ } END { print count + 0 }' "$CSV_FILE"
}

csv_has_data() {
  [[ -f "$CSV_FILE" ]] && [[ "$(csv_row_count)" -gt 0 ]]
}

print_table_header() {
  printf "%-8s %-14s %-14s\n" "code" "rate" "base_currency"
  printf "%-8s %-14s %-14s\n" "--------" "--------------" "--------------"
}

print_csv_rows() {
  awk -F',' '
    {
      printf "%-8s %-14s %-14s\n", $1, $2, $3
    }
  '
}

write_csv_from_json() {
  local json_file="$1"
  local output_file="$2"
  local compact_json result error_type base_code rates_block

  compact_json="$(tr -d '\r\n' < "$json_file")"
  result="$(extract_json_string "result" "$json_file")"

  [[ "$result" == "success" ]] || {
    error_type="$(extract_json_string "error-type" "$json_file")"
    fail "${error_type:-API returned a non-success result}"
  }

  base_code="$(extract_json_string "base_code" "$json_file")"
  [[ -n "$base_code" ]] || fail "Could not parse base_code from API response"

  rates_block="${compact_json#*\"rates\":\{"
  [[ "$rates_block" != "$compact_json" ]] || fail "Could not parse rates block from API response"
  rates_block="${rates_block%%\}*}"

  {
    printf '%s\n' 'code,rate'
    printf '%s' "$rates_block" \
      | tr ',' '\n' \
      | sed -n 's/^[[:space:]]*"\([A-Z][A-Z][A-Z]\)"[[:space:]]*:[[:space:]]*\([-0-9.][0-9.]*\)[[:space:]]*$/\1,\2/p' \
      | sort \
      | awk -F',' -v base="$base_code" '
          BEGIN { OFS="," }
          {
            print $1, $2, base
          }
        '
  } >"$output_file"
}

lookup_rate() {
  local currency_code="$1"

  awk -F',' -v target="$currency_code" '
    NR > 1 && $1 == target {
      print $2
      exit
    }
  ' "$CSV_FILE"
}

current_base_currency() {
  awk -F',' 'NR == 2 { print $3; exit }' "$CSV_FILE"
}

currency_count() {
  awk -F',' 'NR > 1 { count++ } END { print count + 0 }' "$CSV_FILE"
}

currency_by_index() {
  local index="$1"
  awk -F',' -v target="$index" '
    NR > 1 {
      row++
      if (row == target) {
        print $1
        exit
      }
    }
  ' "$CSV_FILE"
}

rate_by_index() {
  local index="$1"
  awk -F',' -v target="$index" '
    NR > 1 {
      row++
      if (row == target) {
        print $2
        exit
      }
    }
  ' "$CSV_FILE"
}

print_currency_indexed() {
  awk -F',' '
    NR > 1 {
      row++
      printf "%3d) %-8s %-14s\n", row, $1, $2
    }
  ' "$CSV_FILE" >&2
}
