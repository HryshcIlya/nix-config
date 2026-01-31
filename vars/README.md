# Variables

Common variables used across NixOS configurations.

## Structure

```
vars/
├── README.md
└── default.nix    # User identity and credentials
```

## Contents

- User credentials (username, full name, email)
- Initial hashed password for new installations
- SSH authorized keys (main and backup sets)

## Usage

These variables are imported via `myvars` and used throughout the configuration.
