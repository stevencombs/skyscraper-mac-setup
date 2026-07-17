# Command reference and scrape examples

## Command reference

### Always available

```bash
Skyscraper --help
Skyscraper --help-all
Skyscraper --flags help
Skyscraper --cache help
Skyscraper --buildinfo
Skyscraper --hint
```

### Core two-step workflow

```bash
# Step 1: gather into cache
Skyscraper -p <PLATFORM> -s screenscraper

# Step 2: write gamelist + media to the card
Skyscraper -p <PLATFORM>
```

### Important options

| Option | Meaning |
|--------|---------|
| `-p <PLATFORM>` | System (e.g. `snes`, `gba`, `nes`, `psx`) |
| `-s <MODULE>` | Scraping module (`screenscraper`, `thegamesdb`, `esgamelist`, `import`, …) |
| `-u USER:PASS` | ScreenScraper (or other) credentials |
| `-i <PATH>` | ROM input folder |
| `-g <PATH>` | Gamelist output folder |
| `-o <PATH>` | Media output folder |
| `-f <FRONTEND>` | `emulationstation` (default), `batocera`, `esde`, `pegasus`, … |
| `-c <FILE>` | Alternate config file |
| `-d <FOLDER>` | Alternate cache base folder |
| `-a <FILE>` | Custom `artwork.xml` |
| `--flags FLAG1,FLAG2` | Runtime flags (see below) |
| `--onlymissing` | Only scrape games with nothing in cache |
| `--startat FILE` / `--endat FILE` | Subset of alphabetically ordered ROMs |
| `--includefrom FILE` / `--excludefrom FILE` | File lists |
| `--includepattern` / `--excludepattern` | Glob filters |
| `--lang` / `--region` | Language / region preference |
| `-m <0-100>` | Minimum title match % |
| `-l <N>` | Max description length |

Leaving out `-s` switches to **gamelist generation mode** (uses cache only).

### Common flags (`--flags`)

```bash
Skyscraper --flags help
```

| Flag | Use |
|------|-----|
| `onlymissing` | Skip games that already have any cache data |
| `pretend` | Dry-run gamelist generation (no write) |
| `interactive` | Manually pick matches |
| `videos` | Enable video scrape/export (if configured) |
| `relative` | Force relative paths in gamelist |
| `nobrackets` | Strip `()` / `[]` from titles in gamelist |
| `forcefilename` | Use filename as display name |
| `nosubdirs` | Do not recurse into subfolders |
| `nocovers` / `noscreenshots` / `nowheels` / `nomarquees` | Skip caching those media types |
| `noresize` | Store full-res art in cache (uses more disk) |
| `skipexistingcovers` (etc.) | When generating, skip media files already on card |
| `unattend` | No overwrite prompts |

```bash
Skyscraper -p snes -s screenscraper --flags onlymissing
Skyscraper -p snes --flags pretend
Skyscraper -p snes -s screenscraper --flags interactive
```

### Cache commands

```bash
Skyscraper --cache help
Skyscraper -p snes --cache show
Skyscraper -p snes --cache report:missing=cover
Skyscraper -p snes -s screenscraper --cache refresh
Skyscraper -p snes --cache vacuum
Skyscraper -p snes --cache validate
Skyscraper -p snes --cache purge:all
```

### Scraping modules (`-s`)

| Module | Role |
|--------|------|
| `screenscraper` | Best general source for most systems |
| `thegamesdb` | Alternate metadata/art |
| `esgamelist` | Import existing `gamelist.xml` into cache |
| `import` | Import local custom media into cache |
| `arcadedb` | Arcade-oriented |
| `openretro` | Amiga-focused |
| (others) | See `Skyscraper --help` and [SCRAPINGMODULES](https://gemba.github.io/skyscraper/SCRAPINGMODULES/) |

---

## Scraping examples

Assume the SD card is mounted at `/Volumes/EEROMS` and `config.ini` is configured.  
Open a new shell with `~/.local/bin` on `PATH`.

### 1. Verify install and card mount

```bash
Skyscraper --buildinfo
ls /Volumes/EEROMS
ls /Volumes/EEROMS/snes | head
```

### 2. Small first test (recommended)

```bash
Skyscraper -p atari7800 -s screenscraper
Skyscraper -p atari7800
ls /Volumes/EEROMS/atari7800/media
head -40 /Volumes/EEROMS/atari7800/gamelist.xml
```

### 3. Single popular systems

```bash
Skyscraper -p snes -s screenscraper && Skyscraper -p snes
Skyscraper -p gba  -s screenscraper && Skyscraper -p gba
Skyscraper -p nes  -s screenscraper && Skyscraper -p nes
Skyscraper -p genesis -s screenscraper && Skyscraper -p genesis
Skyscraper -p psx  -s screenscraper && Skyscraper -p psx
Skyscraper -p n64  -s screenscraper && Skyscraper -p n64
```

### 4. Helper script

```bash
scrape-eeroms --list
scrape-eeroms atari7800
scrape-eeroms snes gba nes
ROMS_ROOT="/Volumes/OTHERCARD" scrape-eeroms snes
scrape-eeroms --cache-only snes gba
```

### 5. Only scrape games still missing from the cache

```bash
Skyscraper -p snes -s screenscraper --flags onlymissing
Skyscraper -p snes
```

### 6. Dry-run gamelist (no files written)

```bash
Skyscraper -p snes --flags pretend
```

### 7. Scrape a subset of files by name range

```bash
Skyscraper -p snes -s screenscraper --startat "Super Mario World.zip" --endat "Super Metroid.zip"
Skyscraper -p snes
```

### 8. Scrape only specific ROMs

```bash
Skyscraper -p snes -s screenscraper \
  "/Volumes/EEROMS/snes/Super Mario World.zip" \
  "/Volumes/EEROMS/snes/Chrono Trigger.zip"
Skyscraper -p snes
```

### 9. Pattern include / exclude

```bash
Skyscraper -p snes -s screenscraper --includepattern "Super*"
Skyscraper -p snes -s screenscraper --excludepattern "*[BIOS]*,*proto*,*Proto*"
```

### 10. Report missing art, then scrape only those

```bash
Skyscraper -p snes --cache report:missing=cover
# Report path is printed; then:
Skyscraper -p snes -s screenscraper --includefrom ~/.skyscraper/reports/report-snes-missing_cover.txt
Skyscraper -p snes
```

### 11. Import existing EmulationStation gamelists into the cache

```bash
Skyscraper -p psx -s esgamelist
Skyscraper -p psx -s screenscraper --flags onlymissing
Skyscraper -p psx
```

### 12. Interactive matching (tricky filenames)

```bash
Skyscraper -p snes -s screenscraper --flags interactive --startat "Some Odd Name.zip" --endat "Some Odd Name.zip"
```

### 13. Prefer Japanese region/language for a system

```bash
Skyscraper -p snes -s screenscraper --lang ja --region jp
```

### 14. Enable videos (uses more space and time)

In `config.ini`:

```ini
[main]
videos="true"
[screenscraper]
videos="true"
```

```bash
Skyscraper -p psx -s screenscraper --flags videos
Skyscraper -p psx --flags videos
```

### 15. Alternate SD path without editing config

```bash
Skyscraper -p gba -s screenscraper \
  -i "/Volumes/OTHERCARD/gba" \
  -g "/Volumes/OTHERCARD/gba" \
  -o "/Volumes/OTHERCARD/gba/media"

Skyscraper -p gba \
  -i "/Volumes/OTHERCARD/gba" \
  -g "/Volumes/OTHERCARD/gba" \
  -o "/Volumes/OTHERCARD/gba/media"
```

### 16. Custom config file

```bash
Skyscraper -c ~/skyscraper-mac-setup/config/config.ini.example -p snes --flags pretend
```

### 17. Batch many systems (bash loop)

```bash
for p in atari7800 lynx gamegear ngpc pcengine; do
  echo "==== $p ===="
  Skyscraper -p "$p" -s screenscraper
  Skyscraper -p "$p"
done
```

### 18. Regenerate gamelist only (no network)

```bash
Skyscraper -p snes
scrape-eeroms --cache-only snes
```

### 19. Show cache status

```bash
Skyscraper -p snes --cache show
```

### 20. Clean cache for removed ROMs

```bash
Skyscraper -p snes --cache vacuum
```

### Platform names vs folder names

| Folder on card | Typical `-p` |
|----------------|--------------|
| `snes`, `sfc` | `snes` (may need per-folder `-i`) |
| `nes`, `famicom` | `nes` / check platform list |
| `gba`, `gbc`, `gb` | `gba`, `gbc`, `gb` |
| `megadrive`, `genesis` | `megadrive` or `genesis` |
| `psx` | `psx` |
| `n64` | `n64` |
| `arcade`, `mame` | `arcade` / `mame` |
| `atari2600`, `atari7800` | same names |

```bash
Skyscraper -p snes -i /Volumes/EEROMS/sfc -g /Volumes/EEROMS/sfc -o /Volumes/EEROMS/sfc/media -s screenscraper
Skyscraper -p snes --listext
```

---

## Helper script: scrape-eeroms

| Variable | Default | Meaning |
|----------|---------|---------|
| `ROMS_ROOT` | `/Volumes/EEROMS` | SD card mount path |

```bash
scrape-eeroms --list
scrape-eeroms snes
scrape-eeroms snes gba nes psx
scrape-eeroms --cache-only snes gba
ROMS_ROOT="/Volumes/OTHERCARD" scrape-eeroms snes
```

---

## What gets written to the SD card

```
/Volumes/EEROMS/snes/
├── gamelist.xml
├── gamelist.xml-YYYYMMDD-…      ← backup if gameListBackup=true
├── media/{covers,screenshots,wheels,...}/
└── <rom files unchanged>
```

Cache stays on the Mac: `~/.skyscraper/cache/`.

```bash
find /Volumes/EEROMS -name '._*' -type f -delete
find /Volumes/EEROMS -name '.DS_Store' -type f -delete
```

---

## After scraping (on the handheld)

1. Eject the SD card safely from the Mac
2. Insert into the **R36MAX2**
3. Boot EmulationStation
4. **Start → Game Collection Settings → Update Games Lists** (or reboot)

---

## Updating Skyscraper

```bash
export PATH="/opt/homebrew/opt/llvm/bin:/opt/homebrew/opt/qt/bin:$PATH"
export CC="/opt/homebrew/opt/llvm/bin/clang" CXX="/opt/homebrew/opt/llvm/bin/clang++"
export PREFIX="$HOME/.local" SYSCONFDIR="$HOME/.local/etc"
cd ~/skysource
# re-run install script, or qmake6 + make, then:
cp -f Skyscraper.app/Contents/MacOS/Skyscraper "$HOME/.local/bin/Skyscraper"
```

---

## Troubleshooting

### `File not found 'peas.json'`

Re-copy support files to `~/.local/etc/skyscraper/` and ensure binary was built with matching `PREFIX` / `SYSCONFDIR`.

### Qt / clang SDK errors

```bash
brew install llvm qt
# rebuild with Homebrew clang as in install script
```

### ScreenScraper rate limits

Confirm `userCreds`, scrape fewer systems/day, use `--flags onlymissing`, consider higher SS tier.

### Covers missing on the handheld

Confirm `gamelist.xml` has `<image>` tags; Update Games Lists; Skyscraper uses `media/` (not `downloaded_images/`).

### Wrong volume

```bash
ls /Volumes/EEROMS
Skyscraper -p snes --flags pretend
```

---

## Uninstall

```bash
rm -f ~/.local/bin/Skyscraper ~/.local/bin/scrape-eeroms
rm -rf ~/.local/etc/skyscraper ~/skysource
# optional: rm -rf ~/.skyscraper
```

---

## References

- [Gemba/skyscraper](https://github.com/Gemba/skyscraper)
- [User manual](https://gemba.github.io/skyscraper/)
- [CONFIGINI](https://gemba.github.io/skyscraper/CONFIGINI/)
- [CLIHELP](https://gemba.github.io/skyscraper/CLIHELP/)
- [ScreenScraper](https://www.screenscraper.fr)
