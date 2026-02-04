{
  # Required by preservation - must be available early in boot
  fileSystems."/persistent".neededForBoot = true;

  disko.devices = {
    # Root filesystem on tmpfs (stateless)
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        # Set mode to 755, otherwise systemd will set it to 777, which causes problems.
        "mode=755"
      ];
    };

    disk.main = {
      # When using disko-install, override this from the commandline:
      #   --disk main /dev/nvme0n1
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          # EFI System Partition
          ESP = {
            size = "630M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "umask=0077"
              ];
            };
          };

          # LUKS encrypted root partition
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted-nixos";
              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };

              # LUKS2 format options
              extraFormatArgs = [
                "--type luks2"
                "--cipher aes-xts-plain64"
                "--hash sha512"
                "--iter-time 5000"
                "--key-size 256"
                "--pbkdf argon2id"
                "--use-random"
              ];

              content = {
                type = "btrfs";
                extraArgs = [
                  "-f" # Force override existing partition
                  "-L crypted-nixos" # Label for the filesystem
                ];
                mountpoint = "/btr_pool";
                mountOptions = [ "subvolid=5" ];
                subvolumes =
                  let
                    subvolMountOptions = [
                      "compress-force=zstd:1"
                      "noatime"
                    ];
                  in
                  {
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = subvolMountOptions;
                    };

                    "@persistent" = {
                      mountpoint = "/persistent";
                      mountOptions = subvolMountOptions;
                    };

                    "@tmp" = {
                      mountpoint = "/tmp";
                      mountOptions = [ "compress-force=zstd:1" ];
                    };

                    "@snapshots" = {
                      mountpoint = "/snapshots";
                      mountOptions = subvolMountOptions;
                    };

                    "@swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "16G";
                    };
                  };
              };
            };
          };
        };
      };
    };
  };
}
