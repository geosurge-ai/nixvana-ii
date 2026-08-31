# imperative-darwin

macOS configuration that can't be managed declaratively via home-manager.
These apps require macOS accessibility permissions, write back to their
config files via GUIs, or need homebrew cask installation.

## Setup on a fresh Mac

```bash
# 1. Install Nix via Determinate Systems installer
#    (provides flakes, nix-command, and a graphical uninstaller out of the box)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Install homebrew (for GUI apps that need cask installation)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Install all GUI apps
brew bundle --file=imperative-darwin/Brewfile

# 4. Unblock Gatekeeper quarantine on all apps
sudo xattr -dr com.apple.quarantine /Applications/*.app 2>/dev/null

# 5. Set macOS system defaults (keyboard repeat, dock, etc.)
imperative-darwin/bin/macos-defaults
# Log out and back in for keyboard repeat to take effect

# 6. F-keys as function keys (must be done via GUI — defaults write alone
#    does not take effect without re-login on modern macOS):
#    System Settings > Keyboard > Keyboard Shortcuts... > Function Keys
#    Toggle "Use F1, F2, etc. keys as standard function keys"
#    (The macos-defaults script writes the backing default, but the GUI
#    toggle applies it immediately without a re-login.)

# 7. Deploy configs (see per-app sections below)

# 8. Grant accessibility permissions (System Settings > Privacy & Security > Accessibility):
#    - Karabiner-Elements (karabiner_grabber + karabiner_observer)
#    - AeroSpace
#    - LinearMouse
```

---

## bin/macos-defaults

System-level defaults that can't be managed by home-manager or nix-darwin.
Run once on a fresh Mac, then log out and back in.

What it sets:
- **Fast keyboard repeat**: KeyRepeat=2 (30ms), InitialKeyRepeat=15 (225ms)
- **Disable press-and-hold**: enables key repeat everywhere (no accent popup)
- **F-keys as F-keys**: F1-F12 send actual function key codes; hold Fn for hardware controls (brightness, volume, etc.). The script writes the backing `defaults` key, but on modern macOS (Ventura+) you must also flip it via GUI for it to apply without re-login: System Settings > Keyboard > Keyboard Shortcuts... > Function Keys.
- **Auto-hide dock**

---

## Brewfile

All GUI apps that need homebrew cask installation. Includes:
- Window manager: AeroSpace
- Input: Karabiner-Elements, LinearMouse
- Terminal: Ghostty
- Browsers: Chromium, Google Chrome
- Media: IINA, VLC, Spotify, OBS
- Dev: Blender, GIMP
- Comms: Slack
- Games: Steam

---

## configs/karabiner/karabiner.json

Deploy: `cp configs/karabiner/karabiner.json ~/.config/karabiner/karabiner.json`
(Karabiner auto-reloads on file change)

### What's configured

**Em dash input:**
- Right Option + `-` / `=` -> em dash
- Right Command + `-` / `=` -> em dash

**PC-Style shortcuts** (Ctrl -> Cmd mapping, skipped in terminals/VMs):
- Paste, Cut, Copy, Undo, Find, Select-All, Open, New, New Tab, Quit (Alt+F4)

**Navigation:**
- Ctrl+Arrows -> Option+Arrows (word movement)
- Alt+Left/Right -> Cmd+Left/Right in browsers (back/forward)
- Right Command + HJKL -> Arrow keys (vim navigation)

**Utilities:**
- Ctrl+Shift+Esc -> Activity Monitor
- Option+P -> Spotlight (XMonad-style)
- Option+Shift+Enter -> Open Ghostty
- Option+Shift+C -> Close window (XMonad-style)

**Hardware:**
- Fn <-> Left Control swap (Apple internal keyboard)
- Non-US backslash -> grave accent/tilde

---

## configs/aerospace/aerospace.toml

Deploy: `cp configs/aerospace/aerospace.toml ~/.aerospace.toml`

XMonad-style tiling window manager config:
- `alt` (Option) as modifier
- Vim directions (HJKL) for focus and move
- Workspaces 1-9 + A-Z
- Service mode via alt+shift+;

---

## configs/linearmouse/linearmouse.json

Deploy: `cp configs/linearmouse/linearmouse.json ~/.config/linearmouse/linearmouse.json`

Per-device pointer settings:
- **Trackpad**: acceleration `0.6641`, just under the macOS default of ~`0.6875`
- **Mouse**: acceleration `0` (a flat, velocity-independent curve) and speed
  `0.22`, which LinearMouse folds into the pointer resolution

The mouse scheme is keyed on `category` and nothing else, so **every** mouse
you own inherits it and they all feel the same. That is the whole point of the
scheme, and it is worth keeping intact.

Beware that the LinearMouse GUI works against this. Changing pointer settings
there does not edit the category scheme; it appends a new one pinned to the
vendor and product ID of whichever mouse happened to be connected. Do that for
two mice and you have two per-device schemes, and a third mouse now matches
neither -- so it falls through to the macOS defaults and gets an acceleration
*curve* while its siblings have a flat one. The mismatch is velocity-dependent,
which is why it feels unfixable: no value of `speed` makes an accelerated mouse
track like a non-accelerated one, because they only diverge as you move faster.
If your mice ever stop feeling alike, look here first and delete the per-device
schemes.

Note that `disableAcceleration: true` is not a stronger form of
`acceleration: 0`. Per the schema it means "acceleration **and speed** will not
take effect", so setting it discards the tuning in the same block.

What this file cannot equalise is the DPI burned into each mouse's sensor. Two
mice at the same `speed` but different onboard DPI differ by exactly the ratio
of those DPI values, and games reading raw HID deltas bypass this file
altogether. Match DPI on the hardware (Logitech G HUB, Razer Synapse, or the
device's own DPI button) rather than compensating here.

---

## configs/ghostty/config

Deploy:
```bash
mkdir -p ~/Library/Application\ Support/com.mitchellh.ghostty
cp configs/ghostty/config ~/Library/Application\ Support/com.mitchellh.ghostty/config
```

Settings:
- Font: PragmataPro Liga, size 16
- `auto-update = off`
