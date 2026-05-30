import SwiftUI
import SceneKit

/// SceneKit-based 3D view rendering the MuJoCo simulation state.
struct SceneView: UIViewRepresentable {
  @ObservedObject var simulation: MuJoCoSimulation

  func makeUIView(context: Context) -> SCNView {
    let scnView = SCNView()
    scnView.scene = context.coordinator.scene
    scnView.allowsCameraControl = true
    scnView.autoenablesDefaultLighting = false
    scnView.backgroundColor = UIColor(red: 0.15, green: 0.25, blue: 0.35, alpha: 1.0)
    return scnView
  }

  func updateUIView(_ uiView: SCNView, context: Context) {
    context.coordinator.updateSpheres(simulation.geomPositions)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator {
    let scene: SCNScene
    private let sphereParent: SCNNode
    private var sphereNodes: [SCNNode] = []
    private let sphereGeometryCache: NSCache<NSNumber, SCNSphere> = .init()

    init() {
      scene = SCNScene()

      // Camera (MuJoCo z-up → SceneKit y-up: rotate scene)
      let cameraNode = SCNNode()
      cameraNode.camera = SCNCamera()
      cameraNode.camera?.zNear = 0.05
      cameraNode.camera?.zFar = 50
      cameraNode.position = SCNVector3(-2, 2, 0)
      cameraNode.look(at: SCNVector3(0, 0, 0))
      scene.rootNode.addChildNode(cameraNode)

      // Lights
      let directional = SCNNode()
      directional.light = SCNLight()
      directional.light?.type = .directional
      directional.light?.intensity = 800
      directional.light?.castsShadow = true
      directional.position = SCNVector3(0, 5, 0)
      directional.look(at: SCNVector3(0, 0, 0))
      scene.rootNode.addChildNode(directional)

      let ambient = SCNNode()
      ambient.light = SCNLight()
      ambient.light?.type = .ambient
      ambient.light?.intensity = 300
      scene.rootNode.addChildNode(ambient)

      // Ground plane (z=0 in MuJoCo → y=0 in SceneKit after axis swap)
      let ground = SCNFloor()
      ground.reflectivity = 0.05
      let groundMat = SCNMaterial()
      groundMat.diffuse.contents = UIColor(white: 0.4, alpha: 1)
      ground.materials = [groundMat]
      let groundNode = SCNNode(geometry: ground)
      scene.rootNode.addChildNode(groundNode)

      // Sphere parent (with z-up → y-up rotation)
      sphereParent = SCNNode()
      // MuJoCo: z-up. SceneKit: y-up. Rotate -90° around X.
      sphereParent.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
      scene.rootNode.addChildNode(sphereParent)

      // Container walls (translucent)
      addWall(at: SCNVector3(-0.5, 0.25, 0), size: SCNVector3(0.01, 0.5, 1.0))
      addWall(at: SCNVector3(0.5, 0.25, 0), size: SCNVector3(0.01, 0.5, 1.0))
      addWall(at: SCNVector3(0, 0.25, -0.5), size: SCNVector3(1.0, 0.5, 0.01))
      addWall(at: SCNVector3(0, 0.25, 0.5), size: SCNVector3(1.0, 0.5, 0.01))
    }

    private func addWall(at position: SCNVector3, size: SCNVector3) {
      let box = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y),
                       length: CGFloat(size.z), chamferRadius: 0)
      let mat = SCNMaterial()
      mat.diffuse.contents = UIColor(white: 0.6, alpha: 0.3)
      mat.transparency = 0.3
      box.materials = [mat]
      let node = SCNNode(geometry: box)
      node.position = position
      scene.rootNode.addChildNode(node)
    }

    func updateSpheres(_ data: [(position: SIMD3<Float>, size: Float, color: SIMD4<Float>)]) {
      // Grow node pool if needed
      while sphereNodes.count < data.count {
        let node = SCNNode()
        sphereParent.addChildNode(node)
        sphereNodes.append(node)
      }
      // Hide excess nodes
      for i in data.count..<sphereNodes.count {
        sphereNodes[i].isHidden = true
      }

      for (i, item) in data.enumerated() {
        let node = sphereNodes[i]
        node.isHidden = false
        node.position = SCNVector3(item.position.x, item.position.y, item.position.z)

        // Cache sphere geometry by size (quantized to avoid too many unique geoms)
        let sizeKey = NSNumber(value: Int(item.size * 10000))
        if node.geometry == nil {
          if let cached = sphereGeometryCache.object(forKey: sizeKey) {
            node.geometry = cached.copy() as? SCNGeometry
          } else {
            let sphere = SCNSphere(radius: CGFloat(item.size))
            sphere.segmentCount = 12
            sphereGeometryCache.setObject(sphere, forKey: sizeKey)
            node.geometry = sphere.copy() as? SCNGeometry
          }
        }

        // Set color
        if let geom = node.geometry {
          let mat = geom.firstMaterial ?? SCNMaterial()
          mat.diffuse.contents = UIColor(
            red: CGFloat(item.color.x),
            green: CGFloat(item.color.y),
            blue: CGFloat(item.color.z),
            alpha: CGFloat(item.color.w)
          )
          geom.firstMaterial = mat
        }
      }
    }
  }
}
