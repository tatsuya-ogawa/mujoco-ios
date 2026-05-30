import Foundation
import QuartzCore
import MuJoCo
import Combine

/// The same model XML used in the MuJoCo WASM demo – a particle scene with
/// 1000 spheres falling into a box enclosure.
let particleModelXML = """
<mujoco model="Particle">
  <statistic extent="1.5" meansize=".05"/>

  <option timestep="0.005" solver="CG" tolerance="1e-6"/>

  <size memory="512M"/>

  <visual>
    <rgba haze="0.15 0.25 0.35 1"/>
    <quality shadowsize="2048"/>
    <map stiffness="700" shadowscale="0.5" fogstart="10" fogend="15" zfar="40" haze="0.3"/>
  </visual>

  <default>
    <default class="wall">
      <geom type="plane" size=".5 .5 .05"/>
    </default>
  </default>

  <worldbody>
    <light directional="true" diffuse=".4 .4 .4" specular="0.1 0.1 0.1" pos="0 0 5.0" dir="0 0 -1" castshadow="false"/>
    <light directional="true" diffuse=".6 .6 .6" specular="0.2 0.2 0.2" pos="0 0 4" dir="0 0 -1"/>

    <geom name="ground" type="plane" size="0 0 1" pos="0 0 0" quat="1 0 0 0" condim="1"/>

    <body mocap="true" pos="-.1 .05 0" zaxis=".5 0 1">
      <geom type="capsule" size=".1 .1" group="1" condim="1"/>
    </body>

    <geom name="+x" class="wall" zaxis="1 0 0"  pos="-.5 0 -.25"/>
    <geom name="-x" class="wall" zaxis="-1 0 0" pos=".5 0 -.25"/>
    <geom name="+y" class="wall" zaxis="0 1 0"  pos="0 -.5 -.25"/>
    <geom name="-y" class="wall" zaxis="0 -1 0" pos="0 .5 -.25"/>

    <replicate count="10" offset=".07 0 0">
      <replicate count="10" offset="0 .07 0">
        <replicate count="10" offset="0 0 .07">
          <body pos="-.315 -.315 1">
            <joint type="slide" axis="1 0 0"/>
            <joint type="slide" axis="0 1 0"/>
            <joint type="slide" axis="0 0 1"/>
            <geom size=".025" rgba=".8 .2 .1 1" condim="1"/>
          </body>
        </replicate>
      </replicate>
    </replicate>
  </worldbody>
</mujoco>
"""

/// Observable simulation state driving the SceneKit view.
@MainActor
final class MuJoCoSimulation: ObservableObject {
  // MuJoCo C pointers
  private var model: UnsafeMutablePointer<mjModel>?
  private var data: UnsafeMutablePointer<mjData>?

  // Published state
  @Published var paused: Bool = false
  @Published var geomPositions: [(position: SIMD3<Float>, size: Float, color: SIMD4<Float>)] = []

  private var displayLink: CADisplayLink?
  private var stepsPerFrame: Int = 10

  init() {
    loadModel()
    startSimulation()
  }

  deinit {
    displayLink?.invalidate()
    if let d = data { mj_deleteData(d) }
    if let m = model { mj_deleteModel(m) }
  }

  func reset() {
    guard let m = model, let d = data else { return }
    mj_resetData(m, d)
    mj_forward(m, d)
    updateGeometries()
  }

  // MARK: - Private

  private func loadModel() {
    // Write XML to a temp file and load via mj_loadXML
    let tmpPath = NSTemporaryDirectory() + "particle.xml"
    do {
      try particleModelXML.write(toFile: tmpPath, atomically: true, encoding: .utf8)
    } catch {
      fatalError("Failed to write temp XML: \(error)")
    }

    var errBuf = [CChar](repeating: 0, count: 1024)
    model = mj_loadXML(tmpPath, nil, &errBuf, Int32(errBuf.count))

    guard let m = model else {
      let errStr = String(cString: errBuf)
      fatalError("Failed to load MuJoCo model: \(errStr)")
    }

    data = mj_makeData(m)
    guard let d = data else {
      fatalError("Failed to create MuJoCo data")
    }

    // Initial forward pass
    mj_forward(m, d)
    updateGeometries()
  }

  private func startSimulation() {
    displayLink = CADisplayLink(target: self, selector: #selector(step))
    displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
    displayLink?.add(to: .main, forMode: .common)
  }

  @objc private func step() {
    guard !paused, let m = model, let d = data else { return }
    for _ in 0..<stepsPerFrame {
      mj_step(m, d)
    }
    updateGeometries()
  }

  private func updateGeometries() {
    guard let m = model, let d = data else { return }

    let ngeom = Int(m.pointee.ngeom)
    var positions: [(position: SIMD3<Float>, size: Float, color: SIMD4<Float>)] = []
    positions.reserveCapacity(ngeom)

    for i in 0..<ngeom {
      let geomType = m.pointee.geom_type[i]
      // mjGEOM_SPHERE = 2
      guard geomType == 2 else { continue }

      let bodyId = Int(m.pointee.geom_bodyid[i])
      guard bodyId > 0 else { continue } // skip world body geoms

      // Position from geom_xpos (3 * geomId)
      let px = Float(d.pointee.geom_xpos[3 * i + 0])
      let py = Float(d.pointee.geom_xpos[3 * i + 1])
      let pz = Float(d.pointee.geom_xpos[3 * i + 2])

      // geom_size is mjtNum (double), 3 per geom
      let size = Float(m.pointee.geom_size[3 * i])

      // geom_rgba is float*, 4 per geom
      let r = m.pointee.geom_rgba[4 * i + 0]
      let g = m.pointee.geom_rgba[4 * i + 1]
      let b = m.pointee.geom_rgba[4 * i + 2]
      let a = m.pointee.geom_rgba[4 * i + 3]

      positions.append((SIMD3(px, py, pz), size, SIMD4(r, g, b, a)))
    }

    geomPositions = positions
  }
}

