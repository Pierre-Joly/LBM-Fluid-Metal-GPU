import MetalKit

class PhysicRenderPass {
    // PSO
    var initialize: MTLComputePipelineState
    var solid_mask: MTLComputePipelineState
    var collide_stream: MTLComputePipelineState
    var boundary: MTLComputePipelineState

    // Command queue
    let commandQueue: MTLCommandQueue

    // Device
    let device: MTLDevice

    // Constant
    var mesh: Mesh
    var substeps: Int
    var stepIndex: Int
    let Nl: Int
    var simParams: SimParams

    // Buffer
    var distributionEvenBuffer: MTLBuffer
    var distributionOddBuffer: MTLBuffer
    var speedNormBuffer: MTLBuffer
    var solidMaskBuffer: MTLBuffer

    // Thread
    let threadgroupSize: MTLSize
    var threadgroupCount: MTLSize

    init(device: MTLDevice, commandQueue: MTLCommandQueue, Nx: Int, Ny: Int, substeps: Int, tau: Float, ma: Float, aoaDeg: Float, chordRatio: Float, speedMax: Float) {
        // Constants
        self.device = device
        self.commandQueue = commandQueue
        let clampedNx = max(1, Nx)
        let clampedNy = max(1, Ny)
        self.mesh = Mesh(
            Nx: UInt32(clampedNx),
            Ny: UInt32(clampedNy)
        )
        self.substeps = substeps
        self.Nl = 9
        self.stepIndex = 0
        self.simParams = SimParams(tau: tau, Ma: ma, aoaDeg: aoaDeg, chordRatio: chordRatio, speedMax: speedMax)

        // Create compute pipeline states
        self.initialize = PipelineStates.createComputePSO(function: "initialize")
        self.solid_mask = PipelineStates.createComputePSO(function: "solid_mask")
        self.collide_stream = PipelineStates.createComputePSO(function: "collide_stream")
        self.boundary = PipelineStates.createComputePSO(function: "boundary")

        // Buffers
        guard
            let solidMaskBuffer = device.makeBuffer(
                length: clampedNx * clampedNy * MemoryLayout<Bool>.stride,
                options: .storageModePrivate
            ),
            let distributionEvenBuffer = device.makeBuffer(
                length: Nl * clampedNx * clampedNy * MemoryLayout<Float>.stride,
                options: .storageModePrivate
            ),
            let distributionOddBuffer = device.makeBuffer(
                length: Nl * clampedNx * clampedNy * MemoryLayout<Float>.stride,
                options: .storageModePrivate
            ),
            let speedNormBuffer = device.makeBuffer(
                length: clampedNx * clampedNy * MemoryLayout<Float>.stride,
                options: .storageModePrivate
            )
        else {
            fatalError("Failed to create one or more buffers")
        }
        self.solidMaskBuffer = solidMaskBuffer
        self.distributionEvenBuffer = distributionEvenBuffer
        self.distributionOddBuffer = distributionOddBuffer
        self.speedNormBuffer = speedNormBuffer

        // Threading
        self.threadgroupSize  = MTLSize(width: 256, height: 1, depth: 1)
        let count = mesh.Nx * mesh.Ny
        let groups = Int((count + 255) / 256)
        self.threadgroupCount = MTLSize(width: groups, height: 1, depth: 1)

        // Initialize the simulation
        resetState()
    }

    func draw(commandBuffer: MTLCommandBuffer) {
        let steps = max(1, substeps)
        for _ in 0..<steps {
            step(commandBuffer: commandBuffer)
        }
    }

    func resetState() {
        // Create a command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create command buffer or compute encoder")
        }

        stepIndex = 0

        // Bind Buffers
        encoder.setBytes(&mesh, length: MemoryLayout<Mesh>.stride, index: MeshBuffer.index)
        encoder.setBytes(&simParams, length: MemoryLayout<SimParams>.stride, index: SimParamsBuffer.index)
        encoder.setBuffer(distributionEvenBuffer, offset: 0, index: DistributionInBuffer.index)
        encoder.setBuffer(solidMaskBuffer, offset: 0, index: SolidMaskBuffer.index)

        // Launch kernel
        encoder.setComputePipelineState(self.initialize)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
        encoder.setBuffer(distributionOddBuffer, offset: 0, index: DistributionInBuffer.index)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)
        
        encoder.setComputePipelineState(self.solid_mask)
        encoder.setBytes(&simParams, length: MemoryLayout<SimParams>.stride, index: SimParamsBuffer.index)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    func updateGridSize(Nx: Int, Ny: Int) {
        let clampedNx = max(1, Nx)
        let clampedNy = max(1, Ny)
        mesh = Mesh(
            Nx: UInt32(clampedNx),
            Ny: UInt32(clampedNy)
        )

        guard
            let solidMaskBuffer = device.makeBuffer(
                length: clampedNx * clampedNy * MemoryLayout<Bool>.stride,
                options: .storageModePrivate
            ),
            let distributionEvenBuffer = device.makeBuffer(
                length: Nl * clampedNx * clampedNy * MemoryLayout<Float>.stride,
                options: .storageModePrivate
            ),
            let distributionOddBuffer = device.makeBuffer(
                length: Nl * clampedNx * clampedNy * MemoryLayout<Float>.stride,
                options: .storageModePrivate
            ),
            let speedNormBuffer = device.makeBuffer(
                length: clampedNx * clampedNy * MemoryLayout<Float>.stride,
                options: .storageModePrivate
            )
        else {
            fatalError("Failed to create one or more buffers")
        }
        self.solidMaskBuffer = solidMaskBuffer
        self.distributionEvenBuffer = distributionEvenBuffer
        self.distributionOddBuffer = distributionOddBuffer
        self.speedNormBuffer = speedNormBuffer
        let count = Int(mesh.Nx * mesh.Ny)
        let groups = (count + 255) / 256
        threadgroupCount = MTLSize(width: groups, height: 1, depth: 1)
        resetState()
    }

    func updateSubsteps(_ value: Int) {
        substeps = max(1, value)
    }

    func updateSimParams(tau: Float, ma: Float, aoaDeg: Float, chordRatio: Float, speedMax: Float) {
        simParams = SimParams(tau: tau, Ma: ma, aoaDeg: aoaDeg, chordRatio: chordRatio, speedMax: speedMax)
    }

    private func step(commandBuffer: MTLCommandBuffer) {
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Failed to create compute command buffer")
        }

        let useEven = (stepIndex % 2 == 0)

        let distributionInBuffer = useEven ? distributionEvenBuffer : distributionOddBuffer
        let distributionOutBuffer = useEven ? distributionOddBuffer : distributionEvenBuffer

        // Bind Buffers
        encoder.setBytes(&mesh, length: MemoryLayout<Mesh>.stride, index: MeshBuffer.index)
        encoder.setBytes(&simParams, length: MemoryLayout<SimParams>.stride, index: SimParamsBuffer.index)
        encoder.setBuffer(distributionInBuffer, offset: 0, index: DistributionInBuffer.index)
        encoder.setBuffer(distributionOutBuffer, offset: 0, index: DistributionOutBuffer.index)
        encoder.setBuffer(self.speedNormBuffer, offset: 0, index: SpeedNormBuffer.index)
        encoder.setBuffer(self.solidMaskBuffer, offset: 0, index: SolidMaskBuffer.index)

        // Launch kernel
        encoder.setComputePipelineState(self.collide_stream)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.setComputePipelineState(self.boundary)
        encoder.dispatchThreadgroups(self.threadgroupCount, threadsPerThreadgroup: self.threadgroupSize)

        encoder.endEncoding()
        stepIndex += 1
    }
}
