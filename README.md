# nixvana-ii

Generic, corporate-friendly macOS configuration using Nix, home-manager, and nix-darwin.
Adaptable by anyone -- no personal secrets, no private inputs.

## Prerequisites

- **Nix** via the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer) (provides flakes and nix-command out of the box)
- **Homebrew** for GUI apps that need cask installation (Karabiner, AeroSpace, etc.)

## Repository structure

```
flake.nix                       Dev shell (nixfmt, nixd)
home-manager/
  flake.nix                     Home-manager flake for macOS hosts
  darwin.nix                    Base darwin config (imports all includes)
  example-host.nix              Host-specific config template
  include/
    cli-darwin.nix              CLI packages
    shells.nix                  Zsh, Bash, Starship, fzf (hostname-colored prompt)
    programming/nix.nix         Nix dev tools
    services/
      gpg.nix                   Linux GPG agent (conditional)
      gpg-darwin.nix            macOS GPG agent via launchd
      backup-darwin.nix         Scheduled restic backup via launchd
nix-darwin/
  flake.nix                     nix-darwin system flake (openssh, direnv, hostname)
imperative-darwin/
  README.md                     Fresh Mac setup guide
  Brewfile                      Homebrew cask apps
  bin/macos-defaults            System defaults script (keyboard, dock, F-keys)
  configs/                      Karabiner, AeroSpace, Ghostty, LinearMouse
```

## Quick start

```bash
# 1. Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Imperative setup (homebrew, GUI apps, system defaults)
#    See imperative-darwin/README.md for full steps

# 3. Apply home-manager config
cd home-manager
# Edit example-host.nix with your username and home directory, then:
home-manager switch --flake .#my-mac

# 4. (Optional) Apply nix-darwin system config
cd nix-darwin
# Edit flake.nix with your hostname and username, then:
darwin-rebuild switch --flake .#my-mac
```

## Using home-manager to run launchd agents

home-manager exposes `launchd.agents.<name>` which generates a macOS
LaunchAgent plist and loads it via `launchctl`. This repo includes two
working examples in `home-manager/include/services/`:

### GPG agent at login (`gpg-darwin.nix`)

Starts `gpg-agent` when you log in using `RunAtLoad`:

```nix
launchd.agents.gpg-agent-start = {
  enable = true;
  config = {
    ProgramArguments = [ "${gpg}/bin/gpgconf" "--launch" "gpg-agent" ];
    EnvironmentVariables.GNUPGHOME = "${config.home.homeDirectory}/.gnupg";
    RunAtLoad = true;
  };
};
```

### Scheduled daily backup (`backup-darwin.nix`)

Backs up your home directory to a restic repository daily at 14:00 via a
launchd calendar trigger. The module is designed to be pluggable:

- **`services.backup-home.repo`** -- restic repository URL. Defaults to
  `rclone:gdrive:backups/<hostname>` (Google Drive via rclone, per-hostname
  path to prevent cross-machine stomping). Set this to any restic-supported
  backend: local path, S3, SFTP, etc.
- **`services.backup-home.passwordCommand`** -- command that prints the restic
  password to stdout. Defaults to macOS Keychain
  (`security find-generic-password -a restic -s backup -w`). Swap in your
  preferred secret manager:
  - `"pass show restic/backup"` (pass/password-store)
  - `"op read op://Vault/restic-backup/password"` (1Password CLI)
  - `"gpg --quiet --decrypt /path/to/password.gpg"` (GPG-encrypted file)

The backup script auto-initializes the repo on first run, skips if a lock
is held, and applies retention (7 daily, 4 weekly, 12 monthly, 3 yearly).
Logs go to `~/.local/log/backup-home-*.log`.

Override in your host config:
```nix
services.backup-home.repo = "s3:s3.amazonaws.com/my-backups";
services.backup-home.passwordCommand = "pass show restic/backup";
```

The launchd agent that drives it:
```nix
launchd.agents.backup-home = {
  enable = true;
  config = {
    ProgramArguments = [ "${backupHome}/bin/backup-home" ];
    StartCalendarInterval = [{ Hour = 14; Minute = 0; }];
    EnvironmentVariables.HOME = homeDir;
    StandardOutPath = "${homeDir}/.local/log/backup-home-launchd.stdout.log";
    StandardErrorPath = "${homeDir}/.local/log/backup-home-launchd.stderr.log";
  };
};
```

### launchd config reference

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
launchctl list | grep nix-community                                            # list loaded agents
launchctl kickstart -k gui/$(id -u)/org.nix-community.home.<name>             # restart
launchctl print gui/$(id -u)/org.nix-community.home.<name>                    # inspect
```
