{ lib, pkgs, ... }:
let
  apiHost = "127.0.0.1";
  apiPort = 3000;
  frontendPort = 3001;
  rfHostBlacklist = [
    "4vps.su"
    "Aeza Group"
    "Beget"
    "CDNvideo"
    "Delta"
    "EdgeCenter"
    "Miglovets Egor Andreevich"
    "russia"
    ".ru"
    "Selectel"
    "Timeweb"
    "VK"
    "Yandex"
  ];
  mkRemoteSub = name: displayName: url: {
    inherit name displayName url;
    source = "remote";
    ignoreFailedRemoteSub = true;
  };

  subscriptions = [
    (mkRemoteSub "black-vless-rus" "BLACK_VLESS_RUS"
      "https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_VLESS_RUS.txt"
    )
    (mkRemoteSub "vless-universal" "vless_universal"
      "https://raw.githubusercontent.com/zieng2/wl/main/vless_universal.txt"
    )
    (mkRemoteSub "black-ss-all-rus" "BLACK_SS+All_RUS"
      "https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_SS+All_RUS.txt"
    )
  ];

  collections = [
    {
      name = "ru-merged";
      displayName = "RU merged";
      subscriptions = [
        "black-vless-rus"
        "vless-universal"
        "black-ss-all-rus"
      ];
      ignoreFailedRemoteSub = true;
      process = [
        {
          type = "Script Filter";
          args = {
            mode = "code";
            content = ''
              const keywords = ${builtins.toJSON rfHostBlacklist}.map((v) =>
                String(v).toLowerCase()
              );
              const fields = [
                $server?.name,
                $server?.server,
                $server?.sni,
                $server?.servername,
                $server?.host,
                $server?.["ws-opts"]?.headers?.Host,
                $server?.["plugin-opts"]?.host,
              ];
              const haystack = fields
                .filter((v) => typeof v === "string" && v.length > 0)
                .join(" ")
                .toLowerCase();
              const isBlocked = keywords.some((k) => haystack.includes(k));
              return !isBlocked;
            '';
          };
        }
        {
          type = "Script Operator";
          args = {
            mode = "code";
            content = ''
              const isValidRealityShortId = (v) =>
                typeof v === "string" &&
                /^[0-9a-fA-F]+$/.test(v) &&
                v.length % 2 === 0;

              const normalize = (container, key) => {
                if (!container || typeof container !== "object") return;
                const v = container[key];
                if (typeof v !== "string") return;
                if (v.length === 0) return;
                if (!isValidRealityShortId(v)) {
                  delete container[key];
                }
              };

              normalize($server?.tls?.reality, "short_id");
              normalize($server?.["reality-opts"], "short-id");
              normalize($server?.["reality-opts"], "short_id");
            '';
          };
        }
        {
          type = "Script Operator";
          args = {
            mode = "code";
            content = ''
              const hasUDP = Object.prototype.hasOwnProperty.call($server ?? {}, "udp");
              if (!hasUDP) {
                $server.udp = true;
              }
            '';
          };
        }
        {
          type = "Handle Duplicate Operator";
          args = {
            action = "delete";
            field = [
              "type"
              "server"
              "port"
              "network"
              "uuid"
              "password"
              "cipher"
              "flow"
              "sni"
              "host"
              "path"
              "plugin"
              "plugin-opts.mode"
              "plugin-opts.host"
              "plugin-opts.path"
              "ws-opts.path"
              "ws-opts.headers.Host"
              "grpc-opts.grpc-service-name"
              "reality-opts.public-key"
              "reality-opts.short-id"
              "obfs"
              "obfs-password"
              "peer"
            ];
          };
        }
        {
          type = "Handle Duplicate Operator";
          args = {
            action = "rename";
            field = [ "name" ];
            link = " #";
            position = "back";
          };
        }
      ];
    }
  ];

  subscriptionsJson = pkgs.writeText "sub-store-subs.json" (builtins.toJSON subscriptions);
  collectionsJson = pkgs.writeText "sub-store-collections.json" (builtins.toJSON collections);
  curl = lib.getExe pkgs.curl;
in
{
  systemd.services.sub-store = {
    description = "Sub-Store backend";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    environment = {
      SUB_STORE_DATA_BASE_PATH = "/var/lib/sub-store";
      SUB_STORE_BACKEND_API_HOST = apiHost;
      SUB_STORE_BACKEND_API_PORT = toString apiPort;
      SUB_STORE_FRONTEND_PATH = toString pkgs.sub-store-frontend;
      SUB_STORE_FRONTEND_PORT = toString frontendPort;
      SUB_STORE_FRONTEND_BACKEND_PATH = "/";
    };
    serviceConfig = {
      StateDirectory = "sub-store";
      StateDirectoryMode = "0700";
      ExecStart = lib.getExe pkgs.sub-store;
      Restart = "on-failure";
      User = "root";
      Group = "root";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.sub-store-bootstrap = {
    description = "Seed Sub-Store subscriptions and collection";
    after = [ "sub-store.service" ];
    requires = [ "sub-store.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail

      api="http://${apiHost}:${toString apiPort}"
      attempt=0
      until ${curl} -fsS "$api/api/settings" >/dev/null; do
        attempt=$((attempt + 1))
        if [ "$attempt" -ge 60 ]; then
          echo "sub-store API did not become ready in time" >&2
          exit 1
        fi
        sleep 1
      done

      ${curl} -fsS -X PUT "$api/api/subs" \
        -H "Content-Type: application/json" \
        --data-binary "@${subscriptionsJson}" >/dev/null

      ${curl} -fsS -X PUT "$api/api/collections" \
        -H "Content-Type: application/json" \
        --data-binary "@${collectionsJson}" >/dev/null
    '';
  };

  systemd.services.sub-store-refresh-ru-merged = {
    description = "Refresh Sub-Store merged Mihomo output";
    wants = [ "network-online.target" ];
    after = [
      "sub-store.service"
      "sub-store-bootstrap.service"
      "network-online.target"
    ];
    requires = [ "sub-store.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      ${curl} -fsS "http://${apiHost}:${toString apiPort}/download/collection/ru-merged/Mihomo" >/dev/null
    '';
  };

  systemd.timers.sub-store-refresh-ru-merged = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "sub-store-refresh-ru-merged.service";
      OnBootSec = "5m";
      OnUnitActiveSec = "1h";
      Persistent = true;
      RandomizedDelaySec = "10m";
    };
  };
}
