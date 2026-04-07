#!/usr/bin/env bash
# =============================================================================
#  NVIDIA RTX 3050 Driver Installer for Kali Linux
#  Tested with: Kali Linux 2023.x / 2024.x (rolling)
#  Driver branch: 535+ (supports Ampere / RTX 30xx series)
# =============================================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; exit 1; }

# ── Root check ────────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Run this script as root:  sudo bash $0"

echo -e "\n${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}   NVIDIA RTX 3050 Driver Installer — Kali Linux       ${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}\n"

# ── Step 1: Verify NVIDIA GPU is present ──────────────────────────────────────
info "Checking for NVIDIA GPU..."
if ! lspci | grep -qi nvidia; then
    error "No NVIDIA GPU detected by lspci. Aborting."
fi
GPU=$(lspci | grep -i nvidia | head -1)
success "Found: $GPU"

# ── Step 2: Remove any conflicting/old drivers ─────────────────────────────────
info "Removing old/conflicting NVIDIA packages..."
apt-get remove -y --purge \
    nvidia-driver \
    nvidia-kernel-dkms \
    nvidia-kernel-common \
    xserver-xorg-video-nvidia \
    libgl1-nvidia-glx \
    2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true
success "Old packages removed."

# ── Step 3: Update package lists ──────────────────────────────────────────────
info "Updating package lists..."
apt-get update -y
success "Package lists updated."

# ── Step 4: Install required kernel headers & build tools ─────────────────────
KERNEL=$(uname -r)
info "Installing kernel headers for: $KERNEL"
apt-get install -y \
    linux-headers-"$KERNEL" \
    dkms \
    build-essential \
    libglvnd-dev \
    pkg-config
success "Build tools and kernel headers installed."

# ── Step 5: Add non-free + non-free-firmware repos if missing ─────────────────
SOURCES="/etc/apt/sources.list"
if ! grep -q "non-free" "$SOURCES"; then
    warn "Adding non-free and non-free-firmware components to sources.list..."
    # Kali uses a single deb line — append components
    sed -i 's/main$/main non-free non-free-firmware contrib/' "$SOURCES"
    apt-get update -y
    success "Repos updated with non-free components."
else
    success "non-free repos already present."
fi

# ── Step 6: Install NVIDIA driver (nvidia-driver metapackage) ─────────────────
info "Installing nvidia-driver (DKMS, Ampere-compatible branch)..."
apt-get install -y nvidia-driver nvidia-smi
success "NVIDIA driver installed."

# ── Step 7: Blacklist Nouveau ──────────────────────────────────────────────────
BLACKLIST="/etc/modprobe.d/blacklist-nouveau.conf"
if [[ ! -f "$BLACKLIST" ]]; then
    info "Blacklisting Nouveau open-source driver..."
    cat > "$BLACKLIST" <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
    update-initramfs -u
    success "Nouveau blacklisted and initramfs updated."
else
    success "Nouveau already blacklisted."
fi

# ── Step 8: Verify nvidia-smi works (post-reboot test hint) ───────────────────
info "Attempting a quick nvidia-smi check (may fail before reboot)..."
if nvidia-smi &>/dev/null; then
    echo ""
    nvidia-smi
    echo ""
    success "nvidia-smi works — driver may already be active."
else
    warn "nvidia-smi not yet active. This is normal; a reboot is required."
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  Installation complete!${RESET}"
echo -e "${BOLD}══════════════════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${YELLOW}Next steps:${RESET}"
echo -e "  1.  ${BOLD}Reboot your system:${RESET}  sudo reboot"
echo -e "  2.  After reboot, verify:  ${BOLD}nvidia-smi${RESET}"
echo -e "  3.  Optional CUDA toolkit:  ${BOLD}sudo apt install nvidia-cuda-toolkit${RESET}"
echo ""
