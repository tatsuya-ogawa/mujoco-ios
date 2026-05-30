# Security Policy

## Supported Versions

Security fixes are considered for the `main` branch and the latest tagged
release, if releases are published.

## Reporting a Vulnerability

Please do not disclose exploitable details in a public issue. Use GitHub Private
Vulnerability Reporting if it is enabled for the repository. If it is not
enabled, open a minimal public issue asking for a private contact path and avoid
including proof-of-concept details, crash reproducers, tokens, private URLs, or
device identifiers.

Useful reports include:

- Affected commit or release.
- Xcode, iOS SDK, and device or simulator target.
- Whether the issue affects generated `mujoco.xcframework`, Swift wrapper code,
  example app code, or GitHub Actions.
- Minimal reproduction steps that do not expose secrets.

## Build and Supply-Chain Notes

- MuJoCo source is downloaded into the ignored `mujoco/` directory.
- The upstream revision is pinned with `MUJOCO_REF` in `Makefile`.
- Generated binaries in `output/`, `.build/`, and `.swiftpm/` should not be
  committed.
- GitHub Actions use least-privilege workflow permissions and avoid
  `pull_request_target`.
