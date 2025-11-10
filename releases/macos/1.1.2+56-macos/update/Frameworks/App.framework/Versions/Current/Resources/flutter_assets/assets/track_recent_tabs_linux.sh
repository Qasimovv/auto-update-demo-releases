#!/bin/bash

# Basic browser tab tracking script for Linux
# Usage: ./track_recent_tabs_linux.sh [output_file]

OUTPUT_FILE=${1:-"/tmp/browser_tabs_output.txt"}

# Function to get Chrome/Chromium tabs
get_chrome_tabs() {
    local browser=$1
    local history_file=$2
    
    if [ -f "$history_file" ]; then
        echo "${browser}=$(sqlite3 "$history_file" "SELECT json_group_array(json_object(
            'url', url,
            'title', title,
            'last_visit_time', last_visit_time
        )) FROM (
            SELECT url, title, last_visit_time 
            FROM urls 
            WHERE last_visit_time > 0 
            ORDER BY last_visit_time DESC 
            LIMIT 5
        );")"
  fi
}

# Function to get Firefox tabs
get_firefox_tabs() {
    local profile_dir=$1
    
    if [ -f "$profile_dir/places.sqlite" ]; then
        echo "firefox=$(sqlite3 "$profile_dir/places.sqlite" "SELECT json_group_array(json_object(
            'url', url,
            'title', title,
            'last_visit_date', last_visit_date
        )) FROM (
            SELECT url, title, last_visit_date 
            FROM moz_places 
            WHERE last_visit_date > 0 
            ORDER BY last_visit_date DESC 
            LIMIT 5
        );")"
  fi
}

# Main execution
{
    # Chrome/Chromium tabs
    chrome_dir="$HOME/.config/google-chrome/Default"
    chromium_dir="$HOME/.config/chromium/Default"
    
    get_chrome_tabs "chrome" "$chrome_dir/History"
    get_chrome_tabs "chromium" "$chromium_dir/History"
    
    # Firefox tabs
    firefox_dir="$HOME/.mozilla/firefox"
    if [ -d "$firefox_dir" ]; then
        profile=$(ls -1 "$firefox_dir" | grep "\.default" | head -n 1)
        if [ -n "$profile" ]; then
            get_firefox_tabs "$firefox_dir/$profile"
        fi
    fi
    
} > "$OUTPUT_FILE" 