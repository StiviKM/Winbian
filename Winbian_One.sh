#!/bin/bash
# =============================================================================
# Winbian_One.sh - Debian 13 Windows Lookalike Setup - Stage 1
# =============================================================================

set -e

# === Logging Setup ===
LOG_FILE="$HOME/winbian.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_section() { echo; echo "========================================"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] >>> $1"; echo "========================================"; }

# === Color Output ===
color_echo() {
  case "$1" in
    red)    echo -e "\e[31m$2\e[0m" ;;
    green)  echo -e "\e[32m$2\e[0m" ;;
    yellow) echo -e "\e[33m$2\e[0m" ;;
    blue)   echo -e "\e[34m$2\e[0m" ;;
    *)      echo "$2" ;;
  esac
}

# === Root Check ===
if [ "$EUID" -eq 0 ]; then
  color_echo "red" "❌ Please run this script as a normal user, not with sudo."
  exit 1
fi

# === Detect Actual User ===
ACTUAL_USER=$(logname 2>/dev/null || echo "$USER")
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

# === Detect repo directory regardless of case (Winbian or winbian) ===
if [ -d "$ACTUAL_HOME/Winbian" ]; then
  WINBIAN_DIR="$ACTUAL_HOME/Winbian"
elif [ -d "$ACTUAL_HOME/winbian" ]; then
  WINBIAN_DIR="$ACTUAL_HOME/winbian"
else
  WINBIAN_DIR="$ACTUAL_HOME/Winbian"
fi

# === Request sudo once and keep it alive for the entire script ===
color_echo "yellow" "🔑 Please enter your password once to authorize the installation:"
sudo -v
while true; do sudo -n true; sleep 60; done &
SUDO_KEEPALIVE_PID=$!
trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT

log "Script started by user: $ACTUAL_USER (home: $ACTUAL_HOME)"
color_echo "blue" "🚀 Starting Winbian Stage 1..."

# =============================================================================
# SECTION 1: System Update & APT Configuration
# =============================================================================
log_section "System Update & APT Configuration"

color_echo "yellow" "Enabling non-free and contrib repositories..."
sudo sed -i 's/^deb \(.*\) bookworm \(.*\)/deb \1 bookworm \2 contrib non-free non-free-firmware/' /etc/apt/sources.list
echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/backports.list > /dev/null
log "non-free, contrib, and backports repos enabled"

color_echo "yellow" "Running system update and upgrade..."
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y
log "System update complete"

color_echo "yellow" "Enabling automatic updates..."
sudo apt install -y unattended-upgrades apt-listchanges
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | sudo debconf-set-selections
sudo dpkg-reconfigure -f noninteractive unattended-upgrades
log "Unattended upgrades enabled"

color_echo "green" "✅ System update and APT configuration complete."

# =============================================================================
# SECTION 2: Flatpak Setup
# =============================================================================
log_section "Flatpak Setup"

color_echo "yellow" "Installing Flatpak and setting up Flathub..."
sudo apt install -y flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak repair
flatpak update -y
log "Flathub configured"

color_echo "green" "✅ Flatpak setup complete."

# =============================================================================
# SECTION 3: Multimedia Codecs & Hardware Acceleration
# =============================================================================
log_section "Multimedia Codecs & Hardware Acceleration"

color_echo "yellow" "Installing multimedia codecs..."
sudo apt install -y \
  ffmpeg \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-libav \
  gstreamer1.0-tools \
  gstreamer1.0-alsa \
  gstreamer1.0-pulseaudio
log "Multimedia codecs installed"

color_echo "yellow" "Installing hardware accelerated video codecs..."
sudo apt install -y \
  intel-media-va-driver \
  i965-va-driver \
  mesa-va-drivers \
  va-driver-all \
  vdpau-driver-all || log "WARNING: Some hardware codec packages not available on this hardware"
log "Hardware codec setup attempted"

color_echo "green" "✅ Multimedia codecs complete."

# =============================================================================
# SECTION 4: SSH & Remote Services
# =============================================================================
log_section "SSH Setup"

color_echo "yellow" "Installing and enabling SSH server..."
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
log "SSH server installed and enabled"

color_echo "green" "✅ SSH setup complete."

# =============================================================================
# SECTION 5: Firmware Updates
# =============================================================================
log_section "Firmware Updates"

color_echo "yellow" "Checking for firmware updates..."
sudo apt install -y fwupd
sudo fwupdmgr refresh --force || log "WARNING: fwupdmgr refresh failed"
sudo fwupdmgr get-updates --assume-yes || log "INFO: No firmware updates available or fwupdmgr error"
sudo fwupdmgr update --assume-yes || log "WARNING: Firmware update failed or not needed"
log "Firmware update step complete"

color_echo "green" "✅ Firmware update step complete."

# =============================================================================
# SECTION 6: Remove Bloatware
# =============================================================================
log_section "Removing Bloatware"

color_echo "yellow" "Removing unwanted pre-installed applications..."
BLOAT_PACKAGES=(
  gnome-music
  gnome-boxes
  gnome-snapshot
  gnome-characters
  gnome-connections
  gnome-contacts
  gnome-disk-utility
  baobab
  gnome-font-viewer
  gnome-color-manager
  libreoffice-common
  gnome-logs
  gnome-maps
  malcontent
  abrt
  gnome-system-monitor
  gnome-tour
  totem
  gnome-weather
  rhythmbox
  yelp
)

for pkg in "${BLOAT_PACKAGES[@]}"; do
  sudo apt remove -y --purge "$pkg" 2>/dev/null && log "Removed: $pkg" || log "INFO: $pkg not installed or already removed"
done

sudo apt autoremove -y
color_echo "green" "✅ Bloatware removal complete."

# =============================================================================
# SECTION 7: Install Required Dependencies & Packages
# =============================================================================
log_section "Installing Required Packages"

color_echo "yellow" "Installing core dependencies..."
sudo apt install -y \
  make \
  git \
  wget \
  curl \
  cabextract \
  unzip \
  fontconfig \
  xfonts-utils \
  gnome-shell-extension-prefs \
  gnome-tweaks \
  meson \
  ninja-build \
  gettext \
  libglib2.0-dev \
  gir1.2-gmenu-3.0 \
  htop \
  fastfetch \
  chromium \
  openssh-server \
  gnome-remote-desktop \
  power-profiles-daemon \
  remmina \
  openssl
log "Core packages installed"

color_echo "green" "✅ Core packages installed."

# =============================================================================
# SECTION 8: Install Flatpak Applications
# =============================================================================
log_section "Installing Flatpak Applications"

color_echo "yellow" "Installing Thunderbird..."
flatpak install -y flathub org.mozilla.Thunderbird
log "Thunderbird installed"

color_echo "yellow" "Installing LibreOffice..."
flatpak install -y flathub org.libreoffice.LibreOffice
log "LibreOffice installed"

color_echo "yellow" "Installing Flatseal..."
flatpak install -y flathub com.github.tchx84.Flatseal
log "Flatseal installed"

color_echo "yellow" "Installing Extension Manager..."
flatpak install -y flathub com.mattjakeman.ExtensionManager
log "Extension Manager installed"

color_echo "yellow" "Installing Slack..."
flatpak install -y flathub com.slack.Slack
log "Slack installed"

color_echo "green" "✅ Flatpak applications installed."

# =============================================================================
# SECTION 9: Install NoMachine (Dynamic Latest Version)
# =============================================================================
log_section "Installing NoMachine"

color_echo "yellow" "Fetching latest NoMachine DEB URL..."

NX_URL=$(curl -s "https://www.nomachine.com/download/download&id=1" \
  | grep -oP 'https://download\.nomachine\.com/download/[^"]+amd64\.deb' \
  | head -1)

if [ -z "$NX_URL" ]; then
  NX_URL=$(curl -s "https://www.nomachine.com/download" \
    | grep -oP 'https://download\.nomachine\.com/download/[^"]+amd64\.deb' \
    | head -1)
fi

if [ -z "$NX_URL" ]; then
  log "WARNING: Could not dynamically fetch NoMachine URL, using known latest version"
  NX_URL="https://download.nomachine.com/download/9.3/Linux/nomachine_9.3.7_1_amd64.deb"
fi

log "NoMachine download URL: $NX_URL"
NX_DEB="/tmp/nomachine_latest_amd64.deb"
wget -O "$NX_DEB" "$NX_URL"
sudo apt install -y "$NX_DEB"
rm -f "$NX_DEB"
log "NoMachine installed"

color_echo "green" "✅ NoMachine installed."

# =============================================================================
# SECTION 10: Install ZeroTier
# =============================================================================
log_section "Installing ZeroTier"

color_echo "yellow" "Installing ZeroTier..."
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/main/doc/contact%40zerotier.com.gpg' | gpg --import
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then
  echo "$z" | sudo bash
  log "ZeroTier installed"
else
  log "WARNING: ZeroTier GPG verification failed, trying direct install"
  curl -s https://install.zerotier.com | sudo bash
  log "ZeroTier installed via fallback"
fi

color_echo "green" "✅ ZeroTier installed."

# =============================================================================
# SECTION 11: Clone Winbian Repository & Install GNOME Extensions
# =============================================================================
log_section "Cloning Winbian Repository"

if [ -d "$ACTUAL_HOME/Winbian" ] || [ -d "$ACTUAL_HOME/winbian" ]; then
  log "Winbian directory already exists, pulling latest..."
  git -C "$WINBIAN_DIR" pull
else
  git clone https://github.com/StiviKM/Winbian "$WINBIAN_DIR"
  log "Winbian repository cloned"
fi

color_echo "yellow" "Copying hidden icon file..."
cp "$WINBIAN_DIR/.arc_icon.png" "$ACTUAL_HOME/.arc_icon.png"
log "Icon file copied"

log_section "Installing GNOME Extensions"

# --- Dash-to-Panel ---
color_echo "yellow" "Installing Dash-to-Panel..."
DTP_DIR="/tmp/dash-to-panel"
rm -rf "$DTP_DIR"
git clone https://github.com/home-sweet-gnome/dash-to-panel.git "$DTP_DIR"
cd "$DTP_DIR"
make install
cd ~
rm -rf "$DTP_DIR"
log "Dash-to-Panel installed"

# --- ArcMenu ---
color_echo "yellow" "Installing ArcMenu..."
ARCMENU_DIR="/tmp/ArcMenu"
rm -rf "$ARCMENU_DIR"
git clone https://gitlab.com/arcmenu/ArcMenu.git "$ARCMENU_DIR"
cd "$ARCMENU_DIR"
make install
cd ~
rm -rf "$ARCMENU_DIR"
log "ArcMenu installed"

# --- Desktop Icons NG ---
color_echo "yellow" "Installing Desktop Icons NG..."
DING_DIR="/tmp/desktop-icons-ng"
rm -rf "$DING_DIR"
git clone https://gitlab.com/rastersoft/desktop-icons-ng.git "$DING_DIR"
cd "$DING_DIR"
chmod +x ./local_install.sh
./local_install.sh
cd ~
rm -rf "$DING_DIR"
log "Desktop Icons NG installed"

# --- AppIndicator Support ---
color_echo "yellow" "Installing AppIndicator Support..."
APPIND_DIR="/tmp/gnome-shell-extension-appindicator"
APPIND_BUILD="/tmp/g-s-appindicators-build"
rm -rf "$APPIND_DIR" "$APPIND_BUILD"
git clone https://github.com/ubuntu/gnome-shell-extension-appindicator.git "$APPIND_DIR"
meson --prefix="$ACTUAL_HOME/.local" "$APPIND_DIR" "$APPIND_BUILD"
ninja -C "$APPIND_BUILD" install
rm -rf "$APPIND_DIR" "$APPIND_BUILD"
log "AppIndicator Support installed"

color_echo "green" "✅ All GNOME extensions installed."

# =============================================================================
# SECTION 12: Install ZSH + Oh My ZSH
# =============================================================================
log_section "Installing ZSH and Oh My ZSH"

color_echo "yellow" "Installing ZSH..."
sudo apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting
log "ZSH packages installed"

color_echo "yellow" "Installing Oh My ZSH..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
log "Oh My ZSH installed"

color_echo "yellow" "Installing ZSH plugins..."

git clone https://github.com/zsh-users/zsh-autosuggestions.git \
  "${ZSH_CUSTOM:-$ACTUAL_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" 2>/dev/null \
  || log "INFO: zsh-autosuggestions plugin already exists"

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "${ZSH_CUSTOM:-$ACTUAL_HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" 2>/dev/null \
  || log "INFO: zsh-syntax-highlighting plugin already exists"

git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
  "${ZSH_CUSTOM:-$ACTUAL_HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting" 2>/dev/null \
  || log "INFO: fast-syntax-highlighting plugin already exists"

git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git \
  "${ZSH_CUSTOM:-$ACTUAL_HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete" 2>/dev/null \
  || log "INFO: zsh-autocomplete plugin already exists"

log "ZSH plugins installed"

color_echo "yellow" "Configuring .zshrc..."
ZSHRC="$ACTUAL_HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
  sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)/' "$ZSHRC"
  sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="jonathan"/' "$ZSHRC"
  log ".zshrc plugins and theme configured"
else
  log "WARNING: .zshrc not found, Oh My ZSH may not have installed correctly"
fi

color_echo "yellow" "Changing default shell to ZSH..."
sudo chsh -s "$(which zsh)" "$ACTUAL_USER"
log "Default shell changed to ZSH for $ACTUAL_USER"

color_echo "green" "✅ ZSH and Oh My ZSH installed."

# =============================================================================
# SECTION 13: Install Fonts
# =============================================================================
log_section "Installing Fonts"

FONTS_DIR="$ACTUAL_HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR/windows"

color_echo "yellow" "Installing Microsoft Windows fonts..."
wget -O /tmp/winfonts.zip https://mktr.sbs/fonts
unzip -o /tmp/winfonts.zip -d "$FONTS_DIR/windows"
rm -f /tmp/winfonts.zip
log "Windows fonts installed"

fc-cache -fv
log "Font cache updated"

color_echo "green" "✅ Fonts installed."

# =============================================================================
# SECTION 14: Schedule Winbian_Two.sh After Reboot
# =============================================================================
log_section "Scheduling Stage 2"

# Detect available terminal emulator
if command -v ptyxis &>/dev/null; then
  TERMINAL="ptyxis --"
elif command -v gnome-terminal &>/dev/null; then
  TERMINAL="gnome-terminal --"
elif command -v xterm &>/dev/null; then
  TERMINAL="xterm -e"
else
  TERMINAL="bash -c"
  log "WARNING: No known terminal emulator found, autostart may not show a window"
fi

log "Using terminal: $TERMINAL"

AUTOSTART_DIR="$ACTUAL_HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/winbian_two.desktop"
STAGE2_SCRIPT="$WINBIAN_DIR/Winbian_Two.sh"

mkdir -p "$AUTOSTART_DIR"
chmod +x "$STAGE2_SCRIPT"

cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Exec=$TERMINAL bash -c '$STAGE2_SCRIPT; echo; echo "✅ Winbian Stage 2 finished. Check ~/winbian.log for details."; read -p "Press Enter to close..."'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Winbian Stage 2
Comment=Completes the Winbian setup after reboot
EOF

log "Stage 2 autostart entry created at $AUTOSTART_FILE"
color_echo "green" "✅ Stage 2 scheduled for after reboot."

# =============================================================================
# DONE - Reboot
# =============================================================================
log_section "Stage 1 Complete - Rebooting"
color_echo "green" "✅ Winbian Stage 1 complete! Rebooting in 10 seconds..."
kill $SUDO_KEEPALIVE_PID 2>/dev/null || true
log "Rebooting system..."
sleep 10
sudo reboot
