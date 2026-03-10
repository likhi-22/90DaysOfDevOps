#!/bin/bash

# ================================================
# user_management.sh
# A bash script to manage Linux user accounts.
# Supports: create, delete, reset password, list, help
#
# Usage:
#   ./user_management.sh [OPTION]
#
# Options:
#   -c | --create   Create a new user account
#   -d | --delete   Delete an existing user account
#   -r | --reset    Reset password for an existing user
#   -l | --list     List all user accounts with UIDs
#   -h | --help     Show this help message
# ================================================

# ── Colour codes for output ──────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helper: print a divider line ─────────────────
divider() {
    echo -e "${CYAN}────────────────────────────────────────${RESET}"
}

# ================================================
# PART 5: Help / Usage
# Displays all available options and their purpose
# ================================================
show_help() {
    divider
    echo -e "${BOLD}  User Account Management Script${RESET}"
    divider
    echo -e "  ${BOLD}Usage:${RESET} $0 [OPTION]"
    echo ""
    echo -e "  ${YELLOW}-c, --create${RESET}   Create a new user account"
    echo -e "  ${YELLOW}-d, --delete${RESET}   Delete an existing user account"
    echo -e "  ${YELLOW}-r, --reset${RESET}    Reset a user's password"
    echo -e "  ${YELLOW}-l, --list${RESET}     List all user accounts and UIDs"
    echo -e "  ${YELLOW}-h, --help${RESET}     Show this help message"
    echo ""
    echo -e "  ${BOLD}Examples:${RESET}"
    echo -e "    sudo $0 --create"
    echo -e "    sudo $0 --delete"
    echo -e "    sudo $0 --reset"
    echo -e "    $0 --list"
    divider
}

# ================================================
# PART 1: Create a New User Account
# - Prompts for username and password
# - Checks if username already exists
# - Creates the user with a home directory
# - Sets the password
# ================================================
create_user() {
    divider
    echo -e "${BOLD}  Create New User Account${RESET}"
    divider

    # Prompt for username
    read -rp "  Enter new username: " username

    # Validate: username must not be empty
    if [ -z "$username" ]; then
        echo -e "${RED}  ✗ Username cannot be empty.${RESET}"
        exit 1
    fi

    # Check if the username already exists in /etc/passwd
    if id "$username" &>/dev/null; then
        echo -e "${RED}  ✗ Username '$username' already exists. Choose a different name.${RESET}"
        exit 1
    fi

    # Prompt for password (hidden input)
    read -rsp "  Enter password for '$username': " password
    echo ""
    read -rsp "  Confirm password: " password_confirm
    echo ""

    # Validate: passwords must match
    if [ "$password" != "$password_confirm" ]; then
        echo -e "${RED}  ✗ Passwords do not match. Aborting.${RESET}"
        exit 1
    fi

    # Create the user with a home directory and bash shell
    useradd -m -s /bin/bash "$username"

    # Set the password using chpasswd (reads from stdin)
    echo "$username:$password" | chpasswd

    # Confirm success
    echo -e "${GREEN}  ✓ User '$username' created successfully.${RESET}"
    echo -e "  Home directory: /home/$username"
    echo -e "  UID: $(id -u "$username")"
    divider
}

# ================================================
# PART 2: Delete an Existing User Account
# - Prompts for username
# - Checks if username exists
# - Deletes the user and their home directory
# ================================================
delete_user() {
    divider
    echo -e "${BOLD}  Delete User Account${RESET}"
    divider

    # Prompt for username to delete
    read -rp "  Enter username to delete: " username

    # Validate: username must not be empty
    if [ -z "$username" ]; then
        echo -e "${RED}  ✗ Username cannot be empty.${RESET}"
        exit 1
    fi

    # Check if the username exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}  ✗ User '$username' does not exist.${RESET}"
        exit 1
    fi

    # Safety: do not allow deletion of root
    if [ "$username" = "root" ]; then
        echo -e "${RED}  ✗ Deleting the root account is not allowed.${RESET}"
        exit 1
    fi

    # Confirm deletion
    read -rp "  Are you sure you want to delete '$username'? This cannot be undone. [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}  Deletion cancelled.${RESET}"
        exit 0
    fi

    # Delete the user and their home directory (-r flag)
    userdel -r "$username" 2>/dev/null

    echo -e "${GREEN}  ✓ User '$username' has been deleted successfully.${RESET}"
    divider
}

# ================================================
# PART 3: Reset a User's Password
# - Prompts for username and new password
# - Checks if username exists
# - Updates the password
# ================================================
reset_password() {
    divider
    echo -e "${BOLD}  Reset User Password${RESET}"
    divider

    # Prompt for username
    read -rp "  Enter username: " username

    # Validate: username must not be empty
    if [ -z "$username" ]; then
        echo -e "${RED}  ✗ Username cannot be empty.${RESET}"
        exit 1
    fi

    # Check if username exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}  ✗ User '$username' does not exist.${RESET}"
        exit 1
    fi

    # Prompt for new password (hidden input)
    read -rsp "  Enter new password for '$username': " new_password
    echo ""
    read -rsp "  Confirm new password: " new_password_confirm
    echo ""

    # Validate: passwords must match
    if [ "$new_password" != "$new_password_confirm" ]; then
        echo -e "${RED}  ✗ Passwords do not match. Aborting.${RESET}"
        exit 1
    fi

    # Apply the new password
    echo "$username:$new_password" | chpasswd

    echo -e "${GREEN}  ✓ Password for '$username' has been reset successfully.${RESET}"
    divider
}

# ================================================
# PART 4: List All User Accounts
# - Reads from /etc/passwd
# - Displays username, UID, home directory, shell
# - Filters out system accounts (UID < 1000)
#   to show only real users (bonus: --all flag shows all)
# ================================================
list_users() {
    divider
    echo -e "${BOLD}  User Accounts on this System${RESET}"
    divider
    printf "  ${CYAN}%-20s %-8s %-25s %-15s${RESET}\n" "USERNAME" "UID" "HOME DIRECTORY" "SHELL"
    echo -e "  ──────────────────────────────────────────────────────────────────"

    # Parse /etc/passwd: fields are colon-separated
    # Format: username:x:UID:GID:comment:home:shell
    while IFS=: read -r uname _ uid _ _ home shell; do
        # Show all human users (UID >= 1000) and root (UID = 0)
        if [ "$uid" -ge 1000 ] || [ "$uid" -eq 0 ]; then
            printf "  %-20s %-8s %-25s %-15s\n" "$uname" "$uid" "$home" "$shell"
        fi
    done < /etc/passwd

    divider
}

# ================================================
# BONUS: Detailed info about a specific user
# Shows everything: groups, last login, shell, etc.
# ================================================
user_info() {
    divider
    echo -e "${BOLD}  Detailed User Information${RESET}"
    divider
    read -rp "  Enter username to inspect: " username

    if ! id "$username" &>/dev/null; then
        echo -e "${RED}  ✗ User '$username' does not exist.${RESET}"
        exit 1
    fi

    echo -e "  ${YELLOW}Username:${RESET}       $username"
    echo -e "  ${YELLOW}UID:${RESET}            $(id -u "$username")"
    echo -e "  ${YELLOW}GID:${RESET}            $(id -g "$username")"
    echo -e "  ${YELLOW}Groups:${RESET}         $(id -Gn "$username")"
    echo -e "  ${YELLOW}Home Directory:${RESET} $(getent passwd "$username" | cut -d: -f6)"
    echo -e "  ${YELLOW}Shell:${RESET}          $(getent passwd "$username" | cut -d: -f7)"
    echo -e "  ${YELLOW}Last Login:${RESET}     $(lastlog -u "$username" | tail -1 | awk '{print $4, $5, $6, $7, $8, $9}')"
    divider
}

# ================================================
# ENTRY POINT: Argument Parsing
# Routes to the correct function based on the flag
# ================================================

# Show help if no argument provided
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Parse the command-line argument
case "$1" in
    -c | --create)
        create_user
        ;;
    -d | --delete)
        delete_user
        ;;
    -r | --reset)
        reset_password
        ;;
    -l | --list)
        list_users
        ;;
    -i | --info)
        # Bonus: detailed user info
        user_info
        ;;
    -h | --help)
        show_help
        ;;
    *)
        # Unknown flag
        echo -e "${RED}  ✗ Unknown option: $1${RESET}"
        echo -e "  Run ${YELLOW}$0 --help${RESET} for usage."
        exit 1
        ;;
esac

exit 0
