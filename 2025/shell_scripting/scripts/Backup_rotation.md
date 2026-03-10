# 🔄 Challenge 2: Automated Backup with Rotation
### Week 3 — Bash Scripting Challenges

---

## Overview

A bash script (`backup_with_rotation.sh`) that creates timestamped backups of any directory and automatically enforces a 3-backup retention limit — deleting the oldest backups when the limit is exceeded.

---

## Usage

```bash
./backup_with_rotation.sh <directory_path>
```

**Example:**
```bash
./backup_with_rotation.sh /home/user/documents
```

---

## How It Works

```
Step 1 → Validate the directory argument
Step 2 → Create backup_YYYY-MM-DD_HH-MM-SS/ inside the target directory
Step 3 → Copy all files (skipping other backup_ folders)
Step 4 → Count existing backups — if > 3, delete the oldest
Step 5 → Display remaining backups with sizes
```

---

## Example Run — First Execution

```bash
./backup_with_rotation.sh /home/sneha/documents
```

**Output:**
```
────────────────────────────────────────
  Backing up: /home/sneha/documents
  Destination: /home/sneha/documents/backup_2025-03-07_21-05-10
────────────────────────────────────────
✓ Backup created: /home/sneha/documents/backup_2025-03-07_21-05-10
────────────────────────────────────────
  Total backups found: 1
  No rotation needed. Keeping all 1 backup(s).
────────────────────────────────────────
  Current backups retained:
  📦 backup_2025-03-07_21-05-10  (4.0K)
────────────────────────────────────────
✓ Backup and rotation complete.
```

---

## Example Run — After 4 Backups Exist (Rotation Triggers)

```bash
./backup_with_rotation.sh /home/sneha/documents
```

**Output:**
```
────────────────────────────────────────
  Backing up: /home/sneha/documents
  Destination: /home/sneha/documents/backup_2025-03-08_09-15-30
────────────────────────────────────────
✓ Backup created: /home/sneha/documents/backup_2025-03-08_09-15-30
────────────────────────────────────────
  Total backups found: 4
  Retention limit: 3 — removing 1 oldest backup(s)...
  ✗ Removed old backup: /home/sneha/documents/backup_2025-03-07_21-05-10
────────────────────────────────────────
  Current backups retained:
  📦 backup_2025-03-07_21-30-45  (4.0K)
  📦 backup_2025-03-07_22-10-00  (4.0K)
  📦 backup_2025-03-08_09-15-30  (4.0K)
────────────────────────────────────────
✓ Backup and rotation complete.
```

---

## Directory State After Rotation

```
/home/sneha/documents/
├── backup_2025-03-07_21-30-45/    ← retained
├── backup_2025-03-07_22-10-00/    ← retained
├── backup_2025-03-08_09-15-30/    ← retained (newest)
├── file1.txt
├── file2.txt
└── notes.md
```

The oldest backup (`backup_2025-03-07_21-05-10`) was automatically removed.

---

## Schedule with Cron

To run the backup automatically every day at 2 AM:

```bash
crontab -e
```

Add:
```
0 2 * * * /path/to/backup_with_rotation.sh /home/sneha/documents >> /var/log/backup_rotation.log 2>&1
```

---

## Script: [scripts/backup_with_rotation.sh](./scripts/backup_with_rotation.sh)

---

## Key Bash Concepts Used

| Concept | Where Used |
|---------|-----------|
| `date +"%Y-%m-%d_%H-%M-%S"` | Generating the timestamp for the backup name |
| `mapfile -t` | Storing `find` output into an array |
| `find -maxdepth 1 -name "backup_*"` | Listing only backup folders, not nested content |
| `sort` | Sorting backups chronologically (oldest first) |
| Array indexing `${ALL_BACKUPS[$i]}` | Accessing specific backups for deletion |
| `du -sh` | Showing human-readable backup size |
| `[[ "$name" == backup_* ]]` | Skipping backup folders during file copy |
| `$#` | Validating that exactly one argument was passed |
