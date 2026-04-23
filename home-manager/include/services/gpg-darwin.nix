{ pkgs, config, ... }:

let
  gpg = pkgs.gnupg;
  pinentry = pkgs.pinentry_mac;
in
{
  # Single source of truth for GPG toolchain on Darwin.
  # Do not declare gnupg or pinentry in cli-darwin.nix or elsewhere —
  # keeping it here ensures the agent binary, CLI binary, and pinentry
  # all come from the same package.
  home.packages = [
    gpg
    pinentry
  ];

  home.file.".gnupg/gpg-agent.conf".text = ''
    grab
    pinentry-program ${pinentry}/bin/pinentry-mac
  '';

  # ┌──────────────────────────────────────────────────────────────────┐
  # │  LAUNCHD EXAMPLE: GPG agent at login                            │
  # │                                                                  │
  # │  home-manager exposes `launchd.agents.<name>` which generates   │
  # │  a macOS LaunchAgent plist and loads it via `launchctl`.        │
  # │                                                                  │
  # │  Key config keys:                                                │
  # │    ProgramArguments  — the command to run (list of strings)      │
  # │    RunAtLoad         — start immediately when the agent loads    │
  # │    KeepAlive         — restart if it exits (not used here;      │
  # │                        gpg-agent forks into background)          │
  # │    EnvironmentVariables — env vars for the launched process      │
  # │    StartCalendarInterval — cron-like scheduling (see backup)     │
  # │    StandardOutPath / StandardErrorPath — log file paths          │
  # │                                                                  │
  # │  The generated plist lands in:                                   │
  # │    ~/Library/LaunchAgents/org.nix-community.home.gpg-agent-start.plist │
  # │                                                                  │
  # │  Useful commands:                                                │
  # │    launchctl list | grep nix-community  — see loaded agents     │
  # │    launchctl kickstart -k gui/$(id -u)/org.nix-community.home.gpg-agent-start │
  # │    launchctl print gui/$(id -u)/org.nix-community.home.gpg-agent-start        │
  # └──────────────────────────────────────────────────────────────────┘
  launchd.agents.gpg-agent-start = {
    enable = true;
    config = {
      ProgramArguments = [
        "${gpg}/bin/gpgconf"
        "--launch"
        "gpg-agent"
      ];
      EnvironmentVariables.GNUPGHOME = "${config.home.homeDirectory}/.gnupg";
      RunAtLoad = true;
    };
  };
}
