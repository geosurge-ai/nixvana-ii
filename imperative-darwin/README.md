# imperative-darwin

macOS configuration that can't be managed declaratively via home-manager.
These apps require macOS accessibility permissions, write back to their
config files via GUIs, or need homebrew cask installation.

## Setup on a fresh Mac

```bash
# 1. Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install all apps
brew bundle --file=imperative-darwin/Brewfile

# 3. Unblock Gatekeeper quarantine on all apps
sudo xattr -dr com.apple.quarantine /Applications/*.app 2>/dev/null

# 4. Set macOS system defaults (keyboard repeat, dock, etc.)
imperative-darwin/bin/macos-defaults
# Log out and back in for keyboard repeat to take effect

# 5. Deploy configs (see per-app sections below)

# 6. Grant accessibility permissions (System Settings > Privacy & Security > Accessibility):
#    - Karabiner-Elements (karabiner_grabber + karabiner_observer)
#    - AeroSpace
#    - LinearMouse
```

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
- Trackpad: custom acceleration
- Mouse: no acceleration, low speed

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

---

## Using home-manager launchd agents

This repo demonstrates how to run macOS launchd services via home-manager.
See the nix modules in `home-manager/include/services/` for working examples:

### GPG agent (`gpg-darwin.nix`)
Starts `gpg-agent` at login using `RunAtLoad = true`:
```nix
launchd.agents.gpg-agent-start = {
  enable = true;
  config = {
    ProgramArguments = [ "''${gpg}/bin/gpgconf" "--launch" "gpg-agent" ];
    EnvironmentVariables.GNUPGHOME = "''${config.home.homeDirectory}/.gnupg";
    RunAtLoad = true;
  };
};
```

### Scheduled backup (`backup-darwin.nix`)
Runs a restic backup daily at 14:00 using `StartCalendarInterval`:
```nix
launchd.agents.backup-home = {
  enable = true;
  config = {
    ProgramArguments = [ "''${backupHome}/bin/backup-home" ];
    StartCalendarInterval = [{ Hour = 14; Minute = 0; }];
    EnvironmentVariables.HOME = homeDir;
    StandardOutPath = "''${homeDir}/.local/log/backup-home-launchd.stdout.log";
    StandardErrorPath = "''${homeDir}/.local/log/backup-home-launchd.stderr.log";
  };
};
```

### Key launchd config options

| Key | Description | Example |
|-----|-------------|---------|
| `ProgramArguments` | Command to run (list of strings) | `[ "/usr/bin/env" "backup" ]` |
| `RunAtLoad` | Start when agent loads | `true` |
| `KeepAlive` | Restart if process exits | `true` |
| `StartCalendarInterval` | Cron-like schedule | `[{ Hour = 14; Minute = 0; }]` |
| `StartInterval` | Run every N seconds | `3600` |
| `WatchPaths` | Run when paths change | `[ "/some/path" ]` |
| `EnvironmentVariables` | Env vars for the process | `{ HOME = "/Users/me"; }` |
| `StandardOutPath` | Stdout log file | `"~/.local/log/out.log"` |
| `StandardErrorPath` | Stderr log file | `"~/.local/log/err.log"` |

Generated plists land in `~/Library/LaunchAgents/org.nix-community.home.<name>.plist`.

Useful commands:
```bash
launchctl list | grep nix-community          # list loaded agents
launchctl kickstart -k gui/$(id -u)/org.nix-community.home.<name>  # restart
launchctl print gui/$(id -u)/org.nix-community.home.<name>         # inspect
```
