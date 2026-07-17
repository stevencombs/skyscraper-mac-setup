# Skyscraper on macOS for R36MAX2 / EmuELEC SD Cards

Deploy **Skyscraper** (Gemba fork) on a Mac to scrape box art, screenshots, and metadata for EmulationStation-based handhelds such as the **R36MAX2** (EmuELEC).

This repository documents a working setup used with an SD card volume named **`EEROMS`** mounted at `/Volumes/EEROMS`. Paths can be changed for any similar card layout.

| Component | Purpose |
|-----------|---------|
| [Skyscraper](https://github.com/Gemba/skyscraper) | CLI scraper + EmulationStation gamelist generator |
| ScreenScraper | Online art/metadata source |
| `config.ini` | Permanent paths and scrape options |
| `scrape-eeroms` | Helper script for common workflows |

**Official docs:** [gemba.github.io/skyscraper](https://gemba.github.io/skyscraper/)

---

## Table of contents

1. [How scraping works](#how-scraping-works)
2. [Repository layout](#repository-layout)
3. [Prerequisites](#prerequisites)
4. [Install on a new Mac](#install-on-a-new-mac)
5. [Configuration](#configuration)
6. [ScreenScraper account](#screenscraper-account)
7. [Command reference](docs/COMMANDS.md#command-reference)
8. [Scraping examples](docs/COMMANDS.md#scraping-examples)
9. [Helper script](docs/COMMANDS.md#helper-script-scrape-eeroms)
10. [What gets written to the SD card](docs/COMMANDS.md#what-gets-written-to-the-sd-card)
11. [After scraping](docs/COMMANDS.md#after-scraping-on-the-handheld)
12. [Updating](docs/COMMANDS.md#updating-skyscraper)
13. [Troubleshooting](docs/COMMANDS.md#troubleshooting)
14. [Uninstall](docs/COMMANDS.md#uninstall)
15. [References](docs/COMMANDS.md#references)

---

## How scraping works

Skyscraper is a **two-step** tool:

1. **Gather** (`-s <module>`) — download metadata and media into a **local cache** under `~/.skyscraper/cache/<platform>/`.
2. **Generate** (no `-s`) — compose artwork and write `gamelist.xml` + media folders onto the SD card.

```
ROMs on SD card  →  ScreenScraper (network)  →  ~/.skyscraper/cache/
                                                      ↓
                    gamelist.xml + media/  ←  gamelist generation
```

You can gather once, then regenerate gamelists many times without re-downloading.

---

## Repository layout

```
skyscraper-mac-setup/
├── README.md
├── docs/
│   └── COMMANDS.md                ← full CLI reference + scrape examples
├── config/
│   └── config.ini.example
└── scripts/
    ├── install-skyscraper-macos.sh
    └── scrape-eeroms
```

```bash
git clone https://github.com/stevencombs/skyscraper-mac-setup.git
cd skyscraper-mac-setup
```

---

## Prerequisites

### Hardware / media

- Mac (Apple Silicon or Intel)
- MicroSD card reader
- SD card from the handheld with ROM folders at the root (EmuELEC style: `snes/`, `gba/`, `nes/`, …)

### Accounts

- Free [ScreenScraper](https://www.screenscraper.fr) account (strongly recommended)

### Software

| Tool | Notes |
|------|--------|
| [Homebrew](https://brew.sh) | Package manager |
| Xcode Command Line Tools | Prefer SDK 14+. Very old CLT can break Qt 6 builds. |
| Homebrew packages | `qt`, `wget`, `gnu-tar`, and (if CLT is outdated) `llvm` |

```bash
xcrun --show-sdk-version
clang --version
```

If the SDK is older than **14**, update Command Line Tools or use Homebrew LLVM (see install script).

---

## Install on a new Mac

### Option A — Automated install script

```bash
cd skyscraper-mac-setup
chmod +x scripts/install-skyscraper-macos.sh scripts/scrape-eeroms
./scripts/install-skyscraper-macos.sh
```

Then:

```bash
mkdir -p ~/.skyscraper
cp config/config.ini.example ~/.skyscraper/config.ini
nano ~/.skyscraper/config.ini   # set userCreds + paths

cp scripts/scrape-eeroms ~/.local/bin/
chmod +x ~/.local/bin/scrape-eeroms

source ~/.zshrc
Skyscraper --buildinfo
```

### Option B — Manual install

See the full steps in the [install script](scripts/install-skyscraper-macos.sh) and original documentation history. Summary:

```bash
brew install gnu-tar wget qt llvm   # llvm if SDK < 14
export PATH="/opt/homebrew/opt/llvm/bin:/opt/homebrew/opt/qt/bin:$PATH"
export CC=clang CXX=clang++
export PREFIX="$HOME/.local" SYSCONFDIR="$HOME/.local/etc"

mkdir -p ~/skysource && cd ~/skysource
git clone --depth 1 https://github.com/Gemba/skyscraper.git .
PREFIX="$HOME/.local" SYSCONFDIR="$HOME/.local/etc" qmake6 \
  "QMAKE_CC=$CC" "QMAKE_CXX=$CXX" "QMAKE_LINK=$CXX" \
  "QMAKE_CXXFLAGS+=-stdlib=libc++" "QMAKE_LFLAGS+=-stdlib=libc++" skyscraper.pro
make -j"$(sysctl -n hw.ncpu)"
mkdir -p "$HOME/.local/bin" "$HOME/.local/etc/skyscraper"
cp Skyscraper.app/Contents/MacOS/Skyscraper "$HOME/.local/bin/Skyscraper"
# Copy peas.json and other assets from source tree to ~/.local/etc/skyscraper/
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

**Important:** `PREFIX` must be an **environment variable** for `qmake` (`PREFIX=$$(PREFIX)` in `skyscraper.pro`).

---

## Configuration

Copy the example and edit credentials:

```bash
cp config/config.ini.example ~/.skyscraper/config.ini
```

Key settings in `[main]`:

- `inputFolder="/Volumes/EEROMS"` / `gameListFolder="/Volumes/EEROMS"` (platform is appended)
- `frontend="emulationstation"`
- `relativePaths="true"`, `gameListBackup="true"`
- `unattend="true"` for non-interactive runs

Under `[screenscraper]`:

```ini
userCreds="YOUR_USERNAME:YOUR_PASSWORD"
```

Never commit real passwords. Keep secrets only in `~/.skyscraper/config.ini` on each machine.

Different volume name:

```ini
inputFolder="/Volumes/MYCARD"
gameListFolder="/Volumes/MYCARD"
```

---

## ScreenScraper account

1. Register at [screenscraper.fr](https://www.screenscraper.fr)
2. Set `userCreds` in `~/.skyscraper/config.ini`
3. Free accounts have daily limits; large libraries may need a higher tier

```bash
Skyscraper -p snes -s screenscraper -u "username:password"
```

---

## Quick start scraping

```bash
# List systems on the card
scrape-eeroms --list

# Small test
scrape-eeroms atari7800

# Or raw Skyscraper two-step
Skyscraper -p snes -s screenscraper
Skyscraper -p snes
```

**Full CLI reference, 20 scrape examples, flags, cache commands, troubleshooting:** see **[docs/COMMANDS.md](docs/COMMANDS.md)**.

---

## After scraping

1. Eject the SD card safely
2. Insert into the R36MAX2
3. Boot EmulationStation
4. **Start → Update Games Lists** (or reboot)

---

## License notes

Skyscraper is GPL-3.0 (upstream). Helper scripts and docs in this repository are provided as-is for personal deployment. ROM files and game assets remain your responsibility to own and use legally.
