{
  self,
  ...
}:

{
  flake.nixosModules.akplanning =
    {
      lib,
      config,
      pkgs,
      ...
    }:

    let
      inherit (lib)
        mkOption
        mkEnableOption
        mkPackageOption
        mkIf
        types
        ;

      pythonFmt = pkgs.formats.pythonVars { };
    in
    {
      options.die-koma.akplanning = {
        enable = mkEnableOption "configure the AKPlanning tool";

        package = mkPackageOption self.packages."${pkgs.stdenv.hostPlatform.system}" "akplanning" { };

        hostName = mkOption {
          description = "Hostname for the AKPlanning tool";
          type = types.str;
          default = "aks.die-koma.org";
        };

        extraHostNames = mkOption {
          description = "Additional hostnames to set up as aliases for the AKPlanning tool";
          type = types.listOf (types.str);
          default = [ ];
        };

        db = mkOption {
          description = "Database settings for the AKPlanning tool";
          type = types.submodule {
            options = {
              database = mkOption {
                description = "MariaDB database for the AKPlanning tool";
                type = types.str;
                default = "akplanning";
              };

              username = mkOption {
                description = "MariaDB username for the AKPlanning tool";
                type = types.str;
                default = "akplanning";
              };
            };
          };
          default = { };
        };

        nginx = mkEnableOption "configure an nginx VirtualHost for the AKPlanning tool";

        useACMEHost = mkOption {
          description = "Hostname to use for obtaining SSL certificates";
          type = types.str;
          default = config.networking.fqdn;
        };

        settings = lib.mkOption {
          description = ''
            Configuration options to set in `settings.py`.
          '';

          default = { };

          type = lib.types.submodule {
            freeformType = pythonFmt.type;

            options = {
            };
          };
        };
      };

      config =
        let
          cfg = config.die-koma.akplanning;
          dataDir = "/data/akplanning";

          settingsFile =
            let
              inherit (pythonFmt.lib) mkRaw;
            in
            pythonFmt.generate "akplanning_settings.py" (
              {
                _imports = [ "os" ];

                STATIC_ROOT = "${dataDir}/static";
                STATICFILES_DIRS = mkRaw ''
                  (BASE_DIR + "/static_common",)
                '';

                ALLOWED_HOSTS = [ cfg.hostName ] ++ cfg.extraHostNames;
                DEBUG = false;

                SESSION_COOKIE_SECURE = true;
                CSRF_COOKIE_SECURE = true;

                DATABASES.default = {
                  ENGINE = "django.db.backends.mysql";
                  HOST = "localhost";
                  NAME = cfg.db.database;
                  USER = cfg.db.username;
                  PASSWORD = mkRaw ''
                    open(os.getenv("AKPLANNING_DATABASE_PASSWORD")).read()
                  '';
                  OPTIONS.init_command = "SET sql_mode='STRICT_TRANS_TABLES'";
                };

                SEND_MAILS = true;
                EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend";

                SECRET_KEY = mkRaw ''
                  open(os.getenv("AKPLANNING_SECRET_KEY")).read()
                '';

                LOGGING = {
                  version = 1;
                  disable_existing_loggers = false;
                  handlers.console = {
                    level = "DEBUG";
                    class = "logging.StreamHandler";
                  };
                  root = {
                    handlers = [ "console" ];
                    level = "DEBUG";
                  };
                };
              }
              // cfg.settings
            );
          settingsPath = pkgs.stdenv.mkDerivation {
            pname = "akplanning-settings";
            version = "0";
            dontUnpack = true;
            dontBuild = true;
            installPhase = ''
              runHook preInstall
              mkdir $out
              echo "from AKPlanning.settings import *" > $out/akplanning_settings.py
              cat ${settingsFile} >> $out/akplanning_settings.py
              runHook postInstall
            '';
          };

          iniFmt = pkgs.formats.ini { listsAsDuplicateKeys = true; };

          uwsgIni = iniFmt.generate "uwsgi-akplanning.ini" {
            uwsgi = {
              plugin = "python3";
              socket = "/run/akplanning/akplanning.socket";
              chmod-socket = 660;
              chdir = dataDir;
              wsgi-file = "${cfg.package}/lib/akplanning/AKPlanning/wsgi.py";
              touch-reload = "%(wsgi-file)";
              env = [
                "DJANGO_SETTINGS_MODULE=akplanning_settings"
                "AKPLANNING_SECRET_KEY=/run/secrets/akplanning-secret-key"
                "AKPLANNING_DATABASE_PASSWORD=/run/secrets/akplanning-database-password"
              ];
              processes = 4;
              threads = 2;
              uid = "akplanning";
              gid = "akplanning";
            };
          };

          wrapper = pkgs.writeShellApplication {
            name = "akplanning";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              SUDO="exec"
              if [[ "$USER" != akplanning ]]; then
                SUDO="exec /run/wrappers/bin/sudo -u akplanning"
              fi
              $SUDO env \
                DJANGO_SETTINGS_MODULE="akplanning_settings" \
                AKPLANNING_SECRET_KEY="/run/secrets/akplanning-secret-key" \
                AKPLANNING_DATABASE_PASSWORD="/run/secrets/akplanning-database-password" \
                PYTHONPATH="${cfg.package.pythonPath}:${cfg.package}/lib/akplanning/:${settingsPath}:${cfg.package.python}/${cfg.package.python.sitePackages}" \
                ${lib.getExe cfg.package} "$@"
            '';
          };

        in
        {
          services = {
            mysql = {
              ensureDatabases = [ "akplanning" ];
              ensureUsers = [
                {
                  name = "akplanning";
                  ensurePermissions = {
                    "akplanning.*" = "ALL PRIVILEGES";
                  };
                }
              ];
            };

            nginx.virtualHosts = mkIf cfg.nginx {
              "${cfg.hostName}" = {
                inherit (cfg) useACMEHost;
                forceSSL = true;
                serverAliases = cfg.extraHostNames;

                locations = {
                  "/" = {
                    recommendedUwsgiSettings = true;
                    uwsgiPass = "unix:///run/akplanning/akplanning.socket";
                  };

                  "^~ /static/" = {
                    alias = "${dataDir}/static/";
                    extraConfig = "allow all;";
                  };
                };
              };
            };
          };

          systemd = {
            services.akplanning = {
              description = "AK planning tool";
              serviceConfig = {
                # TODO: check if these are appropriate
                ReadWritePaths = [ dataDir ];
                CacheDirectory = "akplanning";
                CapabilityBoundingSet = "";
                # ProtectClock adds DeviceAllow=char-rtc r
                DeviceAllow = "";
                LockPersonality = true;
                MemoryDenyWriteExecute = true;
                NoNewPrivileges = true;
                PrivateDevices = true;
                PrivateMounts = true;
                PrivateTmp = true;
                PrivateUsers = true;
                ProtectClock = true;
                ProtectHome = true;
                ProtectHostname = true;
                ProtectSystem = "strict";
                ProtectControlGroups = true;
                ProtectKernelLogs = true;
                ProtectKernelModules = true;
                ProtectKernelTunables = true;
                ProtectProc = "invisible";
                ProcSubset = "pid";
                RestrictAddressFamilies = [
                  "AF_UNIX"
                  "AF_INET"
                  "AF_INET6"
                ];
                RestrictNamespaces = true;
                RestrictRealtime = true;
                RestrictSUIDSGID = true;
                SystemCallArchitectures = "native";
                SystemCallFilter = [
                  "@system-service"
                  "~@privileged @setuid @keyring"
                ];
                UMask = "0066";

                WorkingDirectory = dataDir;
                User = "akplanning";
                Group = "akplanning";
                TimeoutStartSec = "5m";
              };

              after = [
                "mysql.service"
                "network.target"
              ];
              wantedBy = [ "multi-user.target" ];
              environment = {
                DJANGO_SETTINGS_MODULE = "akplanning_settings";
                AKPLANNING_SECRET_KEY = "/run/secrets/akplanning-secret-key";
                AKPLANNING_DATABASE_PASSWORD = "/run/secrets/akplanning-database-password";
                PYTHONPATH = "${cfg.package.pythonPath}:${cfg.package}/lib/akplanning/:${settingsPath}:${cfg.package.python}/${cfg.package.python.sitePackages}";
              };
              script =
                let
                  uwsgi = pkgs.uwsgi.override { plugins = [ "python3" ]; };
                in
                ''
                  ${lib.getExe uwsgi} \
                    --ini ${uwsgIni} \
                    --log-4xx \
                    --log-5xx \
                    --log-zero
                '';
              preStart = ''
                ${lib.getExe cfg.package} migrate --no-input
                ${lib.getExe cfg.package} collectstatic --no-input --clear
              '';
            };

            tmpfiles.rules = [ "d /run/akplanning - akplanning akplanning - -" ];
          };

          environment.systemPackages = [ wrapper ];

          users = {
            users = {
              akplanning = {
                home = dataDir;
                homeMode = "0750";
                createHome = true;
                isSystemUser = true;
                group = "akplanning";
              };
              nginx = mkIf cfg.nginx { extraGroups = [ "akplanning" ]; };
            };
            groups.akplanning = { };
          };
        };
    };
}
