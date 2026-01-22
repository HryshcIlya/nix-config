# Library

This directory contains helper functions used by `flake.nix` to reduce code duplication and make it
easier to add new machines.

## Current Functions

### Core System Generators

1. **`attrs.nix`** - Attribute set manipulation utilities
2. **`nixosSystem.nix`** - NixOS configuration generator
3. **`colmenaSystem.nix`** - Remote deployment configuration for
   [colmena](https://github.com/zhaofengli/colmena)

### Specialized Module Generators

4. **`genK3sAgentModule.nix`** - K3s agent node configuration generator
5. **`genK3sServerModule.nix`** - K3s server node configuration generator
6. **`genKubeVirtGuestModule.nix`** - KubeVirt guest VM configuration generator
7. **`genKubeVirtHostModule.nix`** - KubeVirt host configuration generator

### Entry Point

8. **`default.nix`** - Main entry point that imports all functions and exports them as a single
   attribute set

## Usage

These functions are designed to:

- Generate consistent configurations across different architectures
- Provide type-safe configuration for complex systems
- Enable easy scaling of the infrastructure
- Support both local development and production deployments

## Architecture Support

- **x86_64-linux**: Primary desktop systems
- **aarch64-linux**: ARM64 Linux systems (SBCs)
