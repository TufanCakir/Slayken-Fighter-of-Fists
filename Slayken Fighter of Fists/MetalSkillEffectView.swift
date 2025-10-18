import SwiftUI
import MetalKit

struct MetalSkillEffectView: UIViewRepresentable {
    let element: String
    let trigger: Bool
    var scale: Float = 3.0  // 👈 Dynamischer Faktor (1.0 = normal, 2.0 = doppelt so groß)

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
        context.coordinator.setup(device: view.device!)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.scale = scale
        context.coordinator.triggerIfNeeded(trigger, element: element)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!

        struct Particle {
            var position: SIMD2<Float>
            var velocity: SIMD2<Float>
            var color: SIMD4<Float>
        }

        private var particles: [Particle] = []
        private var life: Float = 0.0
        private var baseColor = SIMD4<Float>(1, 1, 1, 1)
        var scale: Float = 1.0   // 👈 extern steuerbar

        // MARK: - Setup
        func setup(device: MTLDevice) {
            self.device = device
            commandQueue = device.makeCommandQueue()

            let shaderSource = """
            #include <metal_stdlib>
            using namespace metal;

            struct VertexOut {
                float4 position [[position]];
                float pointSize [[point_size]];
                float2 uv;
                float4 color;
            };

            vertex VertexOut basic_vertex(const device float2* positions [[buffer(0)]],
                                          const device float4* colors [[buffer(1)]],
                                          constant float& size [[buffer(2)]],
                                          uint id [[vertex_id]]) {
                VertexOut out;
                out.position = float4(positions[id], 0, 1);
                out.pointSize = size;
                out.uv = (positions[id] + 1.0) * 0.5;
                out.color = colors[id];
                return out;
            }

            fragment float4 basic_fragment(VertexOut in [[stage_in]]) {
                float2 center = float2(0.5, 0.5);
                float dist = distance(in.uv, center);
                float glow = 1.0 - pow(dist, 1.4);
                return float4(in.color.rgb * glow * 1.5, in.color.a * (1.0 - dist));
            }
            """

            do {
                let library = try device.makeLibrary(source: shaderSource, options: nil)
                let vertex = library.makeFunction(name: "basic_vertex")
                let fragment = library.makeFunction(name: "basic_fragment")

                let desc = MTLRenderPipelineDescriptor()
                desc.vertexFunction = vertex
                desc.fragmentFunction = fragment
                desc.colorAttachments[0].pixelFormat = .bgra8Unorm
                desc.colorAttachments[0].isBlendingEnabled = true
                desc.colorAttachments[0].rgbBlendOperation = .add
                desc.colorAttachments[0].alphaBlendOperation = .add
                desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                pipelineState = try device.makeRenderPipelineState(descriptor: desc)
            } catch {
                print("❌ Metal Pipeline Error:", error.localizedDescription)
            }
        }

        // MARK: - Trigger
        func triggerIfNeeded(_ trigger: Bool, element: String) {
            guard trigger else { return }
            life = 1.0
            baseColor = colorForElement(element)
            generateProjectile(for: element)
        }

        private func colorForElement(_ element: String) -> SIMD4<Float> {
            switch element.lowercased() {
            case "fire": return SIMD4(1.0, 0.3, 0.0, 1.0)
            case "ice": return SIMD4(0.5, 0.9, 1.0, 1.0)
            case "thunder": return SIMD4(1.0, 1.0, 0.3, 1.0)
            case "void": return SIMD4(0.8, 0.3, 1.0, 1.0)
            case "wind": return SIMD4(0.6, 1.0, 0.8, 1.0)
            default: return SIMD4(1, 1, 1, 1)
            }
        }

        // MARK: - Particle generation
        private func generateProjectile(for element: String) {
            let particleCount = Int(180 * scale) // 👈 mehr Partikel bei größerem Scale
            particles = (0..<particleCount).map { _ in
                let start = SIMD2<Float>(0, -0.7)
                var vel: SIMD2<Float>

                _ = scale * 0.04
                switch element.lowercased() {
                case "fire":
                    vel = SIMD2(Float.random(in: -0.02...0.02) * scale,
                                Float.random(in: 0.03...0.05) * scale)
                case "ice":
                    vel = SIMD2(Float.random(in: -0.01...0.01) * scale,
                                Float.random(in: 0.01...0.02) * scale)
                case "thunder":
                    vel = SIMD2(Float.random(in: -0.015...0.015) * scale,
                                Float.random(in: 0.025...0.035) * scale)
                case "void":
                    vel = SIMD2(Float.random(in: -0.02...0.02) * scale,
                                Float.random(in: 0.015...0.03) * scale)
                default:
                    vel = SIMD2(Float.random(in: -0.015...0.015) * scale,
                                Float.random(in: 0.02...0.03) * scale)
                }

                var color = baseColor
                color.w = Float.random(in: 0.8...1.0)

                return Particle(position: start, velocity: vel, color: color)
            }
        }

        // MARK: - Draw
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPass = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable else { return }

            if life > 0 {
                life -= 0.02
                for i in 0..<particles.count {
                    particles[i].position += particles[i].velocity
                    particles[i].velocity.y += 0.0002 * scale
                    particles[i].velocity.x += Float.random(in: -0.0005...0.0005) * scale
                    particles[i].color.w = max(0, particles[i].color.w - 0.02)
                }
            } else {
                particles.removeAll()
            }

            guard !particles.isEmpty else {
                commandBuffer.present(drawable)
                commandBuffer.commit()
                return
            }

            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
            encoder.setRenderPipelineState(pipelineState)

            let posBuffer = device.makeBuffer(bytes: particles.map { $0.position },
                                              length: MemoryLayout<SIMD2<Float>>.stride * particles.count)
            let colBuffer = device.makeBuffer(bytes: particles.map { $0.color },
                                              length: MemoryLayout<SIMD4<Float>>.stride * particles.count)
            encoder.setVertexBuffer(posBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(colBuffer, offset: 0, index: 1)

            // 🔸 Punktgröße dynamisch anpassen
            var pointSize: Float = 10.0 * scale
            encoder.setVertexBytes(&pointSize, length: MemoryLayout<Float>.stride, index: 2)

            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particles.count)
            encoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
