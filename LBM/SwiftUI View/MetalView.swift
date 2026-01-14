import SwiftUI
import MetalKit

struct MetalView: View {
    @State private var metalView = MTKView()
    @State private var renderer: Renderer?
    @Binding var isRunning: Bool
    @Binding var restartToken: Int
    @Binding var substeps: Int
    @Binding var tau: Float
    @Binding var ma: Float
    @Binding var aoaDeg: Float
    @Binding var chordRatio: Float
    @Binding var speedMax: Float
    @Binding var gridResolutionX: Int
    @Binding var gridResolutionY: Int

    var body: some View {
        MetalViewRepresentable(metalView: $metalView)
            .onAppear {
                renderer = Renderer(
                    metalView: metalView,
                    gridResolutionX: gridResolutionX,
                    gridResolutionY: gridResolutionY,
                    substeps: substeps,
                    tau: tau,
                    ma: ma,
                    aoaDeg: aoaDeg,
                    chordRatio: chordRatio,
                    speedMax: speedMax
                )
                renderer?.isPaused = !isRunning
            }
            .onChange(of: isRunning) { _, newValue in
                renderer?.isPaused = !newValue
            }
            .onChange(of: restartToken) { _, _ in
                renderer?.resetSimulation()
            }
            .onChange(of: substeps) { _, newValue in
                renderer?.updateSubsteps(newValue)
            }
            .onChange(of: tau) { _, newValue in
                renderer?.updateSimParams(tau: newValue, ma: ma, aoaDeg: aoaDeg, chordRatio: chordRatio, speedMax: speedMax)
                renderer?.resetSimulation()
            }
            .onChange(of: ma) { _, newValue in
                renderer?.updateSimParams(tau: tau, ma: newValue, aoaDeg: aoaDeg, chordRatio: chordRatio, speedMax: speedMax)
                renderer?.resetSimulation()
            }
            .onChange(of: aoaDeg) { _, newValue in
                renderer?.updateSimParams(tau: tau, ma: ma, aoaDeg: newValue, chordRatio: chordRatio, speedMax: speedMax)
                renderer?.resetSimulation()
            }
            .onChange(of: chordRatio) { _, newValue in
                renderer?.updateSimParams(tau: tau, ma: ma, aoaDeg: aoaDeg, chordRatio: newValue, speedMax: speedMax)
                renderer?.resetSimulation()
            }
            .onChange(of: speedMax) { _, newValue in
                renderer?.updateSimParams(tau: tau, ma: ma, aoaDeg: aoaDeg, chordRatio: chordRatio, speedMax: newValue)
            }
            .onChange(of: gridResolutionX) { _, newValue in
                renderer?.updateGridSize(Nx: newValue, Ny: gridResolutionY)
            }
            .onChange(of: gridResolutionY) { _, newValue in
                renderer?.updateGridSize(Nx: gridResolutionX, Ny: newValue)
            }
    }
}

typealias ViewRepresentable = NSViewRepresentable

struct MetalViewRepresentable: ViewRepresentable {
  @Binding var metalView: MTKView

  func makeNSView(context: Context) -> some NSView {
    metalView
  }
  func updateNSView(_ uiView: NSViewType, context: Context) {
    updateMetalView()
  }

  func updateMetalView() {
  }
}
