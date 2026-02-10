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
      auto-route: true
      auto-detect-interface: true
      strict-route: true
      dns-hijack:
        - 0.0.0.0:53

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

      - name: Manual
        type: select
        use:
          - sub-store-ru-merged

      - name: Proxy
        type: select
        proxies:
          - Auto
          - Manual
          - DIRECT
          - REJECT

    rules:
      - DOMAIN,localhost,DIRECT
      - DOMAIN-SUFFIX,localhost,DIRECT
      - DOMAIN-SUFFIX,local,DIRECT
      - IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
      - IP-CIDR6,::1/128,DIRECT,no-resolve
      - GEOIP,PRIVATE,DIRECT,no-resolve
      - NETWORK,UDP,Proxy
      - NETWORK,UDP,REJECT
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
