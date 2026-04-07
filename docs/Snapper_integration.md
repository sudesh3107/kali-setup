# 🐧 Snapper + GRUB Integration Guide

> Integrate Btrfs snapshots with GRUB for easy system rollback directly from your boot menu.

---

## 📋 Prerequisites

Before you begin, ensure your root filesystem is **Btrfs**. Run:

```bash
df -T /
```

Expected output should contain `btrfs` in the type column:

```
Filesystem     Type  ...
/dev/sdXn      btrfs ...
```

> ⚠️ **This guide will not work without a Btrfs root filesystem.**

Also make sure you have the following packages installed:
- `snapper`
- `grub-btrfs`

---

## 🚀 Setup Steps

### Step 1 — Install Required Packages

> *(Skip if already installed)*

```bash
# Debian/Ubuntu/Kali
sudo apt install snapper grub-btrfs

# Arch Linux
sudo pacman -S snapper grub-btrfs
```

---

### Step 2 — Create Snapper Configuration

```bash
sudo snapper -c root create-config /
```

This command will:
- Create `.snapshots` as a dedicated **Btrfs subvolume**
- Initialize the Snapper configuration for the root (`/`) filesystem

---

### Step 3 — Verify Configuration

```bash
sudo snapper list-configs
```

Expected output:

```
Config | Subvolume
-------+----------
root   | /
```

---

### Step 4 — Create Your First Snapshot

```bash
sudo snapper -c root create --description "Initial snapshot"
```

Verify the snapshot was created:

```bash
sudo snapper -c root list
```

---

### Step 5 — Enable GRUB Snapshot Integration

```bash
sudo systemctl enable --now grub-btrfs.path
sudo update-grub
```

This enables the `grub-btrfs` daemon, which automatically updates the GRUB menu whenever a new snapshot is created.

---

## ✅ Verification

Check that `.snapshots` is properly registered as a Btrfs subvolume:

```bash
sudo btrfs subvolume list /
```

You should see `.snapshots` listed in the output.

Reboot and check your GRUB menu — you should now see a **"Btrfs snapshots"** submenu entry.

---

## 🔄 How It Works

```
Snapper creates snapshot
        ↓
grub-btrfs.path detects change
        ↓
GRUB menu is automatically updated
        ↓
Boot into snapshot from GRUB for rollback
```

---

## 📌 Notes

- Snapshots are stored under `/.snapshots/`
- You can configure automatic snapshot policies (e.g., on package install, timeline) via `/etc/snapper/configs/root`
- To roll back, boot into a snapshot from GRUB and use `snapper rollback` or manually swap subvolumes

---

## 📚 References

- [Snapper Documentation](http://snapper.io/)
- [grub-btrfs GitHub](https://github.com/Antynea/grub-btrfs)
- [Btrfs Wiki](https://btrfs.wiki.kernel.org/)

---

*Guide tested on Btrfs root setups. Distro-specific commands may vary.*
