{ lib, ... }:

let
  capsLockToF18 = ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":30064771129,"HIDKeyboardModifierMappingDst":30064771181}]}'';
in
{
  targets.darwin.defaults = {
    NSGlobalDomain.TISRomanSwitchState = 0;

    "com.apple.HIToolbox".AppleEnabledInputSources = [
      {
        InputSourceKind = "Keyboard Layout";
        "KeyboardLayout ID" = 252;
        "KeyboardLayout Name" = "ABC";
      }
      {
        "Bundle ID" = "com.apple.CharacterPaletteIM";
        InputSourceKind = "Non Keyboard Input Method";
      }
      {
        "Bundle ID" = "com.apple.inputmethod.ironwood";
        InputSourceKind = "Non Keyboard Input Method";
      }
      {
        InputSourceKind = "Keyboard Layout";
        "KeyboardLayout ID" = -2354;
        "KeyboardLayout Name" = "Ukrainian-PC";
      }
    ];

  };

  home.activation.activateInputSettings = lib.hm.dag.entryAfter [ "setDarwinDefaults" ] ''
    run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 \
      '<dict><key>enabled</key><false/></dict>'
    run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 \
      '<dict><key>enabled</key><true/><key>value</key><dict><key>type</key><string>standard</string><key>parameters</key><array><integer>65535</integer><integer>79</integer><integer>0</integer></array></dict></dict>'
    run /usr/bin/hidutil property --set '${capsLockToF18}'
    run /usr/bin/defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys > /dev/null
    run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  # hidutil mappings are reset by macOS at reboot, so reapply at GUI login.
  launchd.agents.caps-lock-input-source = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/hidutil"
        "property"
        "--set"
        capsLockToF18
      ];
      RunAtLoad = true;
    };
  };
}
