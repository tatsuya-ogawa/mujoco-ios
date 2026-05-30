import SwiftUI
import MuJoCo

struct ContentView: View {
  @StateObject private var simulation = MuJoCoSimulation()

  var body: some View {
    ZStack {
      SceneView(simulation: simulation)
        .ignoresSafeArea()

      VStack {
        HStack {
          Text("MuJoCo iOS – Particle Demo")
            .font(.headline)
            .foregroundColor(.white)
            .padding(8)
            .background(.black.opacity(0.5))
            .cornerRadius(8)
          Spacer()
        }
        Spacer()
        HStack(spacing: 16) {
          Button(simulation.paused ? "Resume" : "Pause") {
            simulation.paused.toggle()
          }
          .buttonStyle(.borderedProminent)

          Button("Reset") {
            simulation.reset()
          }
          .buttonStyle(.bordered)
        }
        .padding(.bottom, 32)
      }
      .padding()
    }
  }
}
