{ lib, pkgs, ... }:
let
  apiHost = "127.0.0.1";
  apiPort = 3000;
  frontendPort = 3001;

  geminiSupportedCountries = map lib.strings.trim (
    builtins.filter (x: x != "") (
      lib.splitString "\n" ''
        Albania
        Algeria
        American Samoa
        Andorra
        Angola
        Anguilla
        Antarctica
        Antigua and Barbuda
        Argentina
        Armenia
        Aruba
        Australia
        Austria
        Azerbaijan
        The Bahamas
        Bahrain
        Bangladesh
        Barbados
        Belgium
        Belize
        Benin
        Bermuda
        Bhutan
        Bolivia
        Bosnia and Herzegovina
        Botswana
        Brazil
        British Indian Ocean Territory
        British Virgin Islands
        Brunei
        Bulgaria
        Burkina Faso
        Burundi
        Cabo Verde
        Cambodia
        Cameroon
        Canada
        Caribbean Netherlands
        Cayman Islands
        Central African Republic
        Chad
        Chile
        Christmas Island
        Cocos (Keeling) Islands
        Colombia
        Comoros
        Cook Islands
        Costa Rica
        Côte d'Ivoire
        Croatia
        Curaçao
        Czech Republic
        Democratic Republic of the Congo
        Denmark
        Djibouti
        Dominica
        Dominican Republic
        Ecuador
        Egypt
        El Salvador
        Equatorial Guinea
        Eritrea
        Estonia
        Eswatini
        Ethiopia
        Falkland Islands (Islas Malvinas)
        Faroe Islands
        Fiji
        Finland
        France
        Gabon
        The Gambia
        Georgia
        Germany
        Ghana
        Gibraltar
        Greece
        Greenland
        Grenada
        Guam
        Guatemala
        Guernsey
        Guinea
        Guinea-Bissau
        Guyana
        Haiti
        Heard Island and McDonald Islands
        Honduras
        Hungary
        Iceland
        India
        Indonesia
        Iraq
        Ireland
        Isle of Man
        Israel
        Italy
        Jamaica
        Japan
        Jersey
        Jordan
        Kazakhstan
        Kenya
        Kiribati
        Kosovo
        Kuwait
        Kyrgyzstan
        Laos
        Latvia
        Lebanon
        Lesotho
        Liberia
        Libya
        Liechtenstein
        Lithuania
        Luxembourg
        Madagascar
        Malawi
        Malaysia
        Maldives
        Mali
        Malta
        Marshall Islands
        Mauritania
        Mauritius
        Mexico
        Micronesia
        Moldova
        Mongolia
        Montenegro
        Montserrat
        Morocco
        Mozambique
        Namibia
        Nauru
        Nepal
        Netherlands
        New Caledonia
        New Zealand
        Nicaragua
        Niger
        Nigeria
        Niue
        Norfolk Island
        North Macedonia
        Northern Mariana Islands
        Norway
        Oman
        Pakistan
        Palau
        Palestine
        Panama
        Papua New Guinea
        Paraguay
        Peru
        Philippines
        Pitcairn Islands
        Poland
        Portugal
        Puerto Rico
        Qatar
        Republic of Cyprus
        Republic of the Congo
        Romania
        Rwanda
        Saint Barthélemy
        Saint Helena, Ascension and Tristan da Cunha
        Saint Kitts and Nevis
        Saint Lucia
        Saint Pierre and Miquelon
        Saint Vincent and the Grenadines
        Samoa
        San Marino
        São Tomé and Príncipe
        Saudi Arabia
        Senegal
        Serbia
        Seychelles
        Sierra Leone
        Singapore
        Slovakia
        Slovenia
        Solomon Islands
        Somalia
        South Africa
        South Georgia and the South Sandwich Islands
        South Korea
        South Sudan
        Spain
        Sri Lanka
        Sudan
        Suriname
        Sweden
        Switzerland
        Taiwan
        Tajikistan
        Tanzania
        Thailand
        Timor-Leste
        Togo
        Tokelau
        Tonga
        Trinidad and Tobago
        Tunisia
        Turkmenistan
        Turks and Caicos Islands
        Tuvalu
        Türkiye
        Uganda
        Ukraine
        United Arab Emirates
        United Kingdom
        United States
        United States Minor Outlying Islands
        Uruguay
        U.S. Virgin Islands
        Uzbekistan
        Vanuatu
        Vatican City
        Venezuela
        Vietnam
        Wallis and Futuna
        Western Sahara
        Yemen
        Zambia
        Zimbabwe
        Åland Islands
      ''
    )
  );

  geminiCountryAliases = [
    "Cyprus"
    "Czechia"
    "Cape Verde"
    "Cote d Ivoire"
    "Ivory Coast"
    "Curacao"
    "Sao Tome and Principe"
    "Turkey"
    "USA"
    "United States of America"
    "US Virgin Islands"
  ];

  geminiCountryFilterScript = ''
    const normalize = (input) =>
      String(input ?? "")
        .toLowerCase()
        .normalize("NFKD")
        .replace(/[\u0300-\u036f]/g, "")
        .replace(/[^a-z0-9]+/g, " ")
        .trim();

    const allowedNames = [
      ...${builtins.toJSON geminiSupportedCountries},
      ...${builtins.toJSON geminiCountryAliases},
    ];

    const normalizedAllowed = allowedNames.map(normalize);
    const normalizedName = normalize($server?.name ?? "");

    return normalizedAllowed.some((country) =>
      country && normalizedName.includes(country),
    );
  '';

  subscriptions = [
    {
      name = "black-vless-rus";
      displayName = "BLACK_VLESS_RUS";
      source = "remote";
      url = "https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_VLESS_RUS.txt";
      ignoreFailedRemoteSub = true;
    }
    {
      name = "vless-universal";
      displayName = "vless_universal";
      source = "remote";
      url = "https://raw.githubusercontent.com/zieng2/wl/main/vless_universal.txt";
      ignoreFailedRemoteSub = true;
    }
    {
      name = "black-ss-all-rus";
      displayName = "BLACK_SS+All_RUS";
      source = "remote";
      url = "https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/BLACK_SS+All_RUS.txt";
      ignoreFailedRemoteSub = true;
    }
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
          type = "Type Filter";
          args = [
            "vless"
            "vmess"
            "trojan"
            "ss"
            "hysteria"
            "hysteria2"
            "tuic"
            "wireguard"
            "socks5"
            "http"
          ];
        }
        {
          type = "Script Filter";
          args = {
            mode = "code";
            content = geminiCountryFilterScript;
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
