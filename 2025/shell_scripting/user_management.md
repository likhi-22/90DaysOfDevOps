# 👤 Challenge 1: User Account Management
### Week 3 — Bash Scripting Challenges

---

## Overview

A bash script (`user_management.sh`) that manages Linux user accounts via command-line flags. Covers creation, deletion, password reset, listing, and detailed info — with validation and color-coded output throughout.

---

## Usage

```bash
sudo ./user_management.sh [OPTION]
```

| Flag | Action |
|------|--------|
| `-c` / `--create` | Create a new user account |
| `-d` / `--delete` | Delete an existing user account |
| `-r` / `--reset` | Reset a user's password |
| `-l` / `--list` | List all users with UID, home, shell |
| `-i` / `--info` | Detailed info about a specific user (bonus) |
| `-h` / `--help` | Show usage information |

---

## Part 1: Create a User (`--create`)

```bash
sudo ./user_management.sh --create
```

**Sample interaction:**
```
────────────────────────────────────────
  Create New User Account
────────────────────────────────────────
  Enter new username: devops_user
  Enter password for 'devops_user': ••••••••
  Confirm password: ••••••••
  ✓ User 'devops_user' created successfully.
  Home directory: /home/devops_user
  UID: 1002
────────────────────────────────────────
```

**What the script checks:**
- Username is not empty
- Username doesn't already exist (`id "$username"`)
- Both password entries match before applying

**Command used internally:**
```bash
useradd -m -s /bin/bash "$username"
echo "$username:$password" | chpasswd
```

---

## Part 2: Delete a User (`--delete`)

```bash
sudo ./user_management.sh --delete
```

**Sample interaction:**
```
────────────────────────────────────────
  Delete User Account
────────────────────────────────────────
  Enter username to delete: devops_user
  Are you sure you want to delete 'devops_user'? [y/N]: y
  ✓ User 'devops_user' has been deleted successfully.
────────────────────────────────────────
```

**Safeguards:**
- Checks user exists before attempting deletion
- Blocks deletion of `root` account
- Asks for explicit confirmation before proceeding
- Uses `userdel -r` to remove home directory too

---

## Part 3: Reset Password (`--reset`)

```bash
sudo ./user_management.sh --reset
```

**Sample interaction:**
```
────────────────────────────────────────
  Reset User Password
────────────────────────────────────────
  Enter username: devops_user
  Enter new password for 'devops_user': ••••••••
  Confirm new password: ••••••••
  ✓ Password for 'devops_user' has been reset successfully.
────────────────────────────────────────
```

---

## Part 4: List Users (`--list`)

```bash
./user_management.sh --list
```

**Sample output:**
```
────────────────────────────────────────
  User Accounts on this System
────────────────────────────────────────
  USERNAME             UID      HOME DIRECTORY            SHELL
  ──────────────────────────────────────────────────────────────────
  root                 0        /root                     /bin/bash
  sneha                1000     /home/sneha               /bin/bash
  devops_user          1002     /home/devops_user         /bin/bash
────────────────────────────────────────
```

Filters out system accounts (UID < 1000) to show only real human users.

---

## Part 5: Help (`--help`)

```bash
./user_management.sh --help
```

**Sample output:**
```
────────────────────────────────────────
  User Account Management Script
────────────────────────────────────────
  Usage: ./user_management.sh [OPTION]

  -c, --create   Create a new user account
  -d, --delete   Delete an existing user account
  -r, --reset    Reset a user's password
  -l, --list     List all user accounts and UIDs
  -h, --help     Show this help message
  -i, --info     Show detailed info about a user

  Examples:
    sudo ./user_management.sh --create
    sudo ./user_management.sh --list
────────────────────────────────────────
```

---

## Bonus: Detailed User Info (`--info`)

```bash
./user_management.sh --info
```

**Sample output:**
```
  Username:       devops_user
  UID:            1002
  GID:            1002
  Groups:         devops_user devops_team sudo
  Home Directory: /home/devops_user
  Shell:          /bin/bash
  Last Login:     Never logged in
```

---

## Script: [scripts/user_management.sh](./scripts/user_management.sh)

---

## Key Bash Concepts Used

| Concept | Where Used |
|---------|-----------|
| `case` statement | Routing command-line flags to functions |
| `id "$username"` | Checking if a user exists |
| `read -rsp` | Reading passwords silently (no echo) |
| `chpasswd` | Setting passwords non-interactively |
| `getent passwd` | Reading user info from `/etc/passwd` |
| `IFS=:` | Parsing colon-separated `/etc/passwd` fields |
| Color codes (`\e[32m`) | Green/red/yellow terminal output |
