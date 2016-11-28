{ nixpkgs ? <nixpkgs>, declInput ? {} }:

let
  pkgs = import nixpkgs {};
  defaultSettings = {
    enabled = true;
    hidden = true;
    description = "";
    input = "jobs";
    path = "default.nix";
    keep = 1;
    shares = 42;
    interval = 60;
    inputs = {
      jobs = {
        type = "git";
        value = "git://github.com/mayflower/hydra-jobs-azure";
      };
      nixpkgs = {
        type = "git";
        value = "git://github.com/mayflower/nixpkgs";
      };
      supportedSystems = {
        type = "nix";
        value = ''[ \"x86_64-linux\" ]'';
      };
    };
    mail = true;
    mailOverride = "devnull+hydra@mayflower.de";
  };
  jobsetsAttrs = with pkgs.lib; mapAttrs (name: settings: defaultSettings // settings) (rec {
    mayflower-azure = {
      path = "images.nix";
      inputs = defaultSettings.inputs // {
        nixpkgs = defaultSettings.inputs.nixpkgs // {
          value = "${defaultSettings.inputs.nixpkgs.value} azure_fixes";
        };
      };
      keep = 2;
    };
  });
  fileContents = with pkgs.lib; ''
    cat <<EOF
    ${builtins.toXML declInput}
    EOF
    cat > $out <<EOF
    {
      ${concatStringsSep "," (mapAttrsToList (name: settings: ''
        "${name}": {
            "enabled": ${if settings.enabled then "1" else "0"},
            "hidden": ${if settings.hidden then "true" else "false"},
            "description": "${settings.description}",
            "nixexprinput": "${settings.input}",
            "nixexprpath": "${settings.path}",
            "checkinterval": ${toString settings.interval},
            "schedulingshares": ${toString settings.shares},
            "enableemail": ${if settings.mail then "true" else "false"},
            "emailoverride": "${settings.mailOverride}",
            "keepnr": ${toString settings.keep},
            "inputs": {
              ${concatStringsSep "," (mapAttrsToList (inputName: inputSettings: ''
                "${inputName}": { "type": "${inputSettings.type}", "value": "${inputSettings.value}", "emailresponsible": false }
              '') settings.inputs)}
            }
        }
      '') jobsetsAttrs)}
    }
    EOF
  '';
in {
  jobsets = pkgs.runCommand "spec.json" {} fileContents;
}
