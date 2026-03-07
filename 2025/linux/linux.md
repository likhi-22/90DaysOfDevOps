# Week 2: Linux System Administration & Automation

> **Project:** DevOps Linux Server Monitoring & Automation
> You're managing a Linux-based production server and need to ensure that users, logs, and processes are well-managed. Tasks cover log analysis, volume management, and automation.

---

## Table of Contents

1. [Task 1 – User & Group Management](#task-1--user--group-management)
2. [Task 2 – File & Directory Permissions](#task-2--file--directory-permissions)
3. [Task 3 – Log File Analysis with AWK, Grep & Sed](#task-3--log-file-analysis-with-awk-grep--sed)
4. [Task 4 – Volume Management & Disk Usage](#task-4--volume-management--disk-usage)
5. [Task 5 – Process Management & Monitoring](#task-5--process-management--monitoring)
6. [Task 6 – Automate Backups with Shell Scripting](#task-6--automate-backups-with-shell-scripting)
7. [Bonus Tasks](#bonus-tasks)

---

## Task 1 – User & Group Management

### Background

Linux manages access through users and groups defined in two key files:

| File | Purpose |
|---|---|
| `/etc/passwd` | Stores user account information (username, UID, home dir, shell) |
| `/etc/group` | Stores group definitions and group memberships |
| `/etc/shadow` | Stores hashed passwords (readable only by root) |
| `/etc/sudoers` | Defines which users/groups can run commands as root |

---

### Step 1 – Create a group and user

```bash
# Create the devops_team group
sudo groupadd devops_team

# Create devops_user with a home directory and bash shell
sudo useradd -m -s /bin/bash -G devops_team devops_user

# Verify the user was created
id devops_user
# Expected output: uid=1001(devops_user) gid=1001(devops_user) groups=1001(devops_user),1002(devops_team)

# Verify group membership
cat /etc/group | grep devops_team
```

### Step 2 – Set a password

```bash
sudo passwd devops_user
# You will be prompted to enter and confirm the new password
```

### Step 3 – Grant sudo access

```bash
# Method 1: Add user to the sudo group (recommended)
sudo usermod -aG sudo devops_user

# Method 2: Add a dedicated sudoers entry (more controlled)
sudo visudo
# Add the following line at the end of the file:
# devops_user ALL=(ALL:ALL) ALL

# Verify sudo access
sudo -l -U devops_user
```

### Step 4 – Restrict SSH login in `/etc/ssh/sshd_config`

```bash
# Open the SSH daemon config file
sudo nano /etc/ssh/sshd_config
```

Add or modify the following directives:

```
# Allow only specific users to SSH in
AllowUsers devops_user ubuntu

# OR deny specific users
DenyUsers test_user guest

# Disable root SSH login entirely (recommended for production)
PermitRootLogin no

# Disable password authentication (use SSH keys only)
PasswordAuthentication no
```

```bash
# Restart SSH to apply changes
sudo systemctl restart sshd

# Verify the service is running
sudo systemctl status sshd
```

> **Important:** Always keep an active SSH session open while making changes to `sshd_config`. If your changes are wrong, you can still revert them without getting locked out.

---

## Task 2 – File & Directory Permissions

### Background – Understanding Linux Permissions

Every file and directory in Linux has three permission sets:

| Set | Who |
|---|---|
| **Owner (u)** | The user who owns the file |
| **Group (g)** | Members of the file's assigned group |
| **Others (o)** | Everyone else |

Each set has three permission bits:

| Symbol | Octal | Meaning |
|---|---|---|
| `r` | 4 | Read |
| `w` | 2 | Write |
| `x` | 1 | Execute |
| `-` | 0 | No permission |

---

### Step 1 – Create the workspace and file

```bash
# Create the directory
sudo mkdir /devops_workspace

# Create a file inside it
sudo touch /devops_workspace/project_notes.txt

# Write some content to it
echo "DevOps Week 2 - Project Notes" | sudo tee /devops_workspace/project_notes.txt
```

### Step 2 – Set ownership

```bash
# Assign devops_user as owner and devops_team as group
sudo chown devops_user:devops_team /devops_workspace
sudo chown devops_user:devops_team /devops_workspace/project_notes.txt
```

### Step 3 – Set permissions

**Requirement:** Owner can edit (rw-), group can read (r--), others have no access (---)

```bash
# Using octal notation: 6=rw, 4=r, 0=---
sudo chmod 640 /devops_workspace/project_notes.txt

# Set directory permissions: owner full, group read+execute, others none
sudo chmod 750 /devops_workspace
```

### Step 4 – Verify with `ls -l`

```bash
ls -l /devops_workspace/
```

Expected output:

```
-rw-r----- 1 devops_user devops_team 34 Jan 14 10:22 project_notes.txt
```

Permission breakdown:

```
- rw- r-- ---
│  │   │   └── Others: no access
│  │   └────── Group: read only
│  └────────── Owner: read + write
└──────────── File type: - = regular file, d = directory
```

```bash
# Also verify the directory itself
ls -ld /devops_workspace/
# Expected: drwxr-x--- 2 devops_user devops_team 4096 Jan 14 10:22 /devops_workspace/
```

---

## Task 3 – Log File Analysis with AWK, Grep & Sed

### Setup – Download the log file

```bash
# Download Linux_2k.log from LogHub GitHub repository
wget https://raw.githubusercontent.com/logpai/loghub/master/Linux/Linux_2k.log

# Verify it downloaded correctly
wc -l Linux_2k.log
head -5 Linux_2k.log
```

A typical log line looks like:

```
Jun 14 15:16:01 combo sshd(pam_unix)[19939]: authentication failure; logname= uid=0 euid=0 tty=NODEVssh ruser= rhost=218.188.2.4
```

---

### grep – Search for patterns

```bash
# Find all lines containing "error" (case-insensitive)
grep -i "error" Linux_2k.log

# Count how many error lines exist
grep -ic "error" Linux_2k.log

# Show line numbers alongside matches
grep -in "error" Linux_2k.log

# Find lines with "error" but exclude "no error"
grep -i "error" Linux_2k.log | grep -vi "no error"

# Find authentication failures
grep "authentication failure" Linux_2k.log

# Extract lines matching multiple patterns
grep -E "error|warning|critical" Linux_2k.log
```

---

### awk – Extract and transform fields

```bash
# Print the timestamp (fields 1-3) and the rest of the log message
awk '{print $1, $2, $3, $5}' Linux_2k.log

# Extract timestamp and log level (assumes standard syslog format)
awk '{print "Timestamp:", $1, $2, $3, "| Process:", $5}' Linux_2k.log

# Count occurrences of each unique process/service
awk '{print $5}' Linux_2k.log | sort | uniq -c | sort -nr | head -10

# Print only lines where the 5th field contains "sshd"
awk '$5 ~ /sshd/' Linux_2k.log

# Count total log entries per day
awk '{print $1, $2}' Linux_2k.log | sort | uniq -c | sort -nr
```

---

### sed – Stream editing and substitution

```bash
# Replace all IPv4 addresses with [REDACTED]
sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[REDACTED]/g' Linux_2k.log

# Save the redacted version to a new file
sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/[REDACTED]/g' Linux_2k.log > Linux_2k_redacted.log

# Verify the replacement worked
grep -c "\[REDACTED\]" Linux_2k_redacted.log

# Delete blank lines from the log
sed '/^$/d' Linux_2k.log

# Replace "error" with "ERROR" for consistent formatting
sed 's/error/ERROR/gi' Linux_2k.log
```

---

### Bonus – Most frequent log entries

```bash
# Top 10 most frequent complete log messages
awk '{$1=$2=$3=$4=""; print $0}' Linux_2k.log | \
  sed 's/^ *//' | \
  sort | uniq -c | sort -nr | head -10

# Top 10 most frequent log sources/processes
awk '{print $5}' Linux_2k.log | \
  sort | uniq -c | sort -nr | head -10

# Count entries per hour
awk '{print $3}' Linux_2k.log | \
  cut -d: -f1 | \
  sort | uniq -c | sort -nr
```

---

## Task 4 – Volume Management & Disk Usage

### Step 1 – Create the mount directory

```bash
sudo mkdir -p /mnt/devops_data
```

### Step 2 – Create and mount a loop device (local practice)

A loop device lets you simulate a disk volume using a regular file — useful when you don't have a spare physical disk.

```bash
# Create a 500MB empty file to act as a virtual disk
sudo dd if=/dev/zero of=/tmp/devops_volume.img bs=1M count=500

# Format it with ext4 filesystem
sudo mkfs.ext4 /tmp/devops_volume.img

# Mount it to our directory
sudo mount -o loop /tmp/devops_volume.img /mnt/devops_data

# Verify the mount
df -h /mnt/devops_data
mount | grep devops_data
```

### Step 3 – Make the mount persistent (optional for real volumes)

```bash
# Get the UUID of the volume (for real block devices)
sudo blkid /dev/xvdf

# Add to /etc/fstab for automatic mounting on boot
echo "UUID=<your-uuid>  /mnt/devops_data  ext4  defaults  0  2" | sudo tee -a /etc/fstab

# For a loop device in /etc/fstab (lab use only):
echo "/tmp/devops_volume.img  /mnt/devops_data  ext4  loop  0  0" | sudo tee -a /etc/fstab
```

### Step 4 – Verify disk usage

```bash
# Human-readable disk usage for all mounted filesystems
df -h

# Check only the devops_data mount
df -h /mnt/devops_data

# Check how much space a directory uses
du -sh /mnt/devops_data

# Show disk usage for all items in a directory (sorted)
du -sh /mnt/devops_data/* | sort -rh

# Confirm it appears in the mount list
mount | grep devops_data
```

Expected `df -h` output:

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0      477M  2.3M  446M   1% /mnt/devops_data
```

---

## Task 5 – Process Management & Monitoring

### Step 1 – Start a background process

```bash
# Run ping in the background, redirect output to a log file
ping google.com > ping_test.log &

# The shell prints the job number and PID, e.g.:
# [1] 12345

# Note the PID for later use
echo "Background PID: $!"
```

### Step 2 – Monitor with `ps`

```bash
# List all running processes (detailed)
ps aux

# Filter for the ping process specifically
ps aux | grep ping

# Show process tree to see parent-child relationships
ps -ef --forest | grep ping

# Show just PID and command for ping
ps -C ping -o pid,cmd
```

### Step 3 – Monitor with `top`

```bash
# Launch interactive top (press q to quit)
top

# Useful top keybindings:
# P  – sort by CPU usage
# M  – sort by memory usage
# k  – kill a process (enter PID when prompted)
# 1  – show per-CPU usage

# Non-interactive: show top 10 processes once and exit
top -bn1 | head -20
```

### Step 4 – Monitor with `htop` (enhanced top)

```bash
# Install htop if not present
sudo apt install htop -y       # Debian/Ubuntu
sudo yum install htop -y       # RHEL/Amazon Linux

# Launch htop
htop

# Useful htop keybindings:
# F3 or /  – search for a process by name
# F9       – kill selected process
# F6       – sort by column
# F5       – tree view
```

### Step 5 – Check the log output

```bash
# View real-time output of the ping log
tail -f ping_test.log

# Count how many pings have been logged so far
wc -l ping_test.log
```

### Step 6 – Kill the process and verify

```bash
# Get the PID of the ping process
PID=$(pgrep ping)
echo "Killing PID: $PID"

# Send SIGTERM (graceful stop)
kill $PID

# If it doesn't stop, force kill with SIGKILL
kill -9 $PID

# Verify the process is gone
ps aux | grep ping
# You should only see the grep command itself, not the ping process

# Alternatively, use pkill to kill by name
pkill ping
```

---

## Task 6 – Automate Backups with Shell Scripting

### Step 1 – Create the backups directory

```bash
sudo mkdir -p /backups
sudo chown devops_user:devops_team /backups
```

### Step 2 – Write the backup script

```bash
sudo nano /usr/local/bin/devops_backup.sh
```

Paste the following script:

```bash
#!/bin/bash
# ============================================================
# devops_backup.sh
# Backs up /devops_workspace to /backups with a datestamped
# tar.gz archive. Designed for the 90 Days of DevOps challenge.
# ============================================================

# --- Configuration ---
SOURCE_DIR="/devops_workspace"
BACKUP_DIR="/backups"
DATE=$(date +%F)
BACKUP_FILE="backup_${DATE}.tar.gz"
FULL_PATH="${BACKUP_DIR}/${BACKUP_FILE}"
LOG_FILE="${BACKUP_DIR}/backup.log"

# --- Colour codes ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No colour (reset)

# --- Pre-flight checks ---
echo -e "${YELLOW}[INFO]${NC} Starting backup: $(date '+%Y-%m-%d %H:%M:%S')"

if [ ! -d "$SOURCE_DIR" ]; then
  echo -e "${RED}[ERROR]${NC} Source directory $SOURCE_DIR does not exist. Aborting."
  exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
  echo -e "${YELLOW}[INFO]${NC} Backup directory not found. Creating $BACKUP_DIR..."
  mkdir -p "$BACKUP_DIR"
fi

# --- Create the backup ---
echo -e "${YELLOW}[INFO]${NC} Compressing $SOURCE_DIR → $FULL_PATH"

tar -czf "$FULL_PATH" "$SOURCE_DIR" 2>/dev/null

# --- Verify success ---
if [ $? -eq 0 ]; then
  SIZE=$(du -sh "$FULL_PATH" | cut -f1)
  echo -e "${GREEN}[SUCCESS]${NC} Backup completed successfully!"
  echo -e "${GREEN}[SUCCESS]${NC} File: $FULL_PATH | Size: $SIZE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') SUCCESS $FULL_PATH $SIZE" >> "$LOG_FILE"
else
  echo -e "${RED}[ERROR]${NC} Backup failed. Check permissions and disk space."
  echo "$(date '+%Y-%m-%d %H:%M:%S') FAILED $FULL_PATH" >> "$LOG_FILE"
  exit 1
fi

# --- Remove backups older than 7 days ---
echo -e "${YELLOW}[INFO]${NC} Cleaning up backups older than 7 days..."
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -delete
echo -e "${GREEN}[DONE]${NC} Cleanup complete."
```

### Step 3 – Make the script executable and test it

```bash
# Set execute permission
sudo chmod +x /usr/local/bin/devops_backup.sh

# Run manually to verify it works
sudo /usr/local/bin/devops_backup.sh

# Check the output file was created
ls -lh /backups/
cat /backups/backup.log
```

Expected output:

```
[INFO]   Starting backup: 2025-01-14 10:30:00
[INFO]   Compressing /devops_workspace → /backups/backup_2025-01-14.tar.gz
[SUCCESS] Backup completed successfully!
[SUCCESS] File: /backups/backup_2025-01-14.tar.gz | Size: 12K
[INFO]   Cleaning up backups older than 7 days...
[DONE]   Cleanup complete.
```

### Step 4 – Schedule with cron

```bash
# Open the crontab editor for the current user
crontab -e

# Add the following line to run the backup every day at 2:00 AM
0 2 * * * /usr/local/bin/devops_backup.sh >> /backups/cron.log 2>&1
```

**Cron syntax reference:**

```
┌─────── minute (0–59)
│ ┌───── hour (0–23)
│ │ ┌─── day of month (1–31)
│ │ │ ┌─ month (1–12)
│ │ │ │ ┌ day of week (0–7, 0 and 7 = Sunday)
│ │ │ │ │
0 2 * * *  /usr/local/bin/devops_backup.sh
```

```bash
# Verify the cron job was saved
crontab -l

# Check cron service is running
sudo systemctl status cron      # Debian/Ubuntu
sudo systemctl status crond     # RHEL/Amazon Linux
```

---

## Bonus Tasks

### Bonus 1 – Top 5 most common log messages

```bash
# Strip the variable timestamp fields (columns 1-3) and count remaining message text
awk '{$1=$2=$3=""; print $0}' Linux_2k.log | \
  sed 's/^ *//' | \
  sort | uniq -c | sort -nr | head -5
```

---

### Bonus 2 – Files modified in the last 7 days

```bash
# Find all files modified within the last 7 days from current directory
find . -type f -mtime -7

# Search system-wide (exclude /proc and /sys to avoid noise)
find / -type f -mtime -7 \
  -not -path "/proc/*" \
  -not -path "/sys/*" \
  2>/dev/null

# Show modification time alongside filename
find . -type f -mtime -7 -exec ls -lh {} \;
```

---

### Bonus 3 – Script to extract ERROR and WARNING logs

```bash
sudo nano /usr/local/bin/extract_errors.sh
```

```bash
#!/bin/bash
# ============================================================
# extract_errors.sh
# Extracts ERROR and WARNING lines from Linux_2k.log and
# displays a formatted summary report.
# ============================================================

LOG_FILE="${1:-Linux_2k.log}"
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ ! -f "$LOG_FILE" ]; then
  echo -e "${RED}[ERROR]${NC} Log file not found: $LOG_FILE"
  echo "Usage: $0 <path-to-log-file>"
  exit 1
fi

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  Log Analysis Report: $LOG_FILE${NC}"
echo -e "${CYAN}  Generated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# --- Counts ---
TOTAL=$(wc -l < "$LOG_FILE")
ERROR_COUNT=$(grep -ic "error" "$LOG_FILE")
WARN_COUNT=$(grep -ic "warning" "$LOG_FILE")

echo -e "  Total log lines : ${GREEN}$TOTAL${NC}"
echo -e "  ERROR entries   : ${RED}$ERROR_COUNT${NC}"
echo -e "  WARNING entries : ${YELLOW}$WARN_COUNT${NC}"
echo ""

# --- ERROR lines ---
echo -e "${RED}━━━ ERROR ENTRIES ━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
grep -i "error" "$LOG_FILE" | while read -r line; do
  echo -e "  ${RED}[ERROR]${NC} $line"
done

echo ""

# --- WARNING lines ---
echo -e "${YELLOW}━━━ WARNING ENTRIES ━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
grep -i "warning" "$LOG_FILE" | while read -r line; do
  echo -e "  ${YELLOW}[WARN]${NC}  $line"
done

echo ""
echo -e "${CYAN}============================================${NC}"
echo -e "${GREEN}  Analysis complete.${NC}"
echo -e "${CYAN}============================================${NC}"
```

```bash
# Make executable and run
chmod +x /usr/local/bin/extract_errors.sh
/usr/local/bin/extract_errors.sh Linux_2k.log

# Save output to a file
/usr/local/bin/extract_errors.sh Linux_2k.log > error_report.txt
```

---

## Quick Reference Summary

| Task | Key Commands |
|---|---|
| User management | `useradd`, `usermod`, `passwd`, `groupadd`, `id` |
| File permissions | `chmod`, `chown`, `ls -l`, `umask` |
| Log analysis | `grep -i`, `awk '{print $1}'`, `sed 's/pattern/replace/g'` |
| Disk / volumes | `df -h`, `du -sh`, `mount`, `dd`, `mkfs.ext4` |
| Process control | `ps aux`, `top`, `htop`, `kill`, `pkill`, `pgrep` |
| Backup & cron | `tar -czf`, `crontab -e`, `find -mtime` |
