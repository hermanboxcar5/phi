#!/bin/bash

# Directory to start the search
SEARCH_DIR="/"

# Log file to record deleted files
LOG_FILE="/var/log/deleted_media_files.log"

# Function to find and delete mp3 and mp4 files
remove_media_files() {
    find "$SEARCH_DIR" -type f \( -iname "*.mp3" -o -iname "*.mp4" \) -print -delete | tee -a "$LOG_FILE"
}

# Run the function
remove_media_files

echo "All mp3 and mp4 files have been removed and logged to $LOG_FILE."
