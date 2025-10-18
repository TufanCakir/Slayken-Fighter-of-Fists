import SwiftUI
import MetalKit

struct MetalParticleView: UIViewRepresentable {
    var bossElement: String
    var intensity: Float
    var speed: Float
    var size: Float
    var triggerBurst: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.framebufferOnly = false
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        view.delegate = context.coordinator

        // ❌ Diese Zeile löschen:
        // context.coordinator.view = view

        context.coordinator.setup(device: view.device)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.update(element: bossElement,
                                   intensity: intensity,
                                   speed: speed,
                                   size: size,
                                   triggerBurst: triggerBurst)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        var particles: [SIMD2<Float>] = []
        var color: SIMD4<Float> = SIMD4(1, 1, 1, 1)
        var burstTimer: Float = 0

        func setup(device: MTLDevice?) {
            guard let device else { return }
            self.device = device
            self.commandQueue = device.makeCommandQueue()

            let library = device.makeDefaultLibrary()
            let vertex = library?.makeFunction(name: "basic_vertex")
            let fragment = library?.makeFunction(name: "basic_fragment")

            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = vertex
            desc.fragmentFunction = fragment
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm

            do {
                pipelineState = try device.makeRenderPipelineState(descriptor: desc)
            } catch {
                print("❌ Pipeline creation failed:", error.localizedDescription)
            }

            generateParticles(count: 500)
        }

        func generateParticles(count: Int) {
            particles = (0..<count).map { _ in
                SIMD2<Float>(Float.random(in: -0.8...0.8),
                             Float.random(in: -0.8...0.8))
            }
        }

        func update(element: String, intensity: Float, speed: Float, size: Float, triggerBurst: Bool) {
            switch element.lowercased() {
            case "fire": color = SIMD4(1, 0.3, 0.0, 1)
            case "ice": color = SIMD4(0.4, 0.8, 1, 1)
            case "void": color = SIMD4(0.6, 0.2, 0.8, 1)
            case "nature": color = SIMD4(0.3, 1, 0.4, 1)
            default: color = SIMD4(1, 1, 1, 1)
            }
            if triggerBurst {
                burstTimer = 1
                generateParticles(count: Int(300 * intensity))
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let device,
                  let commandQueue,
                  let pipelineState,
                  let descriptor = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable else { return }

            for i in 0..<particles.count {
                particles[i].x += Float.random(in: -0.002...0.002)
                particles[i].y += Float.random(in: -0.002...0.002)
            }

            let vertexBuffer = device.makeBuffer(bytes: particles,
                                                 length: MemoryLayout<SIMD2<Float>>.stride * particles.count,
                                                 options: [])

            let commandBuffer = commandQueue.makeCommandBuffer()
            let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
            encoder?.setRenderPipelineState(pipelineState)
            encoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

            var c = color
            encoder?.setFragmentBytes(&c, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
            encoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particles.count)
            encoder?.endEncoding()

            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}
