#!/bin/bash
# =============================================================================
# eink-rice.sh  —  E-Ink Hyprland Rice for Debian 13 Trixie
# =============================================================================
#
#  Palette:  warm off-white paper · deep ink black · warm grays
#            single vermillion red accent — nothing else
#
#  Stack:    Hyprland · Waybar · Kitty · Rofi · Mako · Starship
#            Fastfetch · Zsh + OMZ · Zathura · btop · cava
#
#  Safe:     Does NOT touch partitions, bootloader, or KDE/GNOME.
#            Installs alongside any existing DE — pick at SDDM login.
#
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIG — change these if needed
# =============================================================================

USERNAME="${USER:-$(whoami)}"
HOME_DIR="$HOME"
CFG="$HOME_DIR/.config"
KB_LAYOUT="us"
MONITOR=",preferred,auto,1"

# =============================================================================
# COLOURS
# =============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[  ✓  ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
skip()  { echo -e "${CYAN}[ skip ]${NC} $*"; }
die()   { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }
stage() {
    echo -e "\n${BOLD}${CYAN}════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}  $*${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════${NC}"
}

pkg_ok() { dpkg -s "$1" &>/dev/null; }

[[ $EUID -eq 0 ]] && die "Run as your normal user, not root."

# =============================================================================
# E-INK PALETTE
# =============================================================================

EI_PAPER="f5f3ed"
EI_PAPER2="ebe8e0"
EI_PAPER3="e0dcd2"
EI_INK="161412"
EI_INK2="3a3632"
EI_INK3="6e6a62"
EI_GHOST="a09c94"
EI_RED="ac201c"
EI_RED_DIM="c88280"
EI_WHITE="fffefc"

# =============================================================================
# STAGE 1 — APT packages
# =============================================================================
stage "STAGE 1 — APT dependencies"

sudo apt-get update -qq

for pkg in waybar rofi mako-notifier kitty zsh zathura \
           zathura-pdf-poppler btop grim slurp wl-clipboard \
           brightnessctl playerctl network-manager-gnome \
           qt5ct papirus-icon-theme fonts-ebgaramond \
           fonts-noto fonts-noto-extra python3-pillow \
           curl wget git unzip imagemagick; do
    pkg_ok "$pkg" && skip "$pkg" || {
        sudo apt-get install -y "$pkg" 2>/dev/null && ok "$pkg" \
            || warn "$pkg unavailable"
    }
done

# kvantum — package name varies
sudo apt-get install -y qt5-style-kvantum 2>/dev/null \
    || sudo apt-get install -y qt5-style-plugin-kvantum 2>/dev/null \
    || warn "kvantum not available"

# cava — build from source if needed
if ! command -v cava &>/dev/null; then
    info "Building cava..."
    sudo apt-get install -y libfftw3-dev libasound2-dev libpulse-dev \
        libncursesw5-dev libpipewire-0.3-dev cmake 2>/dev/null || true
    tmp="$(mktemp -d)"
    git clone --depth 1 https://github.com/karlstav/cava "$tmp/cava" 2>/dev/null && {
        cd "$tmp/cava"
        cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
        cmake --build build -j"$(nproc)"
        sudo cmake --install build
        ok "cava installed."; cd "$HOME_DIR"
    } || warn "cava build failed"
fi

# Oh My Zsh
if [[ ! -d "$HOME_DIR/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        2>/dev/null && ok "oh-my-zsh installed." || warn "oh-my-zsh failed"
else
    skip "oh-my-zsh already present"
fi

# Starship
if ! command -v starship &>/dev/null; then
    info "Installing Starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y &>/dev/null \
        && ok "starship installed." || warn "starship failed"
else
    skip "starship already installed"
fi

# JetBrainsMono Nerd Font
FONT_DIR="$HOME_DIR/.local/share/fonts"
mkdir -p "$FONT_DIR"
if ls "$FONT_DIR"/JetBrainsMono*.ttf &>/dev/null; then
    skip "JetBrainsMono Nerd Font already present"
else
    info "Downloading JetBrainsMono Nerd Font..."
    tmp_nf="$(mktemp -d)"
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" \
        -o "$tmp_nf/jbm.zip" 2>/dev/null && {
        unzip -q "$tmp_nf/jbm.zip" -d "$tmp_nf/jbm"
        cp "$tmp_nf"/jbm/*.ttf "$FONT_DIR/" 2>/dev/null || true
        fc-cache -f "$FONT_DIR"
        ok "JetBrainsMono Nerd Font installed."
    } || warn "Nerd font download failed"
fi

# =============================================================================
# STAGE 2 — Hyprland config
# =============================================================================
stage "STAGE 2 — Hyprland config"

HYPR="$CFG/hypr"
mkdir -p "$HYPR"
[[ -f "$HYPR/hyprland.conf" ]] && {
    cp "$HYPR/hyprland.conf" "$HYPR/hyprland.conf.bak"
    info "Existing config backed up → hyprland.conf.bak"
}

cat > "$HYPR/hyprland.conf" << HEOF
# =============================================================
# Hyprland  —  E-Ink Rice
# =============================================================

env = GDK_BACKEND,wayland,x11
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_QPA_PLATFORMTHEME,qt5ct
env = SDL_VIDEODRIVER,wayland
env = XDG_SESSION_TYPE,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_DESKTOP,Hyprland

monitor = ${MONITOR}

exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-kde-authentication-agent-1 2>/dev/null || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 2>/dev/null || true
exec-once = waybar
exec-once = mako
exec-once = hyprpaper
exec-once = hypridle 2>/dev/null || true
exec-once = nm-applet --indicator &

input {
    kb_layout    = ${KB_LAYOUT}
    follow_mouse = 1
    sensitivity  = 0
    touchpad {
        natural_scroll       = yes
        tap-to-click         = yes
        disable_while_typing = yes
    }
}

general {
    gaps_in     = 4
    gaps_out    = 10
    border_size = 1
    col.active_border   = 0xff${EI_INK}
    col.inactive_border = 0xff${EI_PAPER3}
    layout = dwindle
}

decoration {
    rounding        = 4
    active_opacity  = 1.0
    inactive_opacity = 0.98
    blur { enabled = false }
    drop_shadow   = true
    shadow_range  = 12
    shadow_offset = 3 4
    col.shadow          = rgba(00000025)
    col.shadow_inactive = rgba(00000012)
}

animations {
    enabled = yes
    bezier = ink, 0.16, 1, 0.3, 1
    animation = windows,    1, 4, ink, slide
    animation = windowsOut, 1, 3, ink, slide
    animation = border,     1, 2, default
    animation = fade,       1, 4, default
    animation = workspaces, 1, 3, ink
}

dwindle {
    pseudotile     = yes
    preserve_split = yes
    force_split    = 2
}

misc {
    force_default_wallpaper  = 0
    disable_hyprland_logo    = true
    disable_splash_rendering = true
    vfr = true
}

windowrulev2 = float,    class:^(pavucontrol)$
windowrulev2 = float,    class:^(nm-connection-editor)$
windowrulev2 = float,    class:^(blueman-manager)$
windowrulev2 = noshadow, class:^(waybar)$
windowrulev2 = noanim,   class:^(rofi)$
windowrulev2 = opacity 0.97 0.95, class:^(kitty)$

\$mod = SUPER

bind = \$mod,       Return,    exec, kitty
bind = \$mod SHIFT, Return,    exec, kitty --class=float_kitty
bind = \$mod,       Q,         killactive
bind = \$mod,       F,         fullscreen, 0
bind = \$mod SHIFT, F,         togglefloating
bind = \$mod,       Space,     exec, rofi -show drun
bind = \$mod SHIFT, Space,     exec, rofi -show run
bind = \$mod,       Tab,       exec, rofi -show window
bind = \$mod,       E,         exec, dolphin 2>/dev/null || nautilus 2>/dev/null || thunar
bind = \$mod SHIFT, Q,         exit
bind = \$mod,       L,         exec, hyprlock 2>/dev/null || swaylock -c f5f3ed
bind = \$mod,       B,         exec, firefox 2>/dev/null || chromium
bind = \$mod,       Z,         exec, zathura
bind = \$mod,       R,         exec, kitty -e btop
bind = \$mod SHIFT, S,         exec, grim -g "\$(slurp)" ~/Pictures/shot-\$(date +%Y%m%d-%H%M%S).png
bind = ,            Print,     exec, grim ~/Pictures/shot-\$(date +%Y%m%d-%H%M%S).png

bind = , XF86AudioRaiseVolume,  exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
bind = , XF86AudioLowerVolume,  exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
bind = , XF86AudioMute,         exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
bind = , XF86MonBrightnessUp,   exec, brightnessctl set +5%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
bind = , XF86AudioPlay,         exec, playerctl play-pause
bind = , XF86AudioNext,         exec, playerctl next
bind = , XF86AudioPrev,         exec, playerctl previous

bind = \$mod, h, movefocus, l
bind = \$mod, l, movefocus, r
bind = \$mod, k, movefocus, u
bind = \$mod, j, movefocus, d
bind = \$mod, left,  movefocus, l
bind = \$mod, right, movefocus, r
bind = \$mod, up,    movefocus, u
bind = \$mod, down,  movefocus, d

bind = \$mod SHIFT, h, movewindow, l
bind = \$mod SHIFT, l, movewindow, r
bind = \$mod SHIFT, k, movewindow, u
bind = \$mod SHIFT, j, movewindow, d

binde = \$mod CTRL, right, resizeactive,  30  0
binde = \$mod CTRL, left,  resizeactive, -30  0
binde = \$mod CTRL, up,    resizeactive,   0 -30
binde = \$mod CTRL, down,  resizeactive,   0  30

bind = \$mod, 1, workspace, 1
bind = \$mod, 2, workspace, 2
bind = \$mod, 3, workspace, 3
bind = \$mod, 4, workspace, 4
bind = \$mod, 5, workspace, 5
bind = \$mod, 6, workspace, 6
bind = \$mod, 7, workspace, 7
bind = \$mod, 8, workspace, 8
bind = \$mod, 9, workspace, 9
bind = \$mod, 0, workspace, 10
bind = \$mod SHIFT, 1, movetoworkspace, 1
bind = \$mod SHIFT, 2, movetoworkspace, 2
bind = \$mod SHIFT, 3, movetoworkspace, 3
bind = \$mod SHIFT, 4, movetoworkspace, 4
bind = \$mod SHIFT, 5, movetoworkspace, 5
bind = \$mod SHIFT, 6, movetoworkspace, 6
bind = \$mod SHIFT, 7, movetoworkspace, 7
bind = \$mod SHIFT, 8, movetoworkspace, 8
bind = \$mod SHIFT, 9, movetoworkspace, 9
bind = \$mod SHIFT, 0, movetoworkspace, 10

bind  = \$mod, grave, workspace, previous
bindm = \$mod, mouse:272, movewindow
bindm = \$mod, mouse:273, resizewindow
HEOF
ok "hyprland.conf written."

cat > "$HYPR/hyprlock.conf" << HLEOF
background {
    monitor =
    color = rgb(f5f3ed)
    blur_passes = 0
}
input-field {
    monitor =
    size = 280, 44
    outline_thickness = 1
    outer_color = rgb(161412)
    inner_color = rgb(ebe8e0)
    font_color  = rgb(161412)
    fade_on_empty = false
    placeholder_text = <span foreground="##6e6a62">password</span>
    position = 0, -100
    halign = center
    valign = center
}
label {
    monitor =
    text = cmd[update:1000] echo "\$(date +'%H:%M')"
    font_size = 72
    font_family = JetBrainsMono Nerd Font
    color = rgba(161412ff)
    position = 0, 120
    halign = center
    valign = center
}
label {
    monitor =
    text = cmd[update:60000] echo "\$(date +'%A, %d %B %Y')"
    font_size = 14
    font_family = EB Garamond
    color = rgba(6e6a62ff)
    position = 0, 50
    halign = center
    valign = center
}
HLEOF
ok "hyprlock.conf written."

cat > "$HYPR/hypridle.conf" << 'HIEOF'
general {
    lock_cmd = hyprlock
    before_sleep_cmd = hyprlock
    after_sleep_cmd  = hyprctl dispatch dpms on
}
listener {
    timeout = 300
    on-timeout = hyprlock
}
listener {
    timeout = 600
    on-timeout = hyprctl dispatch dpms off
    on-resume   = hyprctl dispatch dpms on
}
HIEOF
ok "hypridle.conf written."

# =============================================================================
# STAGE 3 — Wallpaper
# =============================================================================
stage "STAGE 3 — Wallpaper"

python3 << 'PYEOF'
from PIL import Image, ImageDraw, ImageFilter
import random

W, H = 1920, 1080
img = Image.new("RGB", (W, H), (245, 243, 237))
d   = ImageDraw.Draw(img)

# Paper gradient
for y in range(H):
    t = y / H
    c = (int(245 - t*14), int(243 - t*16), int(237 - t*18))
    d.line([(0,y),(W,y)], fill=c)

# Fine grain
rng = random.Random(1984)
for _ in range(W*H//5):
    x = rng.randint(0,W-1); y = rng.randint(0,H-1)
    v = rng.randint(-6,6)
    base = img.getpixel((x,y))
    c = tuple(max(0,min(255, base[i]+v)) for i in range(3))
    img.putpixel((x,y), c)

# Grid lines — very faint graph paper
for y in range(60, H, 60):
    d.line([(0,y),(W,y)], fill=(228,224,214), width=1)
for x in range(60, W, 60):
    d.line([(x,0),(x,H)], fill=(228,224,214), width=1)
# Heavier every 300
for y in range(0, H, 300):
    d.line([(0,y),(W,y)], fill=(215,210,200), width=1)

# Halftone fade — bottom-left
for row in range(0, H//2, 16):
    for col in range(0, W//3, 16):
        t = (row/(H//2)) * (col/(W//3))
        r2 = max(0, int(2.5*t))
        if r2 > 0:
            cx2 = col+8; cy2 = H//2+row+8
            shade = int(245 - t*30)
            d.ellipse([cx2-r2,cy2-r2,cx2+r2,cy2+r2], fill=(shade,shade-2,shade-6))

img = img.filter(ImageFilter.GaussianBlur(0.4))
import os
img.save(os.path.expanduser("~/.config/wallpaper.png"), quality=97)
print("Wallpaper saved.")
PYEOF
ok "Wallpaper generated."

cat > "$HYPR/hyprpaper.conf" << 'WPEOF'
preload   = ~/.config/wallpaper.png
wallpaper = ,~/.config/wallpaper.png
ipc = off
WPEOF
ok "hyprpaper.conf written."

# =============================================================================
# STAGE 4 — Waybar
# =============================================================================
stage "STAGE 4 — Waybar"

mkdir -p "$CFG/waybar"

cat > "$CFG/waybar/config" << 'WBEOF'
{
    "layer": "top",
    "position": "top",
    "height": 36,
    "spacing": 0,
    "modules-left":   ["custom/logo", "hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right":  ["pulseaudio", "memory", "cpu", "network", "battery", "custom/power"],

    "custom/logo": {
        "format": " H ",
        "tooltip": false
    },
    "hyprland/workspaces": {
        "format": "{id}",
        "on-click": "activate",
        "sort-by-number": true
    },
    "hyprland/window": {
        "format": "  {}",
        "max-length": 40
    },
    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%A, %d %B %Y   %H:%M}",
        "tooltip-format": "<tt>{calendar}</tt>"
    },
    "pulseaudio": {
        "format": " {volume}%",
        "format-muted": " mute",
        "on-click": "pactl set-sink-mute @DEFAULT_SINK@ toggle",
        "on-click-right": "pavucontrol",
        "tooltip": false
    },
    "memory": {
        "format": " {used:0.1f}G",
        "tooltip-format": "{used:0.1f} / {total:0.1f} GiB"
    },
    "cpu": {
        "format": " {usage}%",
        "tooltip": false,
        "interval": 2
    },
    "network": {
        "format-wifi":        " {essid}",
        "format-ethernet":    " eth",
        "format-disconnected":" off",
        "on-click": "nm-connection-editor",
        "tooltip-format": "{ifname}: {ipaddr}"
    },
    "battery": {
        "format": "{icon} {capacity}%",
        "format-charging": " {capacity}%",
        "format-icons": [" ", " ", " ", " ", " "],
        "states": { "warning": 30, "critical": 15 },
        "tooltip": false
    },
    "custom/power": {
        "format": "",
        "on-click": "rofi -show power-menu -modi 'power-menu:~/.config/rofi/power.sh'",
        "tooltip": false
    }
}
WBEOF

cat > "$CFG/waybar/style.css" << CSSEOF
* {
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 11px;
    border: none;
    border-radius: 0;
    padding: 0;
    margin: 0;
    min-height: 0;
}

window#waybar {
    background-color: #${EI_PAPER2};
    color: #${EI_INK};
    border-bottom: 1px solid #${EI_PAPER3};
}

#custom-logo {
    background-color: #${EI_INK};
    color: #${EI_WHITE};
    padding: 0 10px;
    font-weight: bold;
    margin: 5px 6px 5px 4px;
    border-radius: 2px;
    min-width: 24px;
}

#workspaces { margin: 0 4px; }

#workspaces button {
    padding: 2px 8px;
    color: #${EI_INK3};
    background: transparent;
    border-radius: 2px;
    margin: 6px 2px;
}

#workspaces button.active {
    color: #${EI_WHITE};
    background-color: #${EI_INK};
}

#workspaces button.occupied {
    color: #${EI_INK2};
    border-bottom: 1px solid #${EI_INK3};
}

#workspaces button:hover {
    background-color: #${EI_PAPER3};
    color: #${EI_INK};
}

#window {
    color: #${EI_INK3};
    padding: 0 8px;
    font-size: 10px;
}

#clock {
    color: #${EI_INK};
    font-weight: bold;
    font-size: 12px;
    letter-spacing: 0.03em;
}

#pulseaudio, #memory, #cpu, #network, #battery {
    color: #${EI_INK2};
    padding: 0 9px;
    border-left: 1px solid #${EI_PAPER3};
}

#pulseaudio.muted { color: #${EI_GHOST}; }
#battery.warning  { color: #${EI_RED}; }

#battery.critical {
    color: #${EI_WHITE};
    background-color: #${EI_RED};
    padding: 0 9px;
    animation: blink 1s linear infinite;
}

@keyframes blink { to { background-color: #${EI_INK}; } }

#custom-power {
    color: #${EI_INK3};
    padding: 0 12px 0 9px;
    border-left: 1px solid #${EI_PAPER3};
}

#custom-power:hover { color: #${EI_RED}; }

tooltip {
    background-color: #${EI_PAPER};
    color: #${EI_INK};
    border: 1px solid #${EI_PAPER3};
    border-radius: 2px;
}
CSSEOF
ok "Waybar written."

# =============================================================================
# STAGE 5 — Kitty
# =============================================================================
stage "STAGE 5 — Kitty"

mkdir -p "$CFG/kitty"
cat > "$CFG/kitty/kitty.conf" << KEOF
font_family       JetBrainsMono Nerd Font
bold_font         JetBrainsMono Nerd Font Bold
italic_font       JetBrainsMono Nerd Font Italic
font_size         11.5

cursor                  #${EI_RED}
cursor_shape            beam
cursor_beam_thickness   1.5
cursor_blink_interval   0.6

scrollback_lines        10000
window_padding_width    14 18
hide_window_decorations yes
background_opacity      0.97

url_color    #${EI_RED}
url_style    straight

tab_bar_style           separator
tab_separator           " │ "
active_tab_foreground   #${EI_INK}
active_tab_background   #${EI_PAPER}
active_tab_font_style   bold
inactive_tab_foreground #${EI_INK3}
inactive_tab_background #${EI_PAPER2}

background  #${EI_PAPER}
foreground  #${EI_INK}
selection_background #${EI_INK}
selection_foreground #${EI_PAPER}

color0  #${EI_PAPER2}
color8  #${EI_PAPER3}
color1  #${EI_RED}
color9  #${EI_RED_DIM}
color2  #4a5a40
color10 #6a7a5a
color3  #7a6840
color11 #9a8858
color4  #384858
color12 #506070
color5  #6a5868
color13 #8a7888
color6  #3a6060
color14 #507878
color7  #${EI_INK2}
color15 #${EI_INK}

map ctrl+shift+c  copy_to_clipboard
map ctrl+shift+v  paste_from_clipboard
map ctrl+shift+t  new_tab_with_cwd
map ctrl+shift+w  close_tab
map ctrl+equal    change_font_size all +1.0
map ctrl+minus    change_font_size all -1.0
map ctrl+0        change_font_size all 0
KEOF
ok "Kitty config written."

# =============================================================================
# STAGE 6 — Rofi
# =============================================================================
stage "STAGE 6 — Rofi"

mkdir -p "$CFG/rofi"

cat > "$CFG/rofi/config.rasi" << 'REOF'
configuration {
    modi: "drun,run,window";
    show-icons: false;
    display-drun: "apps";
    drun-display-format: "{name}";
    hover-select: true;
}
@theme "eink"
REOF

cat > "$CFG/rofi/eink.rasi" << RTHEOF
* {
    paper:  #f5f3ed;
    paper2: #ebe8e0;
    paper3: #e0dcd2;
    ink:    #161412;
    ink2:   #3a3632;
    ink3:   #6e6a62;
    ghost:  #a09c94;
    red:    #ac201c;
    white:  #fffefc;

    font:                "JetBrainsMono Nerd Font 11";
    background-color:    @paper;
    text-color:          @ink;
    border-color:        @ink;
    selected-normal-foreground: @white;
    selected-normal-background: @ink;
    normal-foreground:   @ink2;
    normal-background:   @paper;
    alternate-normal-background: @paper2;
    alternate-normal-foreground: @ink2;
    spacing: 0;
}

window {
    width: 380px;
    background-color: @paper;
    border: 1px solid;
    border-color: @ink;
    border-radius: 4px;
}

mainbox { padding: 0; children: [inputbar, listview]; }

inputbar {
    padding: 10px 14px;
    border-bottom: 1px solid;
    border-color: @paper3;
    children: [entry];
}

entry {
    padding: 4px 0;
    placeholder: "search…";
    placeholder-color: @ghost;
}

listview {
    padding: 6px 0;
    lines: 9;
    scrollbar: false;
}

element { padding: 7px 14px; }
element-text { vertical-align: 0.5; }

element.normal.normal    { background-color: @paper;  text-color: @ink2; }
element.alternate.normal { background-color: @paper2; text-color: @ink2; }
element.selected.normal  { background-color: @ink;    text-color: @white; }
element.normal.active    { background-color: @paper;  text-color: @red; }
element.selected.active  { background-color: @red;    text-color: @white; }
RTHEOF

cat > "$CFG/rofi/power.sh" << 'PSH'
#!/bin/bash
chosen=$(printf "  lock\n  logout\n  suspend\n  reboot\n  shutdown" | rofi -dmenu -p "power")
case "$chosen" in
    *lock)     hyprlock ;;
    *logout)   hyprctl dispatch exit ;;
    *suspend)  systemctl suspend ;;
    *reboot)   systemctl reboot ;;
    *shutdown) systemctl poweroff ;;
esac
PSH
chmod +x "$CFG/rofi/power.sh"
ok "Rofi written."

# =============================================================================
# STAGE 7 — Mako
# =============================================================================
stage "STAGE 7 — Mako"

mkdir -p "$CFG/mako"
cat > "$CFG/mako/config" << MEOF
font=JetBrainsMono Nerd Font 10
background-color=#${EI_PAPER}
text-color=#${EI_INK}
border-color=#${EI_INK}
border-radius=4
border-size=1
width=300
height=80
padding=12
margin=10
default-timeout=5000

[urgency=low]
border-color=#${EI_PAPER3}
text-color=#${EI_INK3}

[urgency=high]
background-color=#${EI_RED}
text-color=#${EI_WHITE}
border-color=#${EI_RED}
MEOF
ok "Mako written."

# =============================================================================
# STAGE 8 — Cava
# =============================================================================
stage "STAGE 8 — Cava"

mkdir -p "$CFG/cava"
cat > "$CFG/cava/config" << CEOF
[general]
framerate   = 60
bars        = 20
bar_width   = 2
bar_spacing = 1

[input]
method = pipewire

[color]
background = '#${EI_PAPER}'
foreground = '#${EI_INK}'

[smoothing]
noise_reduction = 77
CEOF
ok "Cava written."

# =============================================================================
# STAGE 9 — Btop
# =============================================================================
stage "STAGE 9 — Btop"

mkdir -p "$CFG/btop/themes"
cat > "$CFG/btop/themes/eink.theme" << BEOF
theme[main_bg]="#${EI_PAPER}"
theme[main_fg]="#${EI_INK}"
theme[title]="#${EI_INK}"
theme[hi_fg]="#${EI_RED}"
theme[selected_bg]="#${EI_INK}"
theme[selected_fg]="#${EI_WHITE}"
theme[inactive_fg]="#${EI_GHOST}"
theme[meter_bg]="#${EI_PAPER3}"
theme[proc_misc]="#${EI_INK3}"
theme[cpu_box]="#${EI_PAPER3}"
theme[mem_box]="#${EI_PAPER3}"
theme[net_box]="#${EI_PAPER3}"
theme[proc_box]="#${EI_PAPER3}"
theme[div_line]="#${EI_PAPER3}"
theme[temp_start]="#${EI_INK3}"
theme[temp_mid]="#${EI_INK2}"
theme[temp_end]="#${EI_RED}"
theme[cpu_start]="#${EI_INK3}"
theme[cpu_mid]="#${EI_INK2}"
theme[cpu_end]="#${EI_INK}"
theme[used_start]="#${EI_INK2}"
theme[used_mid]="#${EI_INK}"
theme[used_end]="#${EI_RED}"
theme[download_start]="#${EI_INK3}"
theme[download_end]="#${EI_INK}"
theme[upload_start]="#${EI_GHOST}"
theme[upload_end]="#${EI_INK3}"
BEOF
ok "Btop theme written."

# =============================================================================
# STAGE 10 — Starship
# =============================================================================
stage "STAGE 10 — Starship"

cat > "$CFG/starship.toml" << SEOF
add_newline     = false
command_timeout = 1000

format = """\$username\$hostname\$directory\$git_branch\$git_status\$cmd_duration
\$character"""

[character]
success_symbol = "[❯](bold #${EI_RED})"
error_symbol   = "[❯](bold #${EI_RED})"
vimcmd_symbol  = "[❮](bold #${EI_INK})"

[username]
show_always = false
format      = "[\$user](\$style)"
style_user  = "bold #${EI_INK}"

[hostname]
ssh_only = true
format   = "[@\$hostname](\$style) "
style    = "#${EI_INK3}"

[directory]
format            = "[ \$path](\$style) "
style             = "#${EI_INK2}"
truncate_to_repo  = true
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
format = "[\$branch](\$style) "
style  = "#${EI_INK3}"
symbol = " "

[git_status]
format    = "([\$all_status\$ahead_behind](\$style)) "
style     = "#${EI_RED}"
ahead     = "↑\${count}"
behind    = "↓\${count}"
modified  = "·\${count}"
untracked = "?\${count}"
staged    = "+\${count}"

[cmd_duration]
min_time = 2000
format   = "[\$duration](\$style) "
style    = "#${EI_GHOST}"

[python]
format = "[\$symbol\$version](\$style) "
style  = "#${EI_INK3}"

[nodejs]
format = "[\$symbol\$version](\$style) "
style  = "#${EI_INK3}"

[rust]
format = "[\$symbol\$version](\$style) "
style  = "#${EI_INK3}"
SEOF
ok "Starship written."

# =============================================================================
# STAGE 11 — Zsh
# =============================================================================
stage "STAGE 11 — Zsh"

[[ "$SHELL" != "$(which zsh)" ]] && {
    chsh -s "$(which zsh)" "$USERNAME" 2>/dev/null \
        && ok "zsh set as default shell." \
        || warn "Run: chsh -s \$(which zsh)"
}

ZSHRC="$HOME_DIR/.zshrc"
[[ -f "$ZSHRC" ]] && cp "$ZSHRC" "$ZSHRC.bak"

cat > "$ZSHRC" << 'ZEOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(git zsh-autosuggestions zsh-syntax-highlighting z sudo colored-man-pages extract)

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions" &>/dev/null &
[[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] || \
    git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" &>/dev/null &

source "$ZSH/oh-my-zsh.sh" 2>/dev/null || true

export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM=wayland
export MOZ_ENABLE_WAYLAND=1

alias ls='eza --icons --group-directories-first 2>/dev/null || ls --color=auto'
alias ll='eza -lh --icons --git 2>/dev/null || ls -lh --color=auto'
alias la='eza -lha --icons --git 2>/dev/null || ls -lha --color=auto'
alias lt='eza --tree --level=2 2>/dev/null || tree -L 2'
alias cat='bat --theme=ansi 2>/dev/null || cat'
alias grep='grep --color=auto'
alias cp='cp -iv'; alias mv='mv -iv'; alias rm='rm -iv'
alias ..='cd ..'; alias ...='cd ../..'; alias ....='cd ../../..'
alias v='nvim'
alias r='ranger 2>/dev/null || lf 2>/dev/null'
alias clip='wl-copy'
alias scr='grim ~/Pictures/shot-$(date +%Y%m%d-%H%M%S).png'
alias scrsel='grim -g "$(slurp)" ~/Pictures/shot-$(date +%Y%m%d-%H%M%S).png'
alias reload='source ~/.zshrc'

mkcd() { mkdir -p "$1" && cd "$1"; }
bak()  { cp "$1" "$1.bak"; }

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#a09c94"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

HISTSIZE=50000; SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

eval "$(starship init zsh)" 2>/dev/null || true
ZEOF
ok ".zshrc written."

# =============================================================================
# STAGE 12 — Fastfetch
# =============================================================================
stage "STAGE 12 — Fastfetch"

if ! command -v fastfetch &>/dev/null; then
    sudo apt-get install -y fastfetch 2>/dev/null || {
        tmp_ff="$(mktemp -d)"
        curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/download/2.21.3/fastfetch-linux-amd64.deb" \
            -o "$tmp_ff/ff.deb" 2>/dev/null && sudo dpkg -i "$tmp_ff/ff.deb" 2>/dev/null \
            && ok "fastfetch installed." || warn "fastfetch install failed"
    }
fi

mkdir -p "$CFG/fastfetch"
cat > "$CFG/fastfetch/config.jsonc" << 'FFEOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": { "type": "builtin", "source": "linux_small", "padding": { "top": 1, "left": 2 } },
    "display": { "separator": "  ", "keyWidth": 10 },
    "modules": [
        { "type": "title",   "format": "{user}@{host}" },
        "separator",
        { "type": "os",      "key": " OS"      },
        { "type": "kernel",  "key": " Kernel"  },
        { "type": "wm",      "key": " WM"      },
        { "type": "shell",   "key": " Shell"   },
        { "type": "terminal","key": " Term"    },
        { "type": "font",    "key": " Font"    },
        "separator",
        { "type": "cpu",     "key": " CPU"     },
        { "type": "gpu",     "key": " GPU"     },
        { "type": "memory",  "key": " RAM"     },
        { "type": "disk",    "key": " Disk"    },
        { "type": "uptime",  "key": " Up"      },
        "separator",
        { "type": "colors",  "paddingLeft": 0, "symbol": "circle" }
    ]
}
FFEOF
ok "Fastfetch written."

# =============================================================================
# STAGE 13 — Zathura
# =============================================================================
stage "STAGE 13 — Zathura"

mkdir -p "$CFG/zathura"
cat > "$CFG/zathura/zathurarc" << ZREOF
set font              "EB Garamond 13"
set default-bg        "#${EI_PAPER}"
set default-fg        "#${EI_INK}"
set statusbar-bg      "#${EI_PAPER2}"
set statusbar-fg      "#${EI_INK3}"
set inputbar-bg       "#${EI_PAPER2}"
set inputbar-fg       "#${EI_INK}"
set highlight-color   "#${EI_RED}55"
set highlight-active-color "#${EI_RED}99"
set completion-bg     "#${EI_PAPER2}"
set completion-fg     "#${EI_INK}"
set index-active-bg   "#${EI_INK}"
set index-active-fg   "#${EI_WHITE}"
set recolor           true
set recolor-lightcolor "#${EI_PAPER}"
set recolor-darkcolor  "#${EI_INK}"
set recolor-keephue   false
set scroll-step       80
set pages-per-row     1
set adjust-open       best-fit
set window-title-basename true
map u scroll half-up
map d scroll half-down
map r reload
map R rotate
map i recolor
ZREOF
ok "Zathura written."

# =============================================================================
# STAGE 14 — GTK + Qt
# =============================================================================
stage "STAGE 14 — GTK & Qt"

mkdir -p "$HOME_DIR/.config/gtk-3.0" "$HOME_DIR/.config/gtk-4.0"

for d in gtk-3.0 gtk-4.0; do
    cat > "$HOME_DIR/.config/$d/settings.ini" << 'GEOF'
[Settings]
gtk-theme-name        = Adwaita
gtk-icon-theme-name   = Papirus-Light
gtk-font-name         = EB Garamond 11
gtk-cursor-theme-name = Adwaita
gtk-cursor-theme-size = 24
gtk-application-prefer-dark-theme = 0
gtk-xft-antialias = 1
gtk-xft-hinting   = 1
gtk-xft-hintstyle = hintslight
GEOF
done

cat > "$HOME_DIR/.config/gtk-3.0/gtk.css" << GCSS
scrollbar { min-width: 6px; min-height: 6px; border-radius: 0; }
scrollbar slider { min-width: 6px; min-height: 6px; background-color: #${EI_INK3}; }
GCSS

mkdir -p "$CFG/qt5ct"
cat > "$CFG/qt5ct/qt5ct.conf" << 'QTEOF'
[Appearance]
icon_theme=Papirus-Light
style=Fusion
QTEOF
ok "GTK/Qt written."

# =============================================================================
# STAGE 15 — SDDM session + environment
# =============================================================================
stage "STAGE 15 — SDDM & environment"

[[ ! -f /usr/share/wayland-sessions/hyprland.desktop ]] && {
    sudo mkdir -p /usr/share/wayland-sessions
    sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null << 'SEOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
SEOF
    ok "SDDM session entry created."
} || skip "SDDM session entry already present."

mkdir -p "$HOME_DIR/Pictures/Screenshots" "$HOME_DIR/Documents" \
         "$HOME_DIR/Projects" "$HOME_DIR/.local/bin" \
         "$HOME_DIR/.config/environment.d"

cat > "$HOME_DIR/.config/environment.d/wayland.conf" << 'EOF'
MOZ_ENABLE_WAYLAND=1
QT_QPA_PLATFORM=wayland
GDK_BACKEND=wayland
SDL_VIDEODRIVER=wayland
EOF
ok "Environment vars written."

# =============================================================================
# DONE
# =============================================================================
echo
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  E-Ink Rice installed!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${NC}"
echo
echo -e "  Paper: #f5f3ed  Ink: #161412  Red: #ac201c"
echo
echo -e "  ${YELLOW}Config files written:${NC}"
for f in \
    "~/.config/hypr/hyprland.conf" \
    "~/.config/hypr/hyprlock.conf" \
    "~/.config/hypr/hypridle.conf" \
    "~/.config/hypr/hyprpaper.conf" \
    "~/.config/wallpaper.png" \
    "~/.config/waybar/config + style.css" \
    "~/.config/kitty/kitty.conf" \
    "~/.config/rofi/eink.rasi" \
    "~/.config/mako/config" \
    "~/.config/cava/config" \
    "~/.config/btop/themes/eink.theme" \
    "~/.config/starship.toml" \
    "~/.zshrc" \
    "~/.config/fastfetch/config.jsonc" \
    "~/.config/zathura/zathurarc" \
    "~/.config/gtk-{3,4}.0/"
do
    echo -e "    ${GREEN}✓${NC}  $f"
done
echo
echo -e "  ${YELLOW}To activate:${NC}"
echo -e "    1. Log out  (or reboot)"
echo -e "    2. SDDM login → click ${BOLD}session icon${NC} (bottom-left)"
echo -e "    3. Select ${BOLD}Hyprland${NC}  —  KDE/GNOME stays intact"
echo
echo -e "  ${YELLOW}Bindings:${NC}"
echo -e "    Super + Return      kitty terminal"
echo -e "    Super + Space       rofi launcher"
echo -e "    Super + Shift+S     screenshot (region)"
echo -e "    Super + L           lock screen"
echo -e "    Super + Q           close window"
echo -e "    Super + Shift+Q     exit → SDDM"
echo -e "    Super + 1–9         workspaces"
echo -e "    Super + h/j/k/l     vim-style focus"
echo -e "    Super + Z           zathura"
echo -e "    Super + R           btop"
echo
echo -e "  ${YELLOW}Note:${NC} Hyprland must be installed first."
echo -e "  If not installed yet, run ${BOLD}./install-hyprland.sh${NC} first."
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${NC}"
