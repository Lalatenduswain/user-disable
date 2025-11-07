# 🧑‍💻 user-disable.sh — Interactive Linux User Disable/Enable Automation Script

> 🔒 A safe and fully automated **user account management tool** for Linux (Ubuntu/Debian-based systems) that lets system administrators **disable, lock, or re-enable** user accounts **interactively** while backing up all related data — including SSH keys, crontabs, and home directories.

---

## 📌 Features

✅ **Interactive Mode** – No arguments required. The script will ask you:
- Whether to `disable` or `enable` a user
- The username
- Confirmation before performing sensitive operations

✅ **Automatic Backups**
- Backs up `.ssh/authorized_keys`
- Backs up user crontab (if any)
- Optionally compresses and archives the user’s home directory

✅ **Account Protection**
- Locks password login (`usermod -L`)
- Expires account (`usermod -e 1`)
- Changes shell to `/usr/sbin/nologin` (blocks shell access)
- Kills all active processes owned by the user

✅ **Easy Restoration**
- Automatically restores the account with one command (`enable`)
- Restores shell, SSH keys, and crontab from the backup

✅ **Logging & Reports**
- Creates a timestamped report in `/opt/scan-report/`
- Writes detailed audit logs in `/var/log/user-disable.log`
- Stores all backups under `/root/user-disable-backups/<user>-<timestamp>/`

✅ **Safe and Idempotent**
- Designed to run multiple times safely
- Won’t destroy user data
- Always asks before deleting or modifying sensitive items

---

## 🧠 Script Overview

📜 **Script Name:** `user-disable.sh`  
🧩 **Repository URL:** [https://github.com/Lalatenduswain/user-disable](https://github.com/Lalatenduswain/user-disable)

This script provides system administrators a **single command-line tool** to manage user lifecycle operations — disable, archive, and later re-enable Linux user accounts securely.  
It’s particularly useful for DevOps, Cloud, or Security teams managing multi-user systems, ensuring compliance with access control and data retention policies.

---

## 🧰 Prerequisites

Before running this script, make sure:

### 🧾 Required privileges
- You must have **sudo or root access** on the system.
  ```bash
  sudo -i   # or run commands with sudo
````

### 📦 Required system tools

Ensure these standard utilities are available:

| Tool                                                  | Purpose                        |
| ----------------------------------------------------- | ------------------------------ |
| `bash`                                                | Required shell interpreter     |
| `tar`                                                 | Used for home directory backup |
| `gzip`                                                | Compression support            |
| `usermod`, `deluser`, `crontab`, `id`                 | Core Linux account management  |
| `tee`, `awk`, `grep`, `chmod`, `cp`, `pkill`, `mkdir` | Utilities for file operations  |
| `sudo`                                                | To execute privileged actions  |
| `tee`                                                 | For logging output safely      |

Most are preinstalled on Ubuntu/Debian. You can verify:

```bash
sudo apt install passwd coreutils procps tar gzip util-linux -y
```

---

## 📖 Installation Guide

### Step 1️⃣ — Clone the Repository

```bash
git clone https://github.com/Lalatenduswain/user-disable.git
cd user-disable
```

### Step 2️⃣ — Move Script to System Path

```bash
sudo cp user-disable.sh /usr/local/bin/user-disable.sh
sudo chmod 750 /usr/local/bin/user-disable.sh
```

### Step 3️⃣ — Run the Script (Interactive Mode)

```bash
sudo user-disable.sh
```

You’ll see:

```
Action (disable / enable): disable
Username: testuser
You chose: disable user 'testuser'. Continue? [y/N]: y
Disable SSH key login by chmod 000 /home/testuser/.ssh/authorized_keys? [Y/n]: y
Remove crontab for testuser (backup saved)? [y/N]: n
DISABLE complete. Report: /opt/scan-report/user-disable-testuser-2025-11-07_101300.txt
```

---

## 🖥️ Usage Examples

### 🔒 Disable a user interactively

```bash
sudo user-disable.sh
```

Choose:

```
Action (disable / enable): disable
Username: devopsuser
```

The script will:

* Lock the account
* Expire credentials
* Set shell to `/usr/sbin/nologin`
* Backup SSH keys, crontab, and home folder
* Generate audit logs and reports

---

### 🔓 Re-enable the same user

```bash
sudo user-disable.sh
```

Choose:

```
Action (disable / enable): enable
Username: devopsuser
```

It will:

* Unlock the user
* Reactivate login shell `/bin/bash`
* Restore SSH keys and crontab from backup

---

## 💾 Logs & Reports

| Path                                                       | Description                                 |
| ---------------------------------------------------------- | ------------------------------------------- |
| `/opt/scan-report/user-disable-<username>-<timestamp>.txt` | Detailed disable/enable report              |
| `/var/log/user-disable.log`                                | Persistent audit trail                      |
| `/root/user-disable-backups/<username>-<timestamp>/`       | Backup folder (keys, crontab, home archive) |

**Sample Report:**

```
User disable report for: devopsuser
Timestamp: 2025-11-07_095834
Current shell: /bin/bash

[2025-11-07 09:59:12] START disable devopsuser
[2025-11-07 09:59:12] Backed up /home/devopsuser/.ssh/authorized_keys
[2025-11-07 09:59:20] Disabled /home/devopsuser/.ssh/authorized_keys (chmod 000)
[2025-11-07 09:59:20] Locked and expired account
[2025-11-07 09:59:21] Killed user processes (if any)
[2025-11-07 10:00:24] Attempted home backup to /root/user-disable-backups/devopsuser-2025-11-07_095834
```

---

## 🧩 Directory Structure

```
user-disable/
├── user-disable.sh          # Main script
├── README.md                # Documentation (this file)
└── LICENSE                  # MIT License (recommended)
```

---

## 🛡️ Security & Compliance

* 🔒 Script performs *non-destructive* backups before disabling any account.
* 🧾 Audit logs stored securely in `/var/log/user-disable.log`.
* 🧹 Compliant with Linux access control best practices.
* ⚙️ Works on **Ubuntu / Debian / Amazon Linux 2** (tested).

---

## 💖 Support & Donations

If you find this project helpful or use it in your infrastructure, consider supporting or following me 🌟

**Author:** [Lalatendu Swain](https://github.com/Lalatenduswain)
💼 [Website / Blog](https://blog.lalatendu.info/)
☕ Buy me a coffee or sponsor my GitHub projects ❤️

> Your support helps me maintain and publish more DevOps, Cloud, and Cybersecurity automation scripts.

---

## ⚠️ Disclaimer | Running the Script

**Author:** Lalatendu Swain | [GitHub](https://github.com/Lalatenduswain) | [Website](https://blog.lalatendu.info/)

> ⚠️ Use this script at your own risk.
> This utility modifies system-level user configurations and requires `sudo` privileges.
> Always test in a non-production or staging environment first.
> The author assumes no responsibility for any system issues arising from misuse or modifications of the script.

---

### 🧾 License

This project is licensed under the **MIT License** — you are free to use, modify, and distribute it with attribution to the author.

---

✨ **Clone, Run, and Automate Securely!**

```bash
git clone https://github.com/Lalatenduswain/user-disable.git
cd user-disable
sudo ./user-disable.sh
```

---

```

---

### ✅ Notes for you (Lalatendu)
- Replace your repo name (`user-disable`) with whatever you push the script under.  
- You can add a **`LICENSE`** file (MIT recommended).  
- If you’d like, I can generate a `CONTRIBUTING.md` or `.github/FUNDING.yml` (for donations/sponsorship buttons).
