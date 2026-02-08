{ pkgs, ... }:
let
  controllerAddr = "127.0.0.1:19090";
  proxyPort = 17890;

  configFile = pkgs.writeText "mihomo-config.yaml" ''
    mixed-port: ${toString proxyPort}
    allow-lan: false
    bind-address: 127.0.0.1
    mode: rule
    log-level: info
    ipv6: true

    external-controller: ${controllerAddr}
    secret: "metacubexd-local"

    profile:
      store-selected: true
      store-fake-ip: true

    tun:
      enable: true

    proxy-providers:
      sub-store-ru-merged:
        type: http
        url: "http://127.0.0.1:3000/download/collection/ru-merged/Mihomo"
        interval: 3600
        path: ./proxy-providers/sub-store-ru-merged.yaml
        health-check:
          enable: true
          interval: 600
          url: https://cp.cloudflare.com/generate_204

    proxy-groups:
      - name: Auto
        type: url-test
        use:
          - sub-store-ru-merged
        url: https://cp.cloudflare.com/generate_204
        interval: 300

      - name: Manual-All
        type: select
        use:
          - sub-store-ru-merged

      - name: Region-Americas
        type: select
        use:
          - sub-store-ru-merged
        filter: "(?i)argentina|bahamas|barbados|belize|bermuda|bolivia|brazil|canada|cayman|chile|colombia|costa rica|dominica|dominican|ecuador|el salvador|falkland|grenada|guatemala|guyana|haiti|honduras|jamaica|mexico|montserrat|nicaragua|panama|paraguay|peru|puerto rico|saint kitts|saint lucia|saint vincent|suriname|trinidad|united states|uruguay|u[.]s[.] virgin|venezuela"

      - name: Region-Europe
        type: select
        use:
          - sub-store-ru-merged
        filter: "(?i)andorra|austria|belgium|bosnia|bulgaria|croatia|cyprus|czech|denmark|estonia|faroe|finland|france|germany|gibraltar|greece|guernsey|hungary|iceland|ireland|isle of man|italy|jersey|kosovo|latvia|liechtenstein|lithuania|luxembourg|malta|moldova|montenegro|netherlands|north macedonia|norway|poland|portugal|romania|san marino|serbia|slovakia|slovenia|spain|sweden|switzerland|ukraine|united kingdom|vatican|aland"

      - name: Region-MEA
        type: select
        use:
          - sub-store-ru-merged
        filter: "(?i)algeria|angola|bahrain|benin|botswana|burkina|burundi|cameroon|central african|chad|comoros|congo|djibouti|egypt|equatorial guinea|eritrea|eswatini|ethiopia|gabon|gambia|ghana|guinea|ivory coast|kenya|kuwait|lebanon|lesotho|liberia|libya|madagascar|malawi|mali|mauritania|mauritius|morocco|mozambique|namibia|niger|nigeria|oman|palestine|qatar|rwanda|saudi arabia|senegal|seychelles|sierra leone|somalia|south africa|south sudan|sudan|tanzania|togo|tunisia|uganda|united arab emirates|western sahara|yemen|zambia|zimbabwe"

      - name: Region-APAC
        type: select
        use:
          - sub-store-ru-merged
        filter: "(?i)american samoa|antarctica|aruba|australia|azerbaijan|bangladesh|bhutan|brunei|cambodia|christmas island|cocos|cook islands|fiji|georgia|guam|india|indonesia|iraq|israel|japan|jordan|kazakhstan|kiribati|kyrgyzstan|laos|malaysia|maldives|marshall islands|micronesia|mongolia|nauru|nepal|new caledonia|new zealand|niue|norfolk island|northern mariana|pakistan|palau|papua new guinea|philippines|pitcairn|samoa|singapore|solomon islands|south korea|sri lanka|taiwan|tajikistan|thailand|timor-leste|tokelau|tonga|turkmenistan|turks and caicos|tuvalu|turkey|turkiye|uzbekistan|vanuatu|vietnam|wallis and futuna"

      - name: Proxy
        type: select
        proxies:
          - Auto
          - Manual-All
          - Region-Americas
          - Region-Europe
          - Region-MEA
          - Region-APAC
          - DIRECT
          - REJECT

    rules:
      - DOMAIN,localhost,DIRECT
      - DOMAIN-SUFFIX,localhost,DIRECT
      - DOMAIN-SUFFIX,local,DIRECT
      - IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
      - IP-CIDR6,::1/128,DIRECT,no-resolve
      - GEOIP,PRIVATE,DIRECT,no-resolve
      - DOMAIN-SUFFIX,ru,DIRECT
      - DOMAIN-SUFFIX,su,DIRECT
      - DOMAIN-SUFFIX,xn--p1ai,DIRECT
      - GEOIP,RU,DIRECT
      - MATCH,Proxy
  '';
in
{
  services.mihomo = {
    enable = true;
    package = pkgs.mihomo;
    configFile = configFile;
    webui = pkgs.metacubexd;
    tunMode = true;
  };

  systemd.services.mihomo = {
    after = [ "sub-store-bootstrap.service" ];
    wants = [ "sub-store-bootstrap.service" ];
  };
}
