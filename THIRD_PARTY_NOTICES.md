# Third-Party Notices

This repository builds and links [MuJoCo](https://github.com/google-deepmind/mujoco).
MuJoCo is developed by Google DeepMind and distributed under the Apache License
2.0.

The build script downloads MuJoCo source into the ignored `mujoco/` directory and
applies `scripts/ios-patches.diff` before producing `output/mujoco.xcframework`.
Generated binaries are not committed to this repository.

If you distribute a generated `mujoco.xcframework` or an app that includes it,
include MuJoCo's license and any upstream notices required by the MuJoCo
distribution you built from.
