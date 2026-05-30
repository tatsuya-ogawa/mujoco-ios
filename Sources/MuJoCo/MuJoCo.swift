// Re-export the C MuJoCo module so consumers can `import MuJoCo`.
@_exported import mujoco

public enum MuJoCo {
  /// MuJoCo version string from the C library, e.g. "3.9.0".
  public static var version: String {
    String(cString: mj_versionString())
  }
}
