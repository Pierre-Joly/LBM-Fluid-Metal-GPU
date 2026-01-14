import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!

    var camera = OrthographicCamera()
    var isPaused: Bool = false

    var physicRenderPass: PhysicRenderPass
    var graphicRenderPass: GraphicRenderPass
    var quadModel: QuadModel
    var gridResolutionX: Int
    var gridResolutionY: Int

    var substeps: Int
    var tau: Float
    var ma: Float
    var aoaDeg: Float
    var chordRatio: Float
    var speedMax: Float

    init(metalView: MTKView, gridResolutionX: Int, gridResolutionY: Int, substeps: Int, tau: Float, ma: Float, aoaDeg: Float, chordRatio: Float, speedMax: Float) {
        self.gridResolutionX = gridResolutionX
        self.gridResolutionY = gridResolutionY
        self.substeps = substeps
        self.tau = tau
        self.ma = ma
        self.aoaDeg = aoaDeg
        self.chordRatio = chordRatio
        self.speedMax = speedMax
        // Create the device and command queue
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue()
        else { fatalError("GPU not available") }
        
        Self.device = device
        Self.commandQueue = commandQueue
        metalView.device = device

        // Create the shader function library
        let library = device.makeDefaultLibrary()
        Self.library = library
        
        // Mesh Model
        self.quadModel = QuadModel(device: device)
        
        // Render Pass
        self.physicRenderPass = PhysicRenderPass(device: Self.device,
                                                 commandQueue: Self.commandQueue,
                                                 Nx: gridResolutionX,
                                                 Ny: gridResolutionY,
                                                 substeps: substeps,
                                                 tau: tau,
                                                 ma: ma,
                                                 aoaDeg: aoaDeg,
                                                 chordRatio: chordRatio,
                                                 speedMax: speedMax)

        self.graphicRenderPass = GraphicRenderPass(view: metalView,
                                                   physicPass: physicRenderPass,
                                                   quad: quadModel,
                                                   camera: self.camera)

        super.init()
        
        metalView.clearColor = MTLClearColor(
            red: 0,
            green: 0,
            blue: 0,
            alpha: 1.0)

        metalView.delegate = self
        mtkView(
            metalView,
            drawableSizeWillChange: metalView.drawableSize)
        }
}

extension Renderer: MTKViewDelegate {
    func mtkView(
        _ view: MTKView,
        drawableSizeWillChange size: CGSize)
    {
        camera.update(size: size)
        graphicRenderPass.updateCamera(camera)
    }

    func draw(in view: MTKView) {
        // set up command
        guard
            let commandBuffer = Self.commandQueue.makeCommandBuffer(),
            let descriptor = view.currentRenderPassDescriptor
            else { return }
        
        // Physic computation
        if !isPaused {
            physicRenderPass.draw(commandBuffer: commandBuffer)
        }
        
        // Graphic rendering
        graphicRenderPass.descriptor = descriptor
        graphicRenderPass.draw(commandBuffer: commandBuffer)
        
        // Finish the frame
        guard let drawable = view.currentDrawable
            else { return }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

extension Renderer {
    func resetSimulation() {
        physicRenderPass.resetState()
    }

    func updateSubsteps(_ value: Int) {
        substeps = value
        physicRenderPass.updateSubsteps(value)
    }

    func updateSimParams(tau: Float, ma: Float, aoaDeg: Float, chordRatio: Float, speedMax: Float) {
        self.tau = tau
        self.ma = ma
        self.aoaDeg = aoaDeg
        self.chordRatio = chordRatio
        self.speedMax = speedMax
        physicRenderPass.updateSimParams(tau: tau, ma: ma, aoaDeg: aoaDeg, chordRatio: chordRatio, speedMax: speedMax)
        graphicRenderPass.simParams = physicRenderPass.simParams
    }

    func updateGridSize(Nx: Int, Ny: Int) {
        gridResolutionX = Nx
        gridResolutionY = Ny
        physicRenderPass.updateGridSize(Nx: Nx, Ny: Ny)
        graphicRenderPass.mesh = physicRenderPass.mesh
        graphicRenderPass.speedNormBuffer = physicRenderPass.speedNormBuffer
        graphicRenderPass.solidMaskBuffer = physicRenderPass.solidMaskBuffer
    }

    
}
