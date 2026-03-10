#!/bin/bash
# =============================================================================
# kali-gnome-rice.sh — GNOME Rice for Kali Linux
# Themes: catppuccin | rosepine | everforest | lotus | nord | dracula
# Safe: only adds themes/tweaks, nothing system-critical is changed.
# Run as your normal user — sudo is invoked when needed.
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIG — edit before running
# =============================================================================

# Colour theme
# Options: catppuccin | rosepine | everforest | lotus | nord | dracula
RICE="dracula"

# Terminal
# Options: kitty | alacritty | default  (default = keeps gnome-terminal)
TERMINAL="default"

# Shell prompt
# Options: starship | oh-my-zsh | both | none
SHELL_STYLE="both"

# GNOME dock style
# Options: dash-to-dock | dash-to-panel | none
DOCK="dash-to-dock"

# =============================================================================
# COLOURS
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[  ✓  ]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
skip()    { echo -e "${CYAN}[ skip ]${NC} $*"; }
die()     { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }
stage()   { echo -e "\n${BOLD}${CYAN}════════════════════════════════════════════════${NC}";
            echo -e "${BOLD}${CYAN}  $*${NC}";
            echo -e "${BOLD}${CYAN}════════════════════════════════════════════════${NC}"; }

pkg_ok()  { dpkg -s "$1" &>/dev/null; }
apt_get() {
    local to=()
    for p in "$@"; do pkg_ok "$p" && skip "$p" || to+=("$p"); done
    [[ ${#to[@]} -eq 0 ]] && return
    sudo apt-get install -y --no-install-recommends "${to[@]}" \
        && ok "Installed: ${to[*]}" \
        || warn "Some packages failed: ${to[*]}"
}

[[ $EUID -eq 0 ]] && die "Run as your normal user, not root."
grep -qi "kali" /etc/os-release 2>/dev/null || warn "Not Kali? Script may still work on Debian/Ubuntu GNOME."

# =============================================================================
# STAGE 0 — Palette
# =============================================================================
stage "STAGE 0 — Loading palette: ${RICE}"

case "$RICE" in
  catppuccin)
    R_NAME="Catppuccin Mocha"
    R_BG="#1e1e2e"    R_BG2="#181825"   R_BG3="#313244"
    R_FG="#cdd6f4"    R_SUB="#a6adc8"   R_MUTED="#585b70"
    R_ACCENT="#cba6f7" R_ROSE="#f38ba8"  R_TEAL="#94e2d5"
    R_GREEN="#a6e3a1"  R_YELLOW="#f9e2af" R_BLUE="#89b4fa"
    R_LAVENDER="#b4befe" R_PEACH="#fab387"
    R_BORDER="#45475a"
    GTK_THEME="Catppuccin-Mocha-Standard-Lavender-Dark"
    GTK_ICON="Papirus-Dark"
    TERM_CURSOR="#cba6f7"
    WP_COLOR1="1e1e2e" WP_COLOR2="313244" WP_ACCENT="cba6f7"
    ;;
  rosepine)
    R_NAME="Rose Pine Moon"
    R_BG="#232136"    R_BG2="#2a273f"   R_BG3="#393552"
    R_FG="#e0def4"    R_SUB="#908caa"   R_MUTED="#6e6a86"
    R_ACCENT="#c4a7e7" R_ROSE="#eb6f92"  R_TEAL="#9ccfd8"
    R_GREEN="#3e8fb0"  R_YELLOW="#f6c177" R_BLUE="#9ccfd8"
    R_LAVENDER="#c4a7e7" R_PEACH="#ea9a97"
    R_BORDER="#44415a"
    GTK_THEME="rose-pine-moon"
    GTK_ICON="Papirus-Dark"
    TERM_CURSOR="#c4a7e7"
    WP_COLOR1="232136" WP_COLOR2="393552" WP_ACCENT="c4a7e7"
    ;;
  everforest)
    R_NAME="Everforest Dark"
    R_BG="#2d353b"    R_BG2="#272e33"   R_BG3="#3d484d"
    R_FG="#d3c6aa"    R_SUB="#9da9a0"   R_MUTED="#7a8478"
    R_ACCENT="#a7c080" R_ROSE="#e67e80"  R_TEAL="#83c092"
    R_GREEN="#a7c080"  R_YELLOW="#dbbc7f" R_BLUE="#7fbbb3"
    R_LAVENDER="#d699b6" R_PEACH="#e69875"
    R_BORDER="#475258"
    GTK_THEME="Adwaita-dark"
    GTK_ICON="Papirus-Dark"
    TERM_CURSOR="#a7c080"
    WP_COLOR1="2d353b" WP_COLOR2="3d484d" WP_ACCENT="a7c080"
    ;;
  lotus)
    R_NAME="Kanagawa Wave"
    R_BG="#1f1f28"    R_BG2="#16161d"   R_BG3="#2a2a37"
    R_FG="#dcd7ba"    R_SUB="#9cabca"   R_MUTED="#727169"
    R_ACCENT="#7e9cd8" R_ROSE="#c34043"  R_TEAL="#6a9589"
    R_GREEN="#76946a"  R_YELLOW="#c0a36e" R_BLUE="#7e9cd8"
    R_LAVENDER="#957fb8" R_PEACH="#ffa066"
    R_BORDER="#363646"
    GTK_THEME="Adwaita-dark"
    GTK_ICON="Papirus-Dark"
    TERM_CURSOR="#7e9cd8"
    WP_COLOR1="1f1f28" WP_COLOR2="2a2a37" WP_ACCENT="7e9cd8"
    ;;
  nord)
    R_NAME="Nord"
    R_BG="#2e3440"    R_BG2="#242933"   R_BG3="#3b4252"
    R_FG="#eceff4"    R_SUB="#d8dee9"   R_MUTED="#4c566a"
    R_ACCENT="#88c0d0" R_ROSE="#bf616a"  R_TEAL="#8fbcbb"
    R_GREEN="#a3be8c"  R_YELLOW="#ebcb8b" R_BLUE="#5e81ac"
    R_LAVENDER="#b48ead" R_PEACH="#d08770"
    R_BORDER="#434c5e"
    GTK_THEME="Nordic"
    GTK_ICON="Papirus-Dark"
    TERM_CURSOR="#88c0d0"
    WP_COLOR1="2e3440" WP_COLOR2="3b4252" WP_ACCENT="88c0d0"
    ;;
  dracula)
    R_NAME="Dracula"
    R_BG="#282a36"    R_BG2="#21222c"   R_BG3="#44475a"
    R_FG="#f8f8f2"    R_SUB="#6272a4"   R_MUTED="#44475a"
    R_ACCENT="#bd93f9" R_ROSE="#ff5555"  R_TEAL="#8be9fd"
    R_GREEN="#50fa7b"  R_YELLOW="#f1fa8c" R_BLUE="#6272a4"
    R_LAVENDER="#bd93f9" R_PEACH="#ffb86c"
    R_BORDER="#6272a4"
    GTK_THEME="Dracula"
    GTK_ICON="Papirus-Dark"
    TERM_CURSOR="#bd93f9"
    WP_COLOR1="282a36" WP_COLOR2="44475a" WP_ACCENT="bd93f9"
    ;;
  *) die "Unknown RICE '${RICE}'. Choose: catppuccin|rosepine|everforest|lotus|nord|dracula" ;;
esac

ok "Palette: ${R_NAME}"

# =============================================================================
# STAGE 1 — System update & base packages
# =============================================================================
stage "STAGE 1 — System update & base packages"

sudo apt-get update -qq
ok "Package lists updated."

apt_get \
    git curl wget unzip tar \
    build-essential pkg-config pkgconf \
    gnome-tweaks \
    gnome-shell-extension-manager \
    gnome-shell-extensions \
    chrome-gnome-shell \
    dconf-editor \
    \
    python3-pip \
    python3-nautilus \
    \
    neofetch \
    htop btop \
    bat eza ripgrep fd-find \
    \
    lm-sensors \
    brightnessctl \
    playerctl \
    \
    fonts-noto-core \
    fonts-noto fonts-noto-extra \
    fonts-ebgaramond \
    fonts-jetbrains-mono \
    fonts-font-awesome \
    \
    imagemagick \
    nitrogen feh

# =============================================================================
# STAGE 2 — GNOME extensions via apt (Kali repos)
# =============================================================================
stage "STAGE 2 — GNOME extensions"

apt_get \
    gnome-shell-extension-dashtodock \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-blur-my-shell \
    gnome-shell-extension-user-theme \
    2>/dev/null || warn "Some extensions not in Kali repos — install via extensions.gnome.org"

# =============================================================================
# STAGE 3 — GTK theme
# =============================================================================
stage "STAGE 3 — GTK theme (${GTK_THEME})"

THEMES_DIR="$HOME/.themes"
LOCAL_THEMES="$HOME/.local/share/themes"
mkdir -p "$THEMES_DIR" "$LOCAL_THEMES"

install_catppuccin_gtk() {
    local dest="$THEMES_DIR/Catppuccin-Mocha-Standard-Lavender-Dark"
    [[ -d "$dest" ]] && { skip "Catppuccin GTK theme already present"; return; }
    info "Downloading Catppuccin Mocha GTK theme..."
    local url="https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-lavender-standard+default.zip"
    local tmp; tmp=$(mktemp -d)
    wget -q --show-progress -O "$tmp/cat.zip" "$url" \
        && unzip -q "$tmp/cat.zip" -d "$THEMES_DIR/" \
        && ok "Catppuccin GTK installed." \
        || warn "Download failed — falling back to Adwaita-dark"
    rm -rf "$tmp"
}

install_rosepine_gtk() {
    local dest="$LOCAL_THEMES/rose-pine-moon"
    [[ -d "$dest" ]] && { skip "Rose Pine Moon GTK theme already present"; return; }
    info "Downloading Rose Pine Moon GTK theme..."
    local tmp; tmp=$(mktemp -d)
    wget -q --show-progress \
        -O "$tmp/rp.zip" \
        "https://github.com/rose-pine/gtk/releases/latest/download/rose-pine-moon.zip" \
        && unzip -q "$tmp/rp.zip" -d "$LOCAL_THEMES/" \
        && ok "Rose Pine Moon GTK installed." \
        || warn "Download failed — falling back to Adwaita-dark"
    rm -rf "$tmp"
}

install_nord_gtk() {
    local dest="$THEMES_DIR/Nordic"
    [[ -d "$dest" ]] && { skip "Nordic GTK theme already present"; return; }
    info "Downloading Nordic GTK theme..."
    local tmp; tmp=$(mktemp -d)
    wget -q --show-progress \
        -O "$tmp/nordic.tar.xz" \
        "https://github.com/EliverLara/Nordic/releases/latest/download/Nordic.tar.xz" \
        && tar -xf "$tmp/nordic.tar.xz" -C "$THEMES_DIR/" \
        && ok "Nordic GTK installed." \
        || warn "Download failed"
    rm -rf "$tmp"
}

install_dracula_gtk() {
    local dest="$THEMES_DIR/Dracula"
    [[ -d "$dest" ]] && { skip "Dracula GTK theme already present"; return; }
    info "Downloading Dracula GTK theme..."
    local tmp; tmp=$(mktemp -d)
    wget -q --show-progress \
        -O "$tmp/dracula.zip" \
        "https://github.com/dracula/gtk/archive/master.zip" \
        && unzip -q "$tmp/dracula.zip" -d "$tmp/out/" \
        && mv "$tmp/out/gtk-master" "$THEMES_DIR/Dracula" \
        && ok "Dracula GTK installed." \
        || warn "Download failed"
    rm -rf "$tmp"
}

case "$RICE" in
    catppuccin) install_catppuccin_gtk ;;
    rosepine)   install_rosepine_gtk   ;;
    nord)       install_nord_gtk       ;;
    dracula)    install_dracula_gtk    ;;
    *)          apt_get gnome-themes-extra; ok "Using Adwaita-dark" ;;
esac

# =============================================================================
# STAGE 4 — Icons (Papirus)
# =============================================================================
stage "STAGE 4 — Icons"

if pkg_ok papirus-icon-theme; then
    skip "papirus-icon-theme already installed"
else
    info "Installing Papirus icons..."
    wget -q --show-progress \
        -O /tmp/papirus-install.sh \
        "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install.sh" \
        && bash /tmp/papirus-install.sh \
        && ok "Papirus icons installed." \
        || { apt_get papirus-icon-theme && ok "Papirus from apt."; }
fi

# =============================================================================
# STAGE 5 — Nerd Fonts
# =============================================================================
stage "STAGE 5 — JetBrains Mono Nerd Font"

NF_DIR="$HOME/.local/share/fonts/JetBrainsMonoNF"
if fc-list | grep -qi "JetBrainsMono Nerd"; then
    skip "JetBrainsMono Nerd Font already installed"
else
    mkdir -p "$NF_DIR"
    info "Downloading JetBrains Mono Nerd Font..."
    tmp=$(mktemp -d)
    wget -q --show-progress \
        -O "$tmp/JBM.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" \
        && unzip -q "$tmp/JBM.zip" -d "$NF_DIR/" \
        && rm -f "$NF_DIR/"*Windows* \
        && fc-cache -fq \
        && ok "JetBrainsMono Nerd Font installed." \
        || warn "Download failed — install manually from nerdfonts.com"
    rm -rf "$tmp"
fi

# =============================================================================
# STAGE 6 — GTK / GNOME settings via gsettings
# =============================================================================
stage "STAGE 6 — Applying GNOME/GTK settings"

info "Setting GTK theme, icons, fonts..."

# Resolve theme name (handle local themes dir)
RESOLVED_THEME="$GTK_THEME"
[[ -d "$LOCAL_THEMES/$GTK_THEME" ]] && RESOLVED_THEME="$GTK_THEME"
[[ -d "$THEMES_DIR/$GTK_THEME" ]]   && RESOLVED_THEME="$GTK_THEME"

gsettings set org.gnome.desktop.interface gtk-theme        "$RESOLVED_THEME"         2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme       "$GTK_ICON"                2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme     "Adwaita"                  2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name        "Noto Sans 11"             2>/dev/null || true
gsettings set org.gnome.desktop.interface document-font-name "Noto Serif 11"          2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name "JetBrainsMono Nerd Font 10" 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-antialiasing "rgba"                    2>/dev/null || true
gsettings set org.gnome.desktop.interface font-hinting    "slight"                    2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme    "prefer-dark"               2>/dev/null || true
gsettings set org.gnome.desktop.interface enable-animations true                      2>/dev/null || true

# Window button layout
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close" 2>/dev/null || true
gsettings set org.gnome.desktop.wm.preferences titlebar-font "Noto Sans Bold 11"               2>/dev/null || true

# GTK 2
cat > "$HOME/.gtkrc-2.0" << GEOF
gtk-theme-name="${RESOLVED_THEME}"
gtk-icon-theme-name="${GTK_ICON}"
gtk-font-name="Noto Sans 11"
gtk-cursor-theme-name="Adwaita"
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintslight"
gtk-xft-rgba="rgb"
GEOF

# GTK 3
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" << GEOF
[Settings]
gtk-theme-name=${RESOLVED_THEME}
gtk-icon-theme-name=${GTK_ICON}
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=true
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
GEOF

# GTK 4
mkdir -p "$HOME/.config/gtk-4.0"
cp "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

ok "GNOME/GTK settings applied."

# =============================================================================
# STAGE 7 — GNOME Shell user-theme extension + theme apply
# =============================================================================
stage "STAGE 7 — GNOME Shell theme"

# Enable user-theme extension
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true

# Set shell theme (requires user-theme extension)
gsettings set org.gnome.shell.extensions.user-theme name "$RESOLVED_THEME" 2>/dev/null \
    && ok "GNOME Shell theme set to ${RESOLVED_THEME}." \
    || warn "Could not set shell theme — enable 'User Themes' extension in GNOME Extensions app first."

# =============================================================================
# STAGE 8 — Dash-to-Dock / Dash-to-Panel
# =============================================================================
stage "STAGE 8 — Dock (${DOCK})"

case "$DOCK" in
    dash-to-dock)
        gnome-extensions enable dash-to-dock@micxgx.gmail.com 2>/dev/null || true

        gsettings set org.gnome.shell.extensions.dash-to-dock \
            dock-fixed true 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.dash-to-dock \
            dock-position BOTTOM 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.dash-to-dock \
            transparency-mode FIXED 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.dash-to-dock \
            background-opacity 0.85 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.dash-to-dock \
            dash-max-icon-size 36 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.dash-to-dock \
            extend-height false 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.dash-to-dock \
            show-trash false 2>/dev/null || true
        ok "Dash-to-Dock configured."
        ;;
    none) skip "Dock configuration skipped." ;;
esac

# =============================================================================
# STAGE 9 — Terminal (kitty or alacritty)
# =============================================================================
stage "STAGE 9 — Terminal: ${TERMINAL}"

install_kitty() {
    if command -v kitty &>/dev/null; then
        skip "kitty already installed"
        return
    fi
    info "Installing kitty..."
    curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n \
        && ok "kitty installed." \
        || { apt_get kitty && ok "kitty from apt."; }

    # Add to PATH if installed to ~/.local
    if [[ -f "$HOME/.local/kitty.app/bin/kitty" ]]; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$HOME/.local/kitty.app/bin/kitty" "$HOME/.local/bin/kitty" 2>/dev/null || true
        ln -sf "$HOME/.local/kitty.app/bin/kitten" "$HOME/.local/bin/kitten" 2>/dev/null || true
    fi
}

case "$TERMINAL" in
    kitty)     install_kitty ;;
    alacritty) apt_get alacritty ;;
    default)   skip "Keeping gnome-terminal" ;;
esac

# Kitty config
if command -v kitty &>/dev/null || [[ -f "$HOME/.local/kitty.app/bin/kitty" ]]; then
    KITTY_DIR="$HOME/.config/kitty"
    mkdir -p "$KITTY_DIR"

    cat > "$KITTY_DIR/kitty.conf" << KEOF
# ── Kitty — ${R_NAME} ────────────────────────────────────────
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        11.5

cursor                  ${TERM_CURSOR}
cursor_text_color       ${R_BG}
cursor_shape            beam
cursor_beam_thickness   1.5

scrollback_lines       5000
window_padding_width   14
background_opacity     0.95
remember_window_size   yes

tab_bar_style           powerline
tab_powerline_style     slanted
active_tab_foreground   ${R_BG}
active_tab_background   ${R_ACCENT}
inactive_tab_foreground ${R_SUB}
inactive_tab_background ${R_BG2}

# ── ${R_NAME} colours ─────────────────────────────────────────
background  ${R_BG}
foreground  ${R_FG}
selection_background ${R_ACCENT}
selection_foreground ${R_BG}

color0   ${R_BG2}
color8   ${R_BG3}
color1   ${R_ROSE}
color9   ${R_ROSE}
color2   ${R_GREEN}
color10  ${R_GREEN}
color3   ${R_YELLOW}
color11  ${R_YELLOW}
color4   ${R_BLUE}
color12  ${R_BLUE}
color5   ${R_LAVENDER}
color13  ${R_ACCENT}
color6   ${R_TEAL}
color14  ${R_TEAL}
color7   ${R_FG}
color15  ${R_FG}

url_color            ${R_ACCENT}
url_style            curly
enable_audio_bell    no
strip_trailing_spaces smart
KEOF

    # Create desktop entry for kitty if installed via curl
    if [[ -f "$HOME/.local/kitty.app/bin/kitty" ]]; then
        mkdir -p "$HOME/.local/share/applications"
        cp "$HOME/.local/kitty.app/share/applications/kitty.desktop" \
            "$HOME/.local/share/applications/" 2>/dev/null || true
        sed -i "s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|g" \
            "$HOME/.local/share/applications/kitty.desktop" 2>/dev/null || true
    fi

    ok "Kitty configured with ${R_NAME} theme."
fi

# =============================================================================
# STAGE 10 — Zsh + Oh-My-Zsh + Starship
# =============================================================================
stage "STAGE 10 — Shell: ${SHELL_STYLE}"

apt_get zsh

if [[ "$SHELL_STYLE" == "oh-my-zsh" || "$SHELL_STYLE" == "both" ]]; then
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing Oh-My-Zsh..."
        RUNZSH=no CHSH=no \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            && ok "Oh-My-Zsh installed." \
            || warn "Oh-My-Zsh install failed."
    else
        skip "Oh-My-Zsh already installed."
    fi

    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    for repo in \
        "zsh-users/zsh-autosuggestions" \
        "zsh-users/zsh-syntax-highlighting" \
        "zsh-users/zsh-history-substring-search"
    do
        name=$(basename "$repo")
        [[ -d "${ZSH_CUSTOM}/plugins/${name}" ]] \
            && skip "$name" \
            || { git clone --depth=1 "https://github.com/${repo}" \
                    "${ZSH_CUSTOM}/plugins/${name}" 2>/dev/null && ok "$name"; }
    done
fi

if [[ "$SHELL_STYLE" == "starship" || "$SHELL_STYLE" == "both" ]]; then
    if command -v starship &>/dev/null; then
        skip "starship already installed"
    else
        info "Installing starship..."
        curl -fsSL https://starship.rs/install.sh | sh -s -- --yes \
            && ok "Starship installed." \
            || warn "Starship install failed."
    fi
fi

# Write .zshrc
info "Writing ~/.zshrc..."
cat > "$HOME/.zshrc" << ZEOF
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
    z
    colored-man-pages
    extract
    sudo
    kali
)

[[ -f \$ZSH/oh-my-zsh.sh ]] && source "\$ZSH/oh-my-zsh.sh"

# Aliases
alias ls='eza --icons --group-directories-first 2>/dev/null || ls --color=auto'
alias ll='eza -lah --icons --git 2>/dev/null || ls -lah --color=auto'
alias lt='eza --tree --icons --level=2 2>/dev/null || tree'
alias cat='bat --paging=never 2>/dev/null || cat'
alias grep='grep --color=auto'
alias ip='ip --color=auto'
alias diff='diff --color=auto'
alias fetch='neofetch'
alias vim='nvim 2>/dev/null || vim'
alias ..='cd ..'
alias ...='cd ../..'
alias update='sudo apt-get update && sudo apt-get upgrade'

# Env
export EDITOR='nvim 2>/dev/null || nano'
export PATH="\$HOME/.local/bin:\$PATH"

# Starship
command -v starship &>/dev/null && eval "\$(starship init zsh)"
ZEOF

# Set zsh as default shell
if [[ "$SHELL" != "$(which zsh)" ]]; then
    chsh -s "$(which zsh)" \
        && ok "Default shell set to zsh." \
        || warn "Could not change shell — run: chsh -s $(which zsh)"
fi

# =============================================================================
# STAGE 11 — Starship config
# =============================================================================
stage "STAGE 11 — Starship prompt (${R_NAME})"

mkdir -p "$HOME/.config"
cat > "$HOME/.config/starship.toml" << SEOF
# ── Starship — ${R_NAME} ──────────────────────────────────────
format = """
[\$os](${R_ACCENT} bold) \
[╭─](${R_BORDER}) \$username\$hostname\$directory\$git_branch\$git_status\$python\$nodejs\$rust
[╰─](${R_BORDER})\$character """

[os]
disabled = false
[os.symbols]
Linux    = " "
Kali     = " "
Debian   = " "
Ubuntu   = " "

[username]
style_user  = "bold fg:${R_ACCENT}"
style_root  = "bold fg:${R_ROSE}"
format      = "[\$user](\$style) "
show_always = false

[hostname]
ssh_only  = true
format    = "at [fg:${R_BLUE}bold]\$hostname[reset] "

[directory]
style             = "bold fg:${R_BLUE}"
format            = "in [ \$path](\$style)[\$read_only](\$read_only_style) "
truncation_length = 3
truncation_symbol = "…/"
read_only         = " 󰌾"

[git_branch]
symbol = " "
style  = "bold fg:${R_LAVENDER}"
format = "on [\$symbol\$branch](\$style) "

[git_status]
format  = "([\$all_status\$ahead_behind]( bold fg:${R_ROSE}) )"
ahead   = "⇡\${count}"
behind  = "⇣\${count}"
modified = "!"
staged  = "+"
untracked = "?"
deleted = "✘"

[python]
symbol = "󰌠 "
style  = "fg:${R_YELLOW}"
format = "[\${symbol}(\${version})](\$style) "

[nodejs]
symbol = " "
style  = "fg:${R_GREEN}"

[rust]
symbol = " "
style  = "fg:${R_ROSE}"

[character]
success_symbol = "[❯](bold fg:${R_GREEN})"
error_symbol   = "[❯](bold fg:${R_ROSE})"
vicmd_symbol   = "[❮](bold fg:${R_ACCENT})"

[cmd_duration]
min_time  = 2000
format    = "took [⏱ \$duration]( fg:${R_YELLOW}) "
SEOF
ok "Starship configured."

# =============================================================================
# STAGE 12 — Neofetch config
# =============================================================================
stage "STAGE 12 — Neofetch"

NEOFETCH_DIR="$HOME/.config/neofetch"
mkdir -p "$NEOFETCH_DIR"

cat > "$NEOFETCH_DIR/config.conf" << NEOF
# ── Neofetch — ${R_NAME} ─────────────────────────────────────
print_info() {
    info title
    info underline
    info "OS"        distro
    info "Host"      model
    info "Kernel"    kernel
    info "Uptime"    uptime
    info "Packages"  packages
    info "Shell"     shell
    info "DE/WM"     de
    info "Theme"     theme
    info "Icons"     icons
    info "Terminal"  term
    info "Font"      term_font
    info "CPU"       cpu
    info "GPU"       gpu
    info "Memory"    memory
    info "Disk"      disk
    prin ""
    info cols
}

distro_shorthand="off"
os_arch="on"
kernel_shorthand="on"
uptime_shorthand="tiny"
memory_percent="on"
memory_unit="gib"
package_managers="on"
shell_path="off"
shell_version="on"
speed_type="bios_limit"
cpu_brand="on"
cpu_cores="logical"
cpu_temp="C"
gpu_brand="on"
gtk_shorthand="on"
gtk2="on"
gtk3="on"
disk_show=('/')
disk_subtitle="mount"
colors=(${R_ROSE:1} ${R_ACCENT:1} ${R_BLUE:1} ${R_GREEN:1} ${R_YELLOW:1} ${R_TEAL:1})
bold="on"
underline_enabled="on"
underline_char="-"
separator=" ➜"
color_blocks="on"
block_width=3
block_height=1
col_offset="auto"
bar_char_elapsed="-"
bar_char_total="="
bar_border="on"
bar_length=15
bar_color_elapsed="distro"
bar_color_total="distro"
cpu_display="off"
memory_display="bar"
battery_display="off"
disk_display="off"
image_backend="ascii"
image_source="auto"
ascii_distro="Kali Linux_small"
ascii_bold="on"
NEOF

ok "Neofetch configured."

# =============================================================================
# STAGE 13 — Wallpaper
# =============================================================================
stage "STAGE 13 — Generating wallpaper (${R_NAME})"

WP="$HOME/.local/share/backgrounds/rice-wallpaper.png"
mkdir -p "$(dirname "$WP")"

python3 - "$WP" "$WP_COLOR1" "$WP_COLOR2" "$WP_ACCENT" << 'WPEOF'
import sys, math, random
try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    print("[rice] Installing Pillow...")
    import subprocess; subprocess.run(["pip3","install","Pillow","--break-system-packages","-q"])
    from PIL import Image, ImageDraw, ImageFilter

path = sys.argv[1]
def h(s): return tuple(int(s[i:i+2],16) for i in (0,2,4))
BG = h(sys.argv[2]); BG2 = h(sys.argv[3]); AC = h(sys.argv[4])
W, H = 2560, 1440
img = Image.new("RGB", (W, H), BG)
draw = ImageDraw.Draw(img)

# Gradient
for y in range(H):
    t = y/H
    c = tuple(int(BG[i]+(BG2[i]-BG[i])*t*0.6) for i in range(3))
    draw.line([(0,y),(W,y)], fill=c)

rng = random.Random(42)

# Noise grain
for _ in range(W*H//10):
    x=rng.randint(0,W-1); y=rng.randint(0,H-1)
    v=rng.randint(-5,5)
    p=img.getpixel((x,y))
    draw.point((x,y), tuple(max(0,min(255,c+v)) for c in p))

# Abstract geometric shapes
ov = Image.new("RGBA", (W,H), (0,0,0,0))
d  = ImageDraw.Draw(ov)

# Large circles
for cx,cy,r,a in [
    (W*0.75, H*0.25, 380, 18),
    (W*0.15, H*0.70, 260, 14),
    (W*0.90, H*0.80, 200, 10),
    (W*0.50, H*0.50, 500, 7),
]:
    d.ellipse([cx-r,cy-r,cx+r,cy+r], outline=AC+(a,), width=1)

# Accent arcs/rings
for i in range(6):
    cx = rng.randint(W//8, W*7//8)
    cy = rng.randint(H//8, H*7//8)
    r  = rng.randint(40, 160)
    d.ellipse([cx-r,cy-r,cx+r,cy+r], outline=AC+(12,), width=1)

# Grid lines (subtle)
for x in range(0, W, 120):
    d.line([(x,0),(x,H)], fill=AC+(5,), width=1)
for y in range(0, H, 120):
    d.line([(0,y),(W,y)], fill=AC+(5,), width=1)

# Dots scatter
for _ in range(120):
    x=rng.randint(0,W-1); y=rng.randint(0,H-1)
    r=rng.randint(1,4)
    d.ellipse([x-r,y-r,x+r,y+r], fill=AC+(rng.randint(15,50),))

img2 = img.convert("RGBA")
img2.alpha_composite(ov)
final = img2.convert("RGB").filter(ImageFilter.GaussianBlur(0.5))
final.save(path)
print(f"[rice] Wallpaper saved → {path}")
WPEOF

if [[ -f "$WP" ]]; then
    # Set via gsettings (GNOME)
    gsettings set org.gnome.desktop.background picture-uri       "file://${WP}" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-uri-dark  "file://${WP}" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-options   "zoom"          2>/dev/null || true
    ok "Wallpaper set."
fi

# =============================================================================
# STAGE 14 — GNOME misc tweaks
# =============================================================================
stage "STAGE 14 — GNOME tweaks"

# Night light
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled    true  2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3700  2>/dev/null || true

# Touchpad
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll  true  2>/dev/null || true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click    true  2>/dev/null || true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true

# Workspace / window
gsettings set org.gnome.desktop.wm.preferences num-workspaces 6                    2>/dev/null || true
gsettings set org.gnome.shell.overrides dynamic-workspaces false                    2>/dev/null || true
gsettings set org.gnome.desktop.interface show-battery-percentage true              2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-show-weekday     true               2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-show-seconds     false              2>/dev/null || true

# Keyboard shortcuts
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal \
    "['<Super>Return']" 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.media-keys www \
    "['<Super>b']" 2>/dev/null || true

ok "GNOME tweaks applied."

# =============================================================================
# STAGE 15 — Blur My Shell extension settings
# =============================================================================
stage "STAGE 15 — Blur My Shell"

gnome-extensions enable blur-my-shell@aunetx 2>/dev/null || true

gsettings set org.gnome.shell.extensions.blur-my-shell.panel blur     false 2>/dev/null || true
gsettings set org.gnome.shell.extensions.blur-my-shell.overview blur  true  2>/dev/null || true
gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder blur true  2>/dev/null || true
gsettings set org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur true 2>/dev/null || true

ok "Blur My Shell configured."

# =============================================================================
# DONE
# =============================================================================
echo
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  🎨  Kali GNOME Rice Complete!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${NC}"
echo
echo -e "  ${BOLD}Theme${NC}     : ${R_NAME}"
echo -e "  ${BOLD}GTK${NC}       : ${RESOLVED_THEME}"
echo -e "  ${BOLD}Icons${NC}     : ${GTK_ICON}"
echo -e "  ${BOLD}Terminal${NC}  : ${TERMINAL}"
echo -e "  ${BOLD}Shell${NC}     : zsh + oh-my-zsh + starship"
echo -e "  ${BOLD}Wallpaper${NC} : ${WP}"
echo
echo -e "  ${YELLOW}Palette:${NC}"
printf "    \033[48;2;%d;%d;%dm   \033[0m  Background   %s\n" \
    $((16#${R_BG:1:2})) $((16#${R_BG:3:2})) $((16#${R_BG:5:2})) "$R_BG"
printf "    \033[48;2;%d;%d;%dm   \033[0m  Accent       %s\n" \
    $((16#${R_ACCENT:1:2})) $((16#${R_ACCENT:3:2})) $((16#${R_ACCENT:5:2})) "$R_ACCENT"
printf "    \033[48;2;%d;%d;%dm   \033[0m  Foreground   %s\n" \
    $((16#${R_FG:1:2})) $((16#${R_FG:3:2})) $((16#${R_FG:5:2})) "$R_FG"
echo
echo -e "  ${YELLOW}Next steps:${NC}"
echo -e "   1. ${BOLD}Log out and back in${NC} to apply all changes"
echo -e "   2. Open ${BOLD}GNOME Extensions${NC} app → enable:"
echo -e "       • User Themes"
echo -e "       • Dash to Dock"
echo -e "       • Blur My Shell"
echo -e "       • AppIndicator"
echo -e "   3. Open ${BOLD}GNOME Tweaks${NC} → Appearance → set Shell theme"
echo -e "      to ${BOLD}${RESOLVED_THEME}${NC}"
echo -e "   4. Run ${BOLD}neofetch${NC} to check system info display"
echo -e "   5. To change theme: edit ${BOLD}RICE=\"...\"${NC} at top and re-run"
echo -e "       Options: catppuccin | rosepine | everforest | lotus | nord | dracula"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${NC}"
