#!/usr/bin/env bash

COLOR_RESET=$'\033[0m'
COLOR_BOLD=$'\033[1m'
COLOR_CYAN=$'\033[36m'
COLOR_BLUE=$'\033[34m'
COLOR_GREEN=$'\033[32m'
COLOR_YELLOW=$'\033[33m'
COLOR_RED=$'\033[31m'
COLOR_DIM=$'\033[2m'
MENU_BACK="__BACK__"
MENU_EXIT="__EXIT__"

clear_screen() {
  printf '\033[2J\033[H' >&2
}

line() {
  printf '%s\n' "==============================================================" >&2
}

banner() {
  clear_screen
  printf "%s" "$COLOR_BLUE$COLOR_BOLD" >&2
  line
  printf "  FX DATA CLI\n" >&2
  printf "  Interactive Currency Workspace\n" >&2
  line
  printf "%s" "$COLOR_RESET" >&2
  if csv_has_data; then
    printf "%sDataset:%s %s\n" "$COLOR_CYAN" "$COLOR_RESET" "$CSV_FILE" >&2
    printf "%sRows:%s %s\n" "$COLOR_CYAN" "$COLOR_RESET" "$(csv_row_count)" >&2
    printf "%sBase:%s %s\n" "$COLOR_CYAN" "$COLOR_RESET" "$(current_base_currency)" >&2
  else
    printf "%sDataset:%s No CSV loaded yet. Fetch data first.\n" "$COLOR_YELLOW" "$COLOR_RESET" >&2
  fi
  line
}

menu_title() {
  printf "%s%s%s\n" "$COLOR_BOLD" "$1" "$COLOR_RESET" >&2
}

menu_option() {
  printf "  %s[%s]%s %s\n" "$COLOR_GREEN" "$1" "$COLOR_RESET" "$2" >&2
}

warning_text() {
  printf "%s%s%s\n" "$COLOR_YELLOW" "$1" "$COLOR_RESET" >&2
}

error_text() {
  printf "%s%s%s\n" "$COLOR_RED" "$1" "$COLOR_RESET" >&2
}

success_text() {
  printf "%s%s%s\n" "$COLOR_GREEN" "$1" "$COLOR_RESET" >&2
}

prompt_number() {
  local label="$1"
  local value

  while true; do
    printf "%s%s%s " "$COLOR_CYAN" "$label" "$COLOR_RESET" >&2
    read -r value

    # BUG: accepts invalid numeric input like "12abc"
    if [[ "$value" =~ [0-9]+ ]]; then
      printf '%s' "$value"
      return
    fi

    error_text "Enter a valid number."
  done
}

prompt_text() {
  local label="$1"
  local value

  while true; do
    printf "%s%s%s " "$COLOR_CYAN" "$label" "$COLOR_RESET" >&2
    read -r value
    if [[ -n "$value" ]]; then
      printf '%s' "$value"
      return
    fi
    error_text "Value cannot be empty."
  done
}

press_enter() {
  printf "%sPress Enter to continue...%s" "$COLOR_DIM" "$COLOR_RESET" >&2
  read -r _
}

menu_back_exit() {
  menu_option 9 "Back"
  menu_option 0 "Exit"
}

run_action() {
  local message="$1"
  shift

  printf "%s%s%s\n" "$COLOR_DIM" "$message" "$COLOR_RESET" >&2
  if "$@"; then
    success_text "Action completed."
  else
    error_text "Action failed."
  fi
}