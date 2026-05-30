# Contributing

Thanks for helping improve `mujoco-ios`.

## Local Setup

```sh
make download
make build
make typecheck
```

Open the sample app with:

```sh
open examples/MujocoExample/MujocoExample.xcodeproj
```

## Guidelines

- Keep generated outputs out of commits: `mujoco/`, `build/`, `output/`,
  `.build/`, `.swiftpm/`, and Xcode `xcuserdata/` are local state.
- Keep changes scoped. Build scripts, patch files, and upstream pin changes have
  a larger supply-chain impact and should be reviewed carefully.
- Update `README.md` when setup, supported platforms, or release behavior changes.
- Run `make typecheck` before opening a pull request.

## Updating MuJoCo

1. Pick a MuJoCo commit or tag.
2. Run `make download MUJOCO_REF=<commit-or-tag>`.
3. Update `scripts/ios-patches.diff` if the patch no longer applies.
4. Run `make build MUJOCO_REF=<commit-or-tag>` and `make typecheck`.
5. Update the default `MUJOCO_REF` in `Makefile` and `scripts/build_xcframework.sh`.
