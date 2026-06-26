# Private Files

These file categories are intentionally not tracked in the public dotfiles repository. The exact private overlay location and recovery instructions should be stored outside this repo.

Examples:

- local shell overlays containing aliases, private paths, or environment-specific helpers
- Git identity files and machine-specific Git settings
- SSH private keys and SSH config
- GitHub auth token state
- cloud credentials and local config
- SOPS/age private key material or other root unlock keys
- old shell profiles that may contain deprecated paths or local secrets
- `.env` files and service account material
- recovery codes

The public files should only define reusable defaults and optional hooks that source local files when they exist.
