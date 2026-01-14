import MetalKit

struct GraphicRenderPass {
    var descriptor: MTLRenderPassDescriptor?
    var graphicPSO: MTLRenderPipelineState
    var vertexFunction: MTLFunction

    var quad: QuadModel

    // Buffer coming from PhysicRenderPass
    var speedNormBuffer: MTLBuffer
    var solidMaskBuffer: MTLBuffer
    var mesh: Mesh
    var simParams: SimParams

    // constant
    var uniforms: Uniforms

    // Properties for the texture and sampler
    var gradientTexture: MTLTexture
    var samplerState: MTLSamplerState

    init(view: MTKView, physicPass: PhysicRenderPass, quad: QuadModel, camera: OrthographicCamera) {
        guard let device = view.device else {
            fatalError("MTKView device not configured")
        }

        // Create the pipeline state and retrieve the vertex function
        let (pso, vertexFunc) = PipelineStates.createGraphicPSO(colorPixelFormat: view.colorPixelFormat)
        self.graphicPSO = pso
        self.vertexFunction = vertexFunc

        // Retrieve information from the physics simulation
        self.speedNormBuffer = physicPass.speedNormBuffer
        self.mesh = physicPass.mesh
        self.solidMaskBuffer = physicPass.solidMaskBuffer
        self.simParams = physicPass.simParams
            
        // Quad vertex model
        self.quad = quad

        // Create uniforms
        var uniforms = Uniforms()
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
        self.uniforms = uniforms

        // Create the gradient texture
        self.gradientTexture = GraphicRenderPass.createGradientTexture(device: device, size: 256)
        
        // Create the sampler state
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        guard let sampler = device.makeSamplerState(descriptor: samplerDescriptor)
        else {
            fatalError("Failed to create sampler state")
        }
        self.samplerState = sampler
    }

    mutating func updateCamera(_ camera: OrthographicCamera) {
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
    }

    func draw(commandBuffer: MTLCommandBuffer) {
        guard let descriptor = descriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(self.graphicPSO)

        // Vertex function
        var uniforms = self.uniforms
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: UniformsBuffer.index)
        renderEncoder.setVertexBuffer(quad.vertexBuffer, offset: 0, index: VertexBuffer.index)
        var mesh = self.mesh
        renderEncoder.setVertexBytes(&mesh, length: MemoryLayout<Mesh>.stride, index: MeshBuffer.index)

        // Fragment function
        renderEncoder.setFragmentBytes(&mesh, length: MemoryLayout<Mesh>.stride, index: MeshBuffer.index)
        var params = self.simParams
        renderEncoder.setFragmentBytes(&params, length: MemoryLayout<SimParams>.stride, index: SimParamsBuffer.index)
        renderEncoder.setFragmentBuffer(solidMaskBuffer, offset: 0, index: SolidMaskBuffer.index)
        renderEncoder.setFragmentBuffer(speedNormBuffer, offset: 0, index: SpeedNormBuffer.index)
        renderEncoder.setFragmentTexture(gradientTexture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)

        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}

extension GraphicRenderPass {

    static func createGradientTexture(device: MTLDevice, size: Int) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: size,
            height: 1,
            mipmapped: false
        )
        textureDescriptor.usage = .shaderRead

        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Failed to create texture")
        }

        struct ColorStop {
            let t: Float
            let r: Float
            let g: Float
            let b: Float
        }

        let stops: [ColorStop] = [
            ColorStop(t: 0.00, r: 0.0, g: 0.0, b: 0.5),
            ColorStop(t: 0.35, r: 0.0, g: 0.8, b: 1.0),
            ColorStop(t: 0.66, r: 1.0, g: 1.0, b: 0.0),
            ColorStop(t: 1.00, r: 1.0, g: 0.0, b: 0.0)
        ]

        func sampleJet(_ t: Float) -> (UInt8, UInt8, UInt8, UInt8) {
            let clamped = min(max(t, 0.0), 1.0)
            var lower = stops[0]
            var upper = stops[stops.count - 1]
            for i in 1..<stops.count {
                if clamped <= stops[i].t {
                    lower = stops[i - 1]
                    upper = stops[i]
                    break
                }
            }
            let span = max(upper.t - lower.t, 1e-6)
            let localT = (clamped - lower.t) / span
            let r = lower.r + (upper.r - lower.r) * localT
            let g = lower.g + (upper.g - lower.g) * localT
            let b = lower.b + (upper.b - lower.b) * localT
            return (
                UInt8(r * 255.0),
                UInt8(g * 255.0),
                UInt8(b * 255.0),
                255
            )
        }

        var pixelData = [UInt8](repeating: 0, count: size * 4)
        let last = max(1, size - 1)
        for x in 0..<size {
            let t = Float(x) / Float(last)
            let (r, g, b, a) = sampleJet(t)
            let pixelIndex = x * 4
            pixelData[pixelIndex] = r
            pixelData[pixelIndex + 1] = g
            pixelData[pixelIndex + 2] = b
            pixelData[pixelIndex + 3] = a
        }

        let region = MTLRegionMake2D(0, 0, size, 1)
        texture.replace(region: region, mipmapLevel: 0, withBytes: pixelData, bytesPerRow: size * 4)
        return texture
    }
}
