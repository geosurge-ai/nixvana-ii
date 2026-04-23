{
  pkgs,
  lib,
  config,
  hostname,
  ...
}:

let
  inherit (lib) mkDefault mod;
  inherit (lib.strings) toLower;

  hexCharToInt =
    c:
    let
      lowerC = toLower c;
    in
    if lowerC == "0" then 0
    else if lowerC == "1" then 1
    else if lowerC == "2" then 2
    else if lowerC == "3" then 3
    else if lowerC == "4" then 4
    else if lowerC == "5" then 5
    else if lowerC == "6" then 6
    else if lowerC == "7" then 7
    else if lowerC == "8" then 8
    else if lowerC == "9" then 9
    else if lowerC == "a" then 10
    else if lowerC == "b" then 11
    else if lowerC == "c" then 12
    else if lowerC == "d" then 13
    else if lowerC == "e" then 14
    else if lowerC == "f" then 15
    else abort "Invalid hex character: ${c}";

  ensureBright =
    code:
    let
      idx = code - 16;
      r = (mod (idx / 36) 6);
      g = (mod (idx / 6) 6);
      b = (mod idx 6);
    in
    if (r + g + b) <= 2 then (mod (code + 36) 216) + 16 else code;

  generateColor =
    name:
    let
      raw = parseHex (builtins.substring 0 2 (builtins.hashString "md5" name));
      cube = (mod raw 216) + 16;
    in
    ensureBright cube;

  parseHex =
    str:
    let
      c1 = hexCharToInt (builtins.substring 0 1 str);
      c2 = hexCharToInt (builtins.substring 1 1 str);
    in
    c1 * 16 + c2;

  hostHash = builtins.hashString "md5" hostname;

  autoUserColor = generateColor (builtins.substring 0 2 hostHash);
  autoAtColor = generateColor (builtins.substring 10 2 hostHash);
  autoHostColor = generateColor (builtins.substring 0 2 hostHash);
  autoPathColor = generateColor (builtins.substring 8 2 hostHash);
  autoGitColor = generateColor (builtins.substring 6 2 hostHash);
  autoTimeColor = generateColor (builtins.substring 8 2 hostHash);
  autoLambdaColor = generateColor (builtins.substring 8 2 hostHash);

  cfg = config.programs.shell-prompt;

  userColor = cfg.userColor;
  atColor = cfg.atColor;
  hostColor = cfg.hostColor;
  pathColor = cfg.pathColor;
  gitColor = cfg.gitColor;
  timeColor = cfg.timeColor;
  lambdaColor = cfg.lambdaColor;

  hostParts = lib.splitString "." hostname;
  abbreviatedHost =
    if builtins.length hostParts > 1
    then (builtins.substring 0 1 (builtins.head hostParts)) + "." + (lib.concatStringsSep "." (lib.tail hostParts))
    else builtins.substring 0 1 hostname;
  abbreviatedUser = builtins.substring 0 1 config.home.username;

  promptUser = if cfg.abbreviate then abbreviatedUser else config.home.username;
  promptHost = if cfg.abbreviate then abbreviatedHost else hostname;

in
{
  options.programs.shell-prompt = {
    userColor   = lib.mkOption { type = lib.types.int; default = autoUserColor;   description = "256-color code for username"; };
    atColor     = lib.mkOption { type = lib.types.int; default = autoAtColor;     description = "256-color code for @ symbol"; };
    hostColor   = lib.mkOption { type = lib.types.int; default = autoHostColor;   description = "256-color code for hostname"; };
    pathColor   = lib.mkOption { type = lib.types.int; default = autoPathColor;   description = "256-color code for path"; };
    gitColor    = lib.mkOption { type = lib.types.int; default = autoGitColor;    description = "256-color code for git branch"; };
    timeColor   = lib.mkOption { type = lib.types.int; default = autoTimeColor;   description = "256-color code for timestamp"; };
    lambdaColor = lib.mkOption { type = lib.types.int; default = autoLambdaColor; description = "256-color code for lambda prompt"; };
    abbreviate  = lib.mkOption { type = lib.types.bool; default = false; description = "Abbreviate user@host for screencast safety"; };
  };

  config = {

  home.packages = [
    pkgs.fd
  ];

  programs.bash.enable = true;
  programs.bash.enableCompletion = true;

  programs.bash.bashrcExtra = ''
    user_color="\$(tput setaf ${builtins.toString userColor})"
    at_color="\$(tput setaf ${builtins.toString atColor})"
    host_color="\$(tput setaf ${builtins.toString hostColor})"
    path_color="\$(tput setaf ${builtins.toString pathColor})"
    git_color="\$(tput setaf ${builtins.toString gitColor})"
    time_color="\$(tput setaf ${builtins.toString timeColor})"
    lambda_color="\$(tput setaf ${builtins.toString lambdaColor})"
    reset_color="\$(tput sgr0)"

    ps1_date="\[\$(tput bold)\]\[''${time_color}\]\$(date +'%a %b %d %H:%M:%S:%N')"
    ps1_user="\[''${user_color}\]\u"
    ps1_at="\[''${at_color}\]@"
    ps1_host="\[''${host_color}\]\h"
    ps1_path="\[''${path_color}\]\w"
    ps1_lambda="\[''${lambda_color}\]λ\[$reset_color\]"

    git_prompt() {
      local ref
      ref="$(git symbolic-ref -q HEAD 2>/dev/null)"
      if [ -n "$ref" ]; then
        echo "(''${ref#refs/heads/}) "
      fi
    }

    export PS1="''${ps1_date} ''${ps1_user}''${ps1_at}''${ps1_host} ''${ps1_path} \$(git_prompt)\n''${ps1_lambda} "

    export GPG_TTY="$(tty)"
    set -o vi

    if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi
  '';

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = false;

    settings = {
      hostname = {
        ssh_only = false;
        format = "[$hostname]($style)";
        style = "bold fg:${toString hostColor}";
      };
      username = {
        show_always = true;
        style_user = "bold fg:${toString userColor}";
      };
      directory = {
        read_only = " ";
        fish_style_pwd_dir_length = 20;
        truncation_length = 10;
        style = "fg:${toString pathColor}";
      };
      git_branch.style = "fg:${toString gitColor}";
      time.style = "fg:${toString timeColor}";
      character = {
        success_symbol = "[λ](fg:${toString lambdaColor})";
        error_symbol = "[λ](fg:${toString lambdaColor})";
        vicmd_symbol = "[λ](fg:${toString lambdaColor})";
      };
      aws.format = mkDefault "[$symbol($region)]($style) ";
      gcloud.format = mkDefault "[$symbol$project]($style) ";

      aws.symbol = mkDefault " ";
      git_branch.symbol = mkDefault " ";
      git_commit.tag_symbol = mkDefault " ";
      git_status.format = mkDefault "([$all_status$ahead_behind]($style) )";
      golang.symbol = mkDefault " ";
      nix_shell.symbol = mkDefault " ";
      nodejs.symbol = mkDefault " ";
      package.symbol = mkDefault " ";
      python.symbol = mkDefault " ";
      ruby.symbol = mkDefault " ";
      rust.symbol = mkDefault " ";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = false;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "docker-compose"
        "docker"
        "git"
        "tmux"
        "fzf"
      ];
      theme = "dst";
    };
    shellAliases = { };
    sessionVariables = {
      ZSH_THEME = "spaceship";
    };
    initContent = ''
      source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh;
      bindkey '^f' autosuggest-accept;
      bindkey -v

      if [[ "$TERM" == "dumb" ]]
      then
        unsetopt zle
        unsetopt prompt_cr
        unsetopt prompt_subst
        if whence -w precmd >/dev/null; then
            unfunction precmd
        fi
        if whence -w preexec >/dev/null; then
            unfunction preexec
        fi
        PS1='$ '
      fi

      if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi
    '';
  };

  programs.ripgrep.enable = true;
  };
}
