import MetalKit
import simd

final class Renderer: NSObject, MTKViewDelegate {
    weak var view: MTKView?
    private var device: MTLDevice!
    private var queue: MTLCommandQueue!
    private var pipeline: MTLRenderPipelineState!

    private var particles: [SIMD2<Float>] = []
    private var velocities: [SIMD2<Float>] = []
    private var color: SIMD4<Float> = SIMD4(1, 1, 1, 1)
    private var particleCount: Int = 400

    private var speed: Float = 1.0
    private var size: Float = 6.0
    private var intensity: Float = 1.0

    init(element: String) {
        super.init()
        device = MTLCreateSystemDefaultDevice()
        queue = device.makeCommandQueue()
        pipeline = Renderer.makePipeline(device: device)
        color = Renderer.color(for: element)
        resetParticles()
    }

    func updateParameters(intensity: Float, speed: Float, size: Float) {
        self.intensity = intensity
        self.speed = speed
        self.size = size
    }

    func triggerBurst() { resetParticles() }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        // 🔸 Bewegung
        for i in 0..<particles.count {
            particles[i] += velocities[i] * 0.003 * speed
            if abs(particles[i].x) > 1.1 || abs(particles[i].y) > 1.1 {
                particles[i] = SIMD2(Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5))
            }
        }

        // 🔸 Vertex Buffer erstellen
        var vertices: [Float] = []
        for p in particles { vertices += [p.x, p.y, 0] }
        let buffer = device.makeBuffer(bytes: vertices,
                                       length: vertices.count * MemoryLayout<Float>.stride,
                                       options: [])

        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        encoder.setVertexBytes(&size, length: MemoryLayout<Float>.stride, index: 1)
        encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)

        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertices.count / 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Setup Helpers
    private func resetParticles() {
        particles = (0..<particleCount).map { _ in
            SIMD2(Float.random(in: -1...1), Float.random(in: -1...1))
        }
        velocities = (0..<particleCount).map { _ in
            SIMD2(Float.random(in: -1...1), Float.random(in: -1...1))
        }
    }

    private static func color(for element: String) -> SIMD4<Float> {
        switch element.lowercased() {
        case "fire": return SIMD4(1.0, 0.4, 0.0, 1.0)
        case "ice": return SIMD4(0.6, 0.9, 1.0, 1.0)
        case "void": return SIMD4(0.8, 0.0, 1.0, 1.0)
        case "nature": return SIMD4(0.1, 1.0, 0.3, 1.0)
        case "thunder": return SIMD4(1.0, 1.0, 0.2, 1.0)
        case "shadow": return SIMD4(0.5, 0.0, 0.6, 1.0)
        default: return SIMD4(1.0, 1.0, 1.0, 1.0)
        }
    }

    private static func makePipeline(device: MTLDevice) -> MTLRenderPipelineState {
        let src = """
        #include <metal_stdlib>
        using namespace metal;

        struct VSOut {
            float4 position [[position]];
            float pointSize [[point_size]];
        };

        vertex VSOut vertex_main(const device float3* pos [[buffer(0)]],
                                 constant float& size [[buffer(1)]],
                                 uint vid [[vertex_id]]) {
            VSOut out;
            out.position = float4(pos[vid], 1.0);
            out.pointSize = size;
            return out;
        }

        fragment float4 frag_main(VSOut in [[stage_in]],
                                  constant float4& color [[buffer(0)]]) {
            return color;
        }
        """
        let lib = try! device.makeLibrary(source: src, options: nil)
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = lib.makeFunction(name: "vertex_main")
        desc.fragmentFunction = lib.makeFunction(name: "frag_main")
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm

        // ✨ Additive Blend für Glow
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].rgbBlendOperation = .add
        desc.colorAttachments[0].alphaBlendOperation = .add
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .one
        desc.colorAttachments[0].sourceAlphaBlendFactor = .one
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try! device.makeRenderPipelineState(descriptor: desc)
    }
}
