#!/usr/bin/env bash

set -euo pipefail

APP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$APP_DIR/lib/common.sh"
source "$APP_DIR/lib/ui.sh"

usage() {
  cat <<'EOF'
fx-data-cli

Usage:
  ./fx_data_cli.sh
  ./fx_data_cli.sh menu
  ./fx_data_cli.sh fetch [--base USD]
  ./fx_data_cli.sh list [--limit 10]
  ./fx_data_cli.sh sort --column rate [--desc]
  ./fx_data_cli.sh filter --column rate --op gt --value 1
  ./fx_data_cli.sh convert --amount 100 --from USD --to EUR
  ./fx_data_cli.sh stats
  ./fx_data_cli.sh update --code EUR --rate 0.93
  ./fx_data_cli.sh delete --code EUR
  ./fx_data_cli.sh help

Commands:
  menu     Open the interactive numbered interface.
  fetch    Pull exchange-rate data from a free public API and overwrite the CSV.
  list     Show CSV rows in a readable table.
  sort     Sort rows by a supported column.
  filter   Filter rows by column, operator, and value.
  convert  Convert an amount using the rates currently stored in the CSV.
  stats    Print summary metrics for the current dataset.
  update   Update a rate in the CSV or add a missing currency row.
  delete   Delete a currency row from the CSV.

Columns:
  code, rate, base_currency

Operators:
  eq, ne, gt, ge, lt, le, contains

Notes:
  - The CSV file is written to ./data/fx_rates.csv by default.
  - JSON parsing uses Bash and standard shell tools only.
EOF
}

load_command_modules() {
  source "$APP_DIR/commands/fetch.sh"
  source "$APP_DIR/commands/list.sh"
  source "$APP_DIR/commands/sort.sh"
  source "$APP_DIR/commands/filter.sh"
  source "$APP_DIR/commands/convert.sh"
  source "$APP_DIR/commands/stats.sh"
  source "$APP_DIR/commands/update.sh"
  source "$APP_DIR/commands/delete.sh"
}

handle_flow_signal() {
  case "$1" in
    "$MENU_BACK")
      return 0
      ;;
    "$MENU_EXIT")
      APP_SHOULD_EXIT=1
      return 0
      ;;
  esac

  return 1
}

ensure_csv_for_menu() {
  if csv_has_data; then
    return 0
  fi

  banner
  warning_text "No dataset found yet. Use option 1 to fetch API data first."
  press_enter
  return 1
}

choose_base_currency() {
  while true; do
    banner
    menu_title "Fetch Rates"
    menu_option 1 "USD"
    menu_option 2 "EUR"
    menu_option 3 "GBP"
    menu_option 4 "INR"
    menu_option 5 "JPY"
    menu_option 6 "Enter custom code"
    menu_back_exit
    line

    case "$(prompt_number 'Choose base currency:')" in
      1) printf 'USD'; return ;;
      2) printf 'EUR'; return ;;
      3) printf 'GBP'; return ;;
      4) printf 'INR'; return ;;
      5) printf 'JPY'; return ;;
      6)
        printf '%s' "$(choose_custom_text_value 'Custom Base Currency' 'Enter 3-letter currency code:' 'currency code' | tr '[:lower:]' '[:upper:]')"
        return
        ;;
      9) printf '%s' "$MENU_BACK"; return ;;
      0) printf '%s' "$MENU_EXIT"; return ;;
      *) error_text "Choose one of the listed numbers."; press_enter ;;
    esac
  done
}

choose_limit() {
  while true; do
    banner
    menu_title "List Rows"
    menu_option 1 "Show 10 rows"
    menu_option 2 "Show 25 rows"
    menu_option 3 "Show 50 rows"
    menu_option 4 "Show 100 rows"
    menu_back_exit
    line

    case "$(prompt_number 'Choose limit:')" in
      1) printf '10'; return ;;
      2) printf '25'; return ;;
      3) printf '50'; return ;;
      4) printf '100'; return ;;
      9) printf '%s' "$MENU_BACK"; return ;;
      0) printf '%s' "$MENU_EXIT"; return ;;
      *) error_text "Choose one of the listed numbers."; press_enter ;;
    esac
  done
}

choose_sort_column() {
  while true; do
    banner
    menu_title "Sort Rows"
    menu_option 1 "Currency code"
    menu_option 2 "Rate"
    menu_option 3 "Base currency"
    menu_back_exit
    line

    case "$(prompt_number 'Choose column:')" in
      1) printf 'code'; return ;;
      2) printf 'rate'; return ;;
      3) printf 'base_currency'; return ;;
      9) printf '%s' "$MENU_BACK"; return ;;
      0) printf '%s' "$MENU_EXIT"; return ;;
      *) error_text "Choose one of the listed numbers."; press_enter ;;
    esac
  done
}

choose_sort_order() {
  while true; do
    banner
    menu_title "Sort Order"
    menu_option 1 "Ascending"
    menu_option 2 "Descending"
    menu_back_exit
    line

    case "$(prompt_number 'Choose order:')" in
      1) printf 'asc'; return ;;
      2) printf 'desc'; return ;;
      9) printf '%s' "$MENU_BACK"; return ;;
      0) printf '%s' "$MENU_EXIT"; return ;;
      *) error_text "Choose one of the listed numbers."; press_enter ;;
    esac
  done
}

choose_filter_column() {
  choose_sort_column
}

choose_filter_operator() {
  while true; do
    banner
    menu_title "Filter Operator"
    menu_option 1 "Equals"
    menu_option 2 "Not equal"
    menu_option 3 "Greater than"
    menu_option 4 "Greater than or equal"
    menu_option 5 "Less than"
    menu_option 6 "Less than or equal"
    menu_option 7 "Contains"
    menu_back_exit
    line

    case "$(prompt_number 'Choose operator:')" in
      1) printf 'eq'; return ;;
      2) printf 'ne'; return ;;
      3) printf 'gt'; return ;;
      4) printf 'ge'; return ;;
      5) printf 'lt'; return ;;
      6) printf 'le'; return ;;
      7) printf 'contains'; return ;;
      9) printf '%s' "$MENU_BACK"; return ;;
      0) printf '%s' "$MENU_EXIT"; return ;;
      *) error_text "Choose one of the listed numbers."; press_enter ;;
    esac
  done
}

choose_custom_text_value() {
  local title="$1"
  local prompt_label="$2"
  local description="$3"
  local choice value

  while true; do
    banner
    menu_title "$title"
    menu_option 1 "Enter $description"
    menu_back_exit
    line

    choice="$(prompt_number 'Choose an option:')"
    case "$choice" in
      1)
        value="$(prompt_text "$prompt_label")"
        printf '%s' "$value"
        return
        ;;
      9)
        printf '%s' "$MENU_BACK"
        return
        ;;
      0)
        printf '%s' "$MENU_EXIT"
        return
        ;;
      *)
        error_text "Choose one of the listed numbers."
        press_enter
        ;;
    esac
  done
}

choose_currency_from_csv() {
  require_csv
  while true; do
    banner
    menu_title "$1"
    print_currency_indexed
    line
    menu_back_exit
    line

    local choice
    choice="$(prompt_number 'Choose currency number:')"

    if [[ "$choice" -ge 1 && "$choice" -le "$(currency_count)" ]]; then
      printf '%s' "$(currency_by_index "$choice")"
      return
    fi

    if [[ "$choice" == "9" ]]; then
      printf '%s' "$MENU_BACK"
      return
    fi

    if [[ "$choice" == "0" ]]; then
      printf '%s' "$MENU_EXIT"
      return
    fi

    error_text "Choose a number from the list."
    press_enter
  done
}

interactive_fetch() {
  local base_currency
  base_currency="$(choose_base_currency)"
  handle_flow_signal "$base_currency" && return
  banner
  run_action "Fetching latest rates..." fetch_main --base "$base_currency"
  press_enter
}

interactive_list() {
  ensure_csv_for_menu 

  local limit
  limit="$(choose_limit)"
  handle_flow_signal "$limit" && return

  banner
  menu_title "Dataset Preview"
  list_main --limit "$limit"
  press_enter
}

interactive_sort() {
  ensure_csv_for_menu || return
  local column order
  column="$(choose_sort_column)"
  handle_flow_signal "$column" && return
  order="$(choose_sort_order)"
  handle_flow_signal "$order" && return
  banner
  menu_title "Sorted Results"
  if [[ "$order" == "desc" ]]; then
    sort_main --column "$column" --desc
  else
    sort_main --column "$column"
  fi
  press_enter
}

interactive_filter() {
  ensure_csv_for_menu || return
  local column operator value
  column="$(choose_filter_column)"
  handle_flow_signal "$column" && return
  operator="$(choose_filter_operator)"
  handle_flow_signal "$operator" && return
  value="$(choose_custom_text_value 'Filter Value' 'Enter filter value:' 'filter value')"
  handle_flow_signal "$value" && return
  banner
  menu_title "Filtered Results"
  filter_main --column "$column" --op "$operator" --value "$value"
  press_enter
}

interactive_convert() {
  ensure_csv_for_menu || return
  local amount from_currency to_currency
  amount="$(choose_custom_text_value 'Conversion Amount' 'Enter amount:' 'amount')"
  handle_flow_signal "$amount" && return
  from_currency="$(choose_currency_from_csv 'From Currency')"
  handle_flow_signal "$from_currency" && return
  to_currency="$(choose_currency_from_csv 'To Currency')"
  handle_flow_signal "$to_currency" && return
  banner
  menu_title "Conversion Result"
  convert_main --amount "$amount" --from "$from_currency" --to "$to_currency"
  press_enter
}

interactive_stats() {
  ensure_csv_for_menu || return
  banner
  menu_title "Dataset Statistics"
  stats_main
  press_enter
}

interactive_update() {
  ensure_csv_for_menu || return
  local currency_code new_rate
  currency_code="$(choose_currency_from_csv 'Choose Currency To Update')"
  handle_flow_signal "$currency_code" && return
  banner
  warning_text "Current rate for $currency_code: $(lookup_rate "$currency_code")"
  new_rate="$(choose_custom_text_value 'Update Rate' 'Enter new rate:' 'new rate')"
  handle_flow_signal "$new_rate" && return
  banner
  run_action "Saving rate..." update_main --code "$currency_code" --rate "$new_rate"
  press_enter
}

interactive_delete() {
  ensure_csv_for_menu || return
  local currency_code confirm
  currency_code="$(choose_currency_from_csv 'Choose Currency To Delete')"
  handle_flow_signal "$currency_code" && return
  banner
  warning_text "You are about to delete $currency_code."
  menu_option 1 "Confirm delete"
  menu_option 9 "Back"
  menu_option 0 "Exit"
  line
  confirm="$(prompt_number 'Choose: ')"
  if [[ "$confirm" == "1" ]]; then
    banner
    run_action "Deleting row..." delete_main --code "$currency_code"
    press_enter
  elif [[ "$confirm" == "0" ]]; then
    APP_SHOULD_EXIT=1
  fi
}

interactive_menu() {
  load_command_modules
  APP_SHOULD_EXIT=0

  while true; do
    banner
    menu_title "Main Menu"
    menu_option 1 "Fetch fresh API data"
    menu_option 2 "List rows"
    menu_option 3 "Sort rows"
    menu_option 4 "Filter rows"
    menu_option 5 "Convert currency"
    menu_option 6 "View dataset stats"
    menu_option 7 "Update a rate"
    menu_option 8 "Delete a rate"
    menu_option 9 "Help"
    menu_option 0 "Exit"
    line

    # BUG: truncates multi-digit input (e.g. 12 → 1)
    choice="$(prompt_number 'Choose an action:')"
    choice="${choice:0:1}"

    case "$choice" in
      1) interactive_fetch ;;
      2) interactive_list ;;
      3) interactive_sort ;;
      4) interactive_filter ;;
      5) interactive_convert ;;
      6) interactive_stats ;;
      7) interactive_update ;;
      8) interactive_delete ;;
      9)
        banner
        usage
        press_enter
        ;;
      0)
        banner
        success_text "Session closed."
        return
        ;;
      *)
        error_text "Choose one of the listed numbers."
        press_enter
        ;;
    esac

    if [[ "${APP_SHOULD_EXIT:-0}" == "1" ]]; then
      banner
      success_text "Session closed."
      return
    fi
  done
}

main() {
  local command="${1:-menu}"

  case "$command" in
    menu)
      interactive_menu
      ;;
    fetch)
      shift
      load_command_modules
      fetch_main "$@"
      ;;
    list)
      shift
      load_command_modules
      list_main "$@"
      ;;
    sort)
      shift
      load_command_modules
      sort_main "$@"
      ;;
    filter)
      shift
      load_command_modules
      filter_main "$@"
      ;;
    convert)
      shift
      load_command_modules
      convert_main "$@"
      ;;
    stats)
      shift
      load_command_modules
      stats_main "$@"
      ;;
    update)
      shift
      load_command_modules
      update_main "$@"
      ;;
    delete)
      shift
      load_command_modules
      delete_main "$@"
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      fail "Unknown command: $command"
      ;;
  esac
}

main "$@"
