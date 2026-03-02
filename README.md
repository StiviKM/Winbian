# Winbian

Automated **Debian 13 (Trixie)** setup that transforms a fresh install into a Windows-lookalike desktop environment. Designed for mass deployment — clone, chmod, run, walk away.

---

## Requirements

* Fresh **Debian 13 (Trixie)** install (GNOME edition recommended)
* A **normal user account** (not root)
* Internet connection
* GNOME desktop session

---

## Usage

```bash
git clone https://github.com/StiviKM/Winbian
chmod +x Winbian/Winbian_One.sh Winbian/Winbian_Two.sh
./Winbian/Winbian_One.sh
```

The setup is fully automated across two stages with an automatic reboot between them.

---

## How It Works

### Stage 1 — `Winbian_One.sh`

Runs manually. Handles all system-level setup, then reboots.

* Prompts for your password **once**, keeps sudo active during execution
* Configures APT for faster downloads and parallel fetching
* Full system update and upgrade
* Enables automatic updates via unattended upgrades
* Enables Flatpak support and configures Flathub
* Installs multimedia codecs and hardware acceleration support
* Installs and enables SSH server
* Performs firmware update checks using `fwupd`
* Removes bloatware packages (see list below)
* Installs required utilities, development tools, and dependencies
* Installs Flatpak applications
* Installs latest NoMachine package dynamically
* Installs ZeroTier
* Clones Winbian repo and installs GNOME extensions
* Installs ZSH + Oh My ZSH with plugins and theme
* Installs Microsoft Windows fonts and Google Fonts
* Schedules Stage 2 to run automatically after reboot
* Reboots system

---

### Stage 2 — `Winbian_Two.sh`

Runs automatically after login via GNOME autostart. Handles session-level configuration.

* Removes autostart entry immediately to prevent loops
* Waits for GNOME Shell readiness before continuing
* Applies Dash-to-Panel configuration from repo
* Applies ArcMenu configuration from repo
* Installs Windows-style icon themes
* Sets wallpaper
* Enables and configures GNOME extensions
* Applies desktop behavior settings
* Configures GNOME Remote Desktop with TLS certificate
* Cleans temporary files and Winbian directory

---

## What Gets Removed (Bloatware)

| App                     | Package                |
| ----------------------- | ---------------------- |
| GNOME Games             | `gnome-games`          |
| LibreOffice (default)   | `libreoffice*`         |
| Evolution Mail          | `evolution*`           |
| Cheese Camera           | `cheese`               |
| GNOME Maps              | `gnome-maps`           |
| GNOME Contacts          | `gnome-contacts`       |
| GNOME Weather           | `gnome-weather`        |
| GNOME Music             | `gnome-music`          |
| Rhythmbox               | `rhythmbox`            |
| Totem Video Player      | `totem`                |
| GNOME Logs              | `gnome-logs`           |
| GNOME System Monitor    | `gnome-system-monitor` |
| GNOME Tour              | `gnome-tour`           |
| Parental Controls       | `malcontent`           |
| Problem Reporting Tools | `reportbug` + related  |

---

## What Gets Installed

### System Packages

```
git wget curl make build-essential cabextract unzip fontconfig
htop fastfetch chromium openssh-server gnome-tweaks gnome-extensions-app
meson ninja-build gettext gnome-menus libglib2.0-dev zsh
zsh-autosuggestions zsh-syntax-highlighting
```

### Flatpak Applications (Flathub)

* Thunderbird
* LibreOffice
* Slack
* Flatseal
* Extension Manager

### Other Software

* NoMachine (latest RPM/DEB dynamically fetched)
* ZeroTier

---

## GNOME Extensions Installed

* Dash-to-Panel
* ArcMenu
* Desktop Icons NG (DING)
* AppIndicator Support

---

## Desktop Settings Applied

* **Taskbar** — Dash-to-Panel at bottom (Windows style)

* **Start Menu** — ArcMenu with custom icon

* **Icons** — Windows 11 dark theme

* **Wallpaper** — Custom Windows-style wallpaper

* **Pinned Apps**

  * Firefox
  * Nautilus
  * Slack
  * Thunderbird
  * Remmina

* **Window Buttons** — Minimize, Maximize, Close enabled

* **Keyboard Layouts** — US + secondary international layout

* **Hot Corners** — Disabled

* **Workspaces** — Single workspace

* **Power Settings**

  * No automatic sleep or hibernate
  * Screen lock disabled
  * Performance profile tuned via system tools

* **File Manager (Nautilus)**

  * Tree view enabled
  * Recursive search enabled
  * Thumbnails and item counts enabled
  * Sort directories first
  * Permanent delete and link creation enabled

* **Shell**

  * ZSH with Oh My ZSH
  * Autosuggestions + syntax highlighting + fast autocomplete

---

## Remote Access

### SSH

Enabled automatically.

Connect using:

```bash
ssh username@machine-ip
```

---

### RDP (GNOME Remote Desktop)

Enabled automatically with self-signed TLS certificates.

Port 3389 is configured in the firewall.

Set credentials manually after setup:

```bash
grdctl rdp set-credentials <username> <password>
```

---

## Logging

All installation steps are logged with timestamps to:

```
~/winbian.log
```

Logs are appended on each run for full history tracking.

---

## Notes

* Script must be run as a **normal user**, not root or via sudo directly
* Firmware updates may show warnings on virtual machines (expected)
* Codec installs may warn if hardware is not present (non-fatal)
* Google Fonts download is large (~600MB)
* RDP credentials are intentionally not stored automatically for security
