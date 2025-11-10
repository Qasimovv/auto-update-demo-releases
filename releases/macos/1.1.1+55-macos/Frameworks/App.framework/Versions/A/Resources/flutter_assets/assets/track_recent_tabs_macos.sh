#!/bin/bash

# Get the output file path from the argument
output_file="$1"

# Function to get Chrome recent tabs
get_chrome_tabs() {
  local session_path="$HOME/Library/Application Support/Google/Chrome/Default/Sessions"
  local db_path="$HOME/Library/Application Support/Google/Chrome/Default/History"
  local db_copy="${TMPDIR:-/tmp}/chrome_history_copy"

  if [ -d "$session_path" ]; then
    echo "Chrome session path: $session_path" >&2
  else
    echo "Chrome session path not found at $session_path" >&2
  fi

  if [ -f "$db_path" ]; then
    cp "$db_path" "$db_copy"
    sqlite3 -json "$db_copy" "SELECT url, last_visit_time FROM urls ORDER BY last_visit_time DESC LIMIT 10;"
    rm "$db_copy"
  else
    echo '[]'
  fi
}

# Function to get Firefox recent tabs
get_firefox_tabs() {
  local profile_path=$(find "$HOME/Library/Application Support/Firefox/Profiles" -name '*.default-release' -print -quit)
  local db_path="$profile_path/places.sqlite"
  local db_copy="${TMPDIR:-/tmp}/places_copy.sqlite"

  if [ -f "$db_path" ]; then
    cp "$db_path" "$db_copy"
    sqlite3 -json "$db_copy" "SELECT url, last_visit_date FROM moz_places ORDER BY last_visit_date DESC LIMIT 10;"
    rm "$db_copy"
  else
    echo '[]'
  fi
}

# Function to get Safari recent tabs
get_safari_tabs() {
  local db_path="$HOME/Library/Safari/History.db"
  local db_copy="${TMPDIR:-/tmp}/safari_history_copy"

  if [ -f "$db_path" ]; then
    cp "$db_path" "$db_copy"
    sqlite3 -json "$db_copy" "SELECT url, visit_time FROM history_items ORDER BY visit_time DESC LIMIT 10;"
    rm "$db_copy"
  else
    echo '[]'
  fi
}

# Capture recent tabs and save to file
{
  echo -n "chrome="
  get_chrome_tabs
  echo -n "firefox="
  get_firefox_tabs
  echo -n "safari="
  get_safari_tabs
} > "$output_file"

# Output the content of the text file
cat "$output_file"
