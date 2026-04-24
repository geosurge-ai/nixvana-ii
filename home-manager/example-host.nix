{ config, pkgs, ... }:

{
  # ── Replace these with your own values ─────────────────────────────
  home.username = builtins.getEnv "USER";
  home.homeDirectory = "/Users/${config.home.username}";
  home.stateVersion = "24.11";

  home.packages = [
    # Add your host-specific packages here:
    # pkgs.google-cloud-sdk
    # pkgs.rclone
    # pkgs.restic
  ];

  home.file = { };

  programs.home-manager.enable = true;
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.bash.shellAliases = {
    vim = "nvim";
  };

  programs.zsh.shellAliases = {
    vim = "nvim";
  };

  # Override backup defaults if needed:
  # services.backup-home.repo = "rclone:gdrive:backups/my-mac";
  # services.backup-home.passwordCommand = "pass show restic/backup";

  # ── mcmonad tiling window manager ──────────────────────────────────
  # i3/Sway-style tiling with tree splits, tabbed containers, sticky
  # windows, scratchpads, and directional focus. Option is the mod key.
  services.mcmonad = {
    enable = true;
    configFile = ''
      import MCMonad
      import MCMonad.Config.Keys
      import qualified Data.Map.Strict as Map
      import Data.Bits ((.|.))

      main :: IO ()
      main = mcmonad $ (withSway defaultConfig
          { terminal        = "/Applications/kitty.app/Contents/MacOS/kitty"
          , modMask         = optionMask
          , mcWorkspaces    = map show [1 :: Int .. 20] ++ ["NSP"]
          , focusFollowsMouse = False
          , mouseWarping    = False
          , borderWidth     = 0
          })
          { mcKeys = cstKeys }

      cstKeys :: MConfig Layout -> Map.Map (Modifiers, KeyCode) (M ())
      cstKeys conf = Map.fromList $
          -- Terminal
          [ ((m, kReturn),               modeAction "resize" exitMode
                                             (spawn (terminal conf)))
          -- Kill / restart
          , ((m .|. shiftMask, kQ),      kill)
          , ((m .|. shiftMask, kR),      restart)

          -- Focus / resize (mode-aware: h=left j=down k=up l=right)
          -- Resize works on both tiled (tree) and floating (scratchpad) windows
          , ((m, kH),                    modeAction "resize"
                                             (resizeOrFloat SplitH (-0.05))
                                             (focusDir DirLeft))
          , ((m, kJ),                    modeAction "resize"
                                             (resizeOrFloat SplitV 0.05)
                                             (focusDir DirDown))
          , ((m, kK),                    modeAction "resize"
                                             (resizeOrFloat SplitV (-0.05))
                                             (focusDir DirUp))
          , ((m, kL),                    modeAction "resize"
                                             (resizeOrFloat SplitH 0.05)
                                             (focusDir DirRight))
          -- Directional window movement (i3's move left/right/up/down)
          , ((m .|. shiftMask, kH),      moveDir DirLeft)
          , ((m .|. shiftMask, kJ),      moveDir DirDown)
          , ((m .|. shiftMask, kK),      moveDir DirUp)
          , ((m .|. shiftMask, kL),      moveDir DirRight)

          -- Resize mode (Mod+r toggles, Escape exits)
          , ((m, kR),                    modeAction "resize" exitMode
                                             (enterMode "resize"))
          , ((m, kEscape),               exitMode)

          -- i3/Sway tree operations
          , ((m, kB),                    sendMessage SetSplitH)
          , ((m, kV),                    sendMessage SetSplitV)
          , ((m, kT),                    sendMessage ToggleTabbed)
          , ((m, kA),                    sendMessage FocusParent)

          -- Fullscreen / floating / sticky
          , ((m, kF),                    withFocused $ \w -> do
                  ws <- gets windowset
                  if Map.member w (floating ws)
                      then windows (sink w)
                      else windows (float w (RationalRect 0 0 1 1)))
          , ((m, kSpace),                withFocused $ \w -> do
                  ws <- gets windowset
                  if Map.member w (floating ws)
                      then windows (sink w)
                      else windows (float w (RationalRect 0.1 0.1 0.8 0.8)))
          , ((m, kW),                    toggleSticky)

          -- Launcher (Spotlight)
          , ((m, kD),                    spawn "osascript -e 'tell application \"System Events\" to keystroke space using command down'")

          -- Scratchpads (quake-style)
          , ((0, kF12),                  toggleScratchpad "dropdown"
                                             (terminal conf))
          , ((m, kBackslash),            toggleScratchpad "notes"
                                             (terminal conf ++ " -e nvim ~/Notes"))

          -- Per-output / global workspace cycling
          , ((m, kComma),                cycleOnOutput Prev)
          , ((m, kSemicolon),            cycleOnOutput Next)
          , ((m .|. shiftMask, kComma),  cycleGlobal Prev)
          , ((m .|. shiftMask, kSemicolon), cycleGlobal Next)
          ]
          ++
          -- Workspaces 1-10
          [ ((m, key), affinityView ws)
          | (ws, key) <- zip wsNames numKeys ]
          ++
          [ ((m .|. shiftMask, key), affinityShift ws)
          | (ws, key) <- zip wsNames numKeys ]
          ++
          -- Workspaces 11-20 (Ctrl)
          [ ((m .|. controlMask, key), affinityView ws)
          | (ws, key) <- zip (drop 10 wsNames) numKeys ]
          ++
          [ ((m .|. shiftMask .|. controlMask, key), affinityShift ws)
          | (ws, key) <- zip (drop 10 wsNames) numKeys ]
        where
          m = modMask conf
          wsNames = mcWorkspaces conf
          numKeys = [k1, k2, k3, k4, k5, k6, k7, k8, k9, k0]
    '';
  };
}
