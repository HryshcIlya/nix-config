# Library

This directory contains helper functions used by `flake.nix` to reduce code duplication and make it
easier to add new machines.

## Current Functions

### Core System Generators

1. **`attrs.nix`** - Attribute set manipulation utilities
2. **`nixosSystem.nix`** - NixOS configuration generator

### Entry Point

3. **`default.nix`** - Main entry point that imports all functions and exports them as a single
   attribute set

## Usage

These functions are designed to:

- Generate consistent configurations across different architectures
- Provide type-safe configuration for complex systems
- Support both local development and production deployments

## Architecture Support

- **x86_64-linux**: Primary desktop systems
