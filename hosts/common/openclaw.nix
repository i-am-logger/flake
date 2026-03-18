{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.local.openclaw;

  openclaw = pkgs.buildNpmPackage rec {
    pname = "openclaw";
    version = "2026.3.13";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/openclaw/-/openclaw-${version}.tgz";
      hash = "sha256-ZxHZ+MTxK9vc1QkOaGXi7hQbjNo+qo8gJZMEQGog6Wo=";
    };

    sourceRoot = "package";

    # Generate lockfile since npm tarball doesn't include one
    postPatch = ''
      cp ${./openclaw-package-lock.json} package-lock.json
    '';

    npmDepsHash = "sha256-XWDzeIUTv/N79w/Ij8Fdaj+xw84bi+HXB51sG8Jgwo8=";

    nodejs = pkgs.nodejs_22;
    makeCacheWritable = true;
    npmFlags = [
      "--legacy-peer-deps"
      "--ignore-scripts"
    ];
    dontNpmBuild = true; # Already pre-built in the npm tarball

    # Rebuild native addons after ignore-scripts install
    postInstall = ''
      cd $out/lib/node_modules/openclaw
      npm rebuild --ignore-scripts 2>/dev/null || true
      cd -
      mkdir -p $out/bin
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/openclaw \
        --add-flags "$out/lib/node_modules/openclaw/openclaw.mjs"
    '';

    nativeBuildInputs = with pkgs; [
      makeWrapper
      python3 # needed by some native npm modules (node-gyp)
    ];

    meta = {
      description = "Multi-channel personal AI assistant";
      mainProgram = "openclaw";
    };
  };

  # Generate openclaw.json from module options
  openclawConfig = builtins.toJSON (
    lib.recursiveUpdate (
      {
        gateway = {
          port = cfg.port;
          bind = cfg.bind;
          mode = "local";
          auth = {
            mode = "token";
            token = cfg.gatewayToken;
          };
        };
        models = {
          providers = {
            ollama = {
              baseUrl = cfg.ollamaUrl;
              models = [
                {
                  id = cfg.ollamaModel;
                  name = cfg.ollamaModel;
                }
              ];
            };
          };
        };
      }
      // lib.optionalAttrs cfg.signal.enable {
        channels = {
          signal =
            {
              account = cfg.signal.account;
              allowFrom = cfg.signal.allowFrom;
            }
            // lib.optionalAttrs (cfg.signal.allowFrom != [ ]) {
              defaultTo = builtins.head cfg.signal.allowFrom;
            };
        };
      }
    ) cfg.extraConfig
  );
in
{
  options.local.openclaw = {
    enable = lib.mkEnableOption "OpenClaw gateway";

    port = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "Gateway port";
    };

    bind = lib.mkOption {
      type = lib.types.enum [
        "loopback"
        "lan"
      ];
      default = "loopback";
      description = "Bind mode";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/openclaw";
      description = "State directory for OpenClaw config, sessions, credentials";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "User to run the gateway as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "Group to run the gateway as";
    };

    ollamaUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:11434";
      description = "Ollama API endpoint";
    };

    ollamaModel = lib.mkOption {
      type = lib.types.str;
      default = "qwen2.5:14b";
      description = "Default Ollama model for inference";
    };

    gatewayToken = lib.mkOption {
      type = lib.types.str;
      default = "openclaw-local-token";
      description = "Gateway auth token (shared between service and CLI users)";
    };

    signal = {
      enable = lib.mkEnableOption "Signal channel";

      account = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Signal phone number (E.164 format, e.g. +1234567890)";
      };

      allowFrom = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Phone numbers allowed to message (E.164 format)";
      };
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional openclaw.json configuration (merged with generated config)";
    };
  };

  config = lib.mkIf cfg.enable {
    # System user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.stateDir;
    };

    users.groups.${cfg.group} = { };

    # Make openclaw CLI available system-wide
    environment.systemPackages = [ openclaw ];

    # Create /etc/openclaw-client.json readable by all users for CLI gateway access
    environment.etc."openclaw-client.json" = {
      text = builtins.toJSON {
        gateway = {
          port = cfg.port;
          bind = cfg.bind;
          auth = {
            mode = "token";
            token = cfg.gatewayToken;
          };
        };
        models = {
          providers = {
            ollama = {
              baseUrl = cfg.ollamaUrl;
              models = [
                {
                  id = cfg.ollamaModel;
                  name = cfg.ollamaModel;
                }
              ];
            };
          };
        };
      };
      mode = "0644";
    };

    # Point CLI to the shared config
    environment.variables = {
      OPENCLAW_CONFIG_PATH = "/etc/openclaw-client.json";
    };

    # Ensure state directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.stateDir}/credentials 0700 ${cfg.user} ${cfg.group} -"
      "d ${cfg.stateDir}/sessions 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.stateDir}/state 0750 ${cfg.user} ${cfg.group} -"
    ];

    # OpenClaw gateway systemd service
    systemd.services.openclaw-gateway = {
      description = "OpenClaw Gateway";
      after = [
        "network-online.target"
        "ollama.service"
      ];
      wants = [
        "network-online.target"
        "ollama.service"
      ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        NODE_ENV = "production";
        OPENCLAW_STATE_DIR = cfg.stateDir;
        OPENCLAW_CONFIG_PATH = "${cfg.stateDir}/openclaw.json";
        OPENCLAW_NIX_MODE = "1";
        HOME = cfg.stateDir;
      };

      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "openclaw-config" ''
          cat > "${cfg.stateDir}/openclaw.json" <<'CONFIGEOF'
          ${openclawConfig}
          CONFIGEOF
        '';

        ExecStart = ''
          ${openclaw}/bin/openclaw gateway run \
            --bind ${cfg.bind} \
            --port ${toString cfg.port} \
            --token ${cfg.gatewayToken} \
            --allow-unconfigured
        '';

        # Provide lsof/fuser in PATH for port management
        path = [ pkgs.lsof pkgs.psmisc ];

        Restart = "always";
        RestartSec = 5;
        TimeoutStopSec = 30;
        TimeoutStartSec = 60;
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.stateDir;
        StateDirectory = "openclaw";

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.stateDir ];
        PrivateTmp = true;
      };
    };
  };
}
