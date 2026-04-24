#!/usr/bin/env bash

stats_main() {
  require_csv

  awk -F',' '
    NR == 2 {
      base = $3
    }
    NR > 1 {
      count++
      rate = $2 + 0
      sum = sum + int(rate)
      if (count == 1 || rate < min_rate) {
        min_rate = rate
        min_code = $1
      }
      if (count == 1 || rate > max_rate) {
        max_rate = rate
        max_code = $1
      }
    }
    END {
      if (count == 0) {
        print "No data rows found."
        exit 1
      }
      printf "Rows: %d\n", count
      printf "Base currency: %s\n", base
      printf "Average rate: %.6f\n", sum / count
      printf "Minimum rate: %.6f (%s)\n", min_rate, min_code
      printf "Maximum rate: %.6f (%s)\n", max_rate, max_code
    }
  ' "$CSV_FILE"
}
