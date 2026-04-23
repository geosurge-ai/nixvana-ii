{ pkgs, config, lib, hostname, ... }:

let
  cfg = config.services.backup-home;
  homeDir = config.home.homeDirectory;

  # Change this to your preferred password retrieval command.
  # Examples:
  #   "security find-generic-password -a restic -s backup -w"  (macOS Keychain)
  #   "pass show restic/backup"                                (pass)
  #   "op read op://Vault/restic-backup/password"              (1Password CLI)
  #   "cat /path/to/password-file"                             (plain file — not recommended)
  passwordCommand = cfg.passwordCommand;

  excludeFile = pkgs.writeText "restic-home-excludes" ''
    # macOS junk
    ${homeDir}/.Trash
    .DS_Store
    .zcompdump*
    ${homeDir}/.CFUserTextEncoding
    ${homeDir}/.zsh_sessions

    # Caches
    ${homeDir}/.cache
    ${homeDir}/Library/Caches
    ${homeDir}/Library/Logs
    ${homeDir}/Library/HTTPStorages
    ${homeDir}/Library/WebKit

    # Library: large regenerable app data
    ${homeDir}/Library/Developer
    ${homeDir}/Library/Containers/com.utmapp.UTM
    ${homeDir}/Library/Containers/com.docker.docker
    ${homeDir}/Library/Application Support/Google
    ${homeDir}/Library/Application Support/Spotify
    ${homeDir}/Library/Application Support/Chromium
    ${homeDir}/Library/Application Support/Slack

    # macOS SIP/TCC-protected directories (inaccessible without FDA)
    ${homeDir}/Library/Group Containers/group.com.apple.*
    ${homeDir}/Library/HomeKit
    ${homeDir}/Library/IdentityServices
    ${homeDir}/Library/Mail
    ${homeDir}/Library/Messages
    ${homeDir}/Library/Metadata/CoreSpotlight
    ${homeDir}/Library/Mobile Documents
    ${homeDir}/Library/Safari

    # Package manager / build caches
    ${homeDir}/.cargo/registry
    ${homeDir}/.npm
    ${homeDir}/go/pkg

    # Build artifacts (match anywhere in tree)
    node_modules
    target/debug
    target/release
    .direnv
    __pycache__
    *.pyc
    *.o

    # Nix build outputs
    result
  '';

  backupHome = pkgs.writeShellApplication {
    name = "backup-home";
    runtimeInputs = [ pkgs.restic pkgs.rclone pkgs.coreutils ];
    text = ''
      export RESTIC_REPOSITORY="${cfg.repo}"
      export RESTIC_PASSWORD_COMMAND="${passwordCommand}"

      LOG="${homeDir}/.local/log/backup-home-$(date +%Y-%m-%d_%H%M%S).log"
      mkdir -p "$(dirname "$LOG")"

      echo "=== backup-home started: $(date) ===" | tee -a "$LOG"
      echo "    repo: ${cfg.repo}" | tee -a "$LOG"

      # Bail if another backup is already running
      if restic list locks --no-lock 2>/dev/null | grep -q .; then
        echo "FATAL: restic repo is locked — another backup is still running." | tee -a "$LOG" >&2
        exit 1
      fi

      # Auto-init on first run
      if ! restic snapshots --quiet >/dev/null 2>&1; then
        echo "Initializing restic repository..." | tee -a "$LOG"
        restic init 2>&1 | tee -a "$LOG"
      fi

      restic backup "${homeDir}/" \
        --exclude-file "${excludeFile}" \
        --verbose=2 2>&1 | tee -a "$LOG"

      # Retention: 7 daily, 4 weekly, 12 monthly, 3 yearly
      restic forget \
        --keep-daily 7 \
        --keep-weekly 4 \
        --keep-monthly 12 \
        --keep-yearly 3 \
        --prune 2>&1 | tee -a "$LOG"

      echo "=== backup-home complete: $(date) ===" | tee -a "$LOG"
    '';
  };

in
{
  options.services.backup-home = {
    repo = lib.mkOption {
      type = lib.types.str;
      default = "rclone:gdrive:backups/${hostname}";
      description = "Restic repository URL. Defaults to per-hostname path on Google Drive via rclone.";
    };
    passwordCommand = lib.mkOption {
      type = lib.types.str;
      default = "security find-generic-password -a restic -s backup -w";
      description = "Command that prints the restic repository password to stdout.";
    };
  };

  config = {
    home.packages = [
      pkgs.rclone
      pkgs.restic
      backupHome
    ];

    # ┌──────────────────────────────────────────────────────────────────┐
    # │  LAUNCHD EXAMPLE: Scheduled daily backup                       │
    # │                                                                  │
    # │  This demonstrates StartCalendarInterval — the launchd          │
    # │  equivalent of a cron job. The agent runs daily at 14:00.      │
    # │                                                                  │
    # │  Available calendar keys:                                       │
    # │    Month (1-12), Day (1-31), Weekday (0=Sun..6=Sat),           │
    # │    Hour (0-23), Minute (0-59)                                   │
    # │                                                                  │
    # │  Omitting a key means "any" (like * in cron). Examples:        │
    # │    [{ Hour = 14; Minute = 0; }]           — daily at 14:00     │
    # │    [{ Weekday = 1; Hour = 9; Minute = 0; }] — Mon 09:00       │
    # │    [{ Minute = 30; }]                     — every hour at :30  │
    # │                                                                  │
    # │  Other useful scheduling options (not used here):              │
    # │    StartInterval = 3600;   — run every 3600 seconds            │
    # │    WatchPaths = [ "/some/path" ];  — run when path changes     │
    # │                                                                  │
    # │  Log files go to ~/.local/log/ for easy inspection:            │
    # │    tail -f ~/.local/log/backup-home-launchd.stdout.log         │
    # └──────────────────────────────────────────────────────────────────┘
    launchd.agents.backup-home = {
      enable = true;
      config = {
        ProgramArguments = [ "${backupHome}/bin/backup-home" ];
        StartCalendarInterval = [{ Hour = 14; Minute = 0; }];
        EnvironmentVariables = {
          HOME = homeDir;
        };
        StandardOutPath = "${homeDir}/.local/log/backup-home-launchd.stdout.log";
        StandardErrorPath = "${homeDir}/.local/log/backup-home-launchd.stderr.log";
      };
    };
  };
}
