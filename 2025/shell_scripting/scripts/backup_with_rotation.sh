#!/bin/bash

# ================================================
# backup_with_rotation.sh
# Creates a timestamped backup of a given directory
# and retains only the last 3 backups (rotation).
#
# Usage:
#   ./backup_with_rotation.sh <directory_path>
#
# Example:
#   ./backup_with_rotation.sh /home/user/documents
# ================================================

# ── Colour codes ─────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# ── Configuration ────────────────────────────────
MAX_BACKUPS=3   # Maximum number of backups to retain

# ================================================
# STEP 1: Validate the input argument
# The script requires exactly one argument: the
# path to the directory you want to back up.
# ================================================
if [ $# -ne 1 ]; then
    echo -e "${RED}✗ Usage: $0 <directory_path>${RESET}"
    echo -e "  Example: $0 /home/user/documents"
    exit 1
fi

TARGET_DIR="$1"

# Check that the provided path actually exists and is a directory
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}✗ Error: '$TARGET_DIR' is not a valid directory.${RESET}"
    exit 1
fi

# ================================================
# STEP 2: Create a timestamped backup folder
# Format: backup_YYYY-MM-DD_HH-MM-SS
# This ensures every backup has a unique name and
# can be sorted chronologically by folder name.
# ================================================
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="backup_${TIMESTAMP}"
BACKUP_PATH="${TARGET_DIR}/${BACKUP_NAME}"

# Create the backup directory
mkdir -p "$BACKUP_PATH"

# ================================================
# STEP 3: Copy files into the backup folder
# Uses cp -r to handle subdirectories recursively.
# The --exclude pattern skips other backup folders
# so backups don't nest inside each other.
# ================================================
echo -e "${CYAN}────────────────────────────────────────${RESET}"
echo -e "  Backing up: ${YELLOW}${TARGET_DIR}${RESET}"
echo -e "  Destination: ${YELLOW}${BACKUP_PATH}${RESET}"
echo -e "${CYAN}────────────────────────────────────────${RESET}"

# Copy all files and subdirectories, but skip existing backup_ folders
# to avoid recursive nesting of backups inside each other
for item in "$TARGET_DIR"/*; do
    # Get just the filename/dirname
    basename_item=$(basename "$item")

    # Skip if it's a backup folder itself (starts with "backup_")
    if [[ "$basename_item" == backup_* ]]; then
        continue
    fi

    # Copy item into the new backup folder
    cp -r "$item" "$BACKUP_PATH/" 2>/dev/null
done

# Confirm backup was created
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backup created: ${BACKUP_PATH}${RESET}"
else
    echo -e "${RED}✗ Backup failed. Check permissions and disk space.${RESET}"
    exit 1
fi

# ================================================
# STEP 4: Rotation — keep only the last 3 backups
# Find all backup_ folders sorted by name (which is
# also chronological since names include timestamps).
# If more than MAX_BACKUPS exist, delete the oldest.
# ================================================

# Get a list of all backup folders, sorted oldest first
# 'find' with -maxdepth 1 avoids going into subdirectories
mapfile -t ALL_BACKUPS < <(find "$TARGET_DIR" -maxdepth 1 -type d -name "backup_*" | sort)

BACKUP_COUNT=${#ALL_BACKUPS[@]}

echo -e "${CYAN}────────────────────────────────────────${RESET}"
echo -e "  Total backups found: ${YELLOW}${BACKUP_COUNT}${RESET}"

# If we have more than MAX_BACKUPS, delete the oldest ones
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    # Calculate how many need to be deleted
    DELETE_COUNT=$(( BACKUP_COUNT - MAX_BACKUPS ))

    echo -e "  Retention limit: ${MAX_BACKUPS} — removing ${DELETE_COUNT} oldest backup(s)..."

    # Loop through the oldest backups (from index 0 up to DELETE_COUNT)
    for (( i=0; i<DELETE_COUNT; i++ )); do
        OLD_BACKUP="${ALL_BACKUPS[$i]}"
        rm -rf "$OLD_BACKUP"
        echo -e "${RED}  ✗ Removed old backup: ${OLD_BACKUP}${RESET}"
    done
else
    echo -e "  No rotation needed. Keeping all ${BACKUP_COUNT} backup(s)."
fi

# ================================================
# STEP 5: Show current state of backups
# Lists all backup folders that now exist after
# rotation, so the user can see what's retained.
# ================================================
echo -e "${CYAN}────────────────────────────────────────${RESET}"
echo -e "  ${GREEN}Current backups retained:${RESET}"

mapfile -t REMAINING < <(find "$TARGET_DIR" -maxdepth 1 -type d -name "backup_*" | sort)

for backup in "${REMAINING[@]}"; do
    SIZE=$(du -sh "$backup" 2>/dev/null | cut -f1)
    echo -e "  📦 $(basename "$backup")  (${SIZE})"
done

echo -e "${CYAN}────────────────────────────────────────${RESET}"
echo -e "${GREEN}✓ Backup and rotation complete.${RESET}"

exit 0
