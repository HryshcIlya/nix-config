{ myvars, lib, ... }:
#############################################################
#
#  Ai - my main computer, with NixOS + I5-13600KF + RTX 4090 GPU, for gaming & daily use.
#
#############################################################
let
  hostName = "ai"; # Define your hostname.
  iface = "enp37s0";
  dnsServers = [
    "1.1.1.1#cloudflare-dns.com"
    "1.0.0.1#cloudflare-dns.com"
    "9.9.9.9#dns.quad9.net"
    "149.112.112.112#dns.quad9.net"
    "2606:4700:4700::1111#cloudflare-dns.com"
    "2606:4700:4700::1001#cloudflare-dns.com"
    "2620:fe::fe#dns.quad9.net"
    "2620:fe::9#dns.quad9.net"
  ];
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./ai

    ./preservation.nix
    ./secureboot.nix
  ];

  services.sunshine.enable = lib.mkForce true;
  services.tuned.ppdSettings.main.default = lib.mkForce "performance";

  services.resolved = {
    enable = true;
    settings.Resolve.DNSOverTLS = "opportunistic";
  };

  networking = {
    inherit hostName;

    # we use networkd instead
    networkmanager.enable = false; # provides nmcli/nmtui for wifi adjustment
    useDHCP = false;
  };

  networking.useNetworkd = true;
  systemd.network.enable = true;

  systemd.network.networks."10-${iface}" = {
    matchConfig.Name = [ iface ];
    networkConfig = {
      DNS = dnsServers;
      DHCP = "ipv4";
      IPv6AcceptRA = true; # for Stateless IPv6 Autoconfiguraton (SLAAC)
      LinkLocalAddressing = "ipv6";
    };
    dhcpV4Config = {
      UseDNS = false;
    };
    ipv6AcceptRAConfig = {
      UseDNS = false;
    };
    linkConfig.RequiredForOnline = "routable";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
