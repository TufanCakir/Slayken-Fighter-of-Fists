import SwiftUI
import MetalKit

struct MetalSkillEffectView: UIViewRepresentable {
    let element: String
    let trigger: Bool
    var style: String = "burst"
    var scale: Float = 3.0

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1) // ✅ Fix
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
        context.coordinator.triggerIfNeeded(trigger, element: element, style: style)
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
        var scale: Float = 1.0

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

            vertex VertexOut basic_vertex(
                const device float2* positions [[buffer(0)]],
                const device float4* colors [[buffer(1)]],
                constant float& size [[buffer(2)]],
                uint id [[vertex_id]]
            ) {
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

                float3 color = in.color.rgb;

                if (color.r > 0.8 && color.g < 0.4) {
                    glow *= 1.8; color.rgb *= float3(1.0, 0.6, 0.3); // Fire
                } else if (color.b > 0.8 && color.g > 0.6) {
                    glow *= 1.3; color.rgb *= float3(0.6, 0.9, 1.0); // Ice
                } else if (color.r > 0.9 && color.g > 0.9) {
                    glow *= 2.0; color.rgb *= float3(1.2, 1.2, 0.5); // Thunder
                } else if (color.b > 0.7 && color.r > 0.7) {
                    glow *= 1.5; color.rgb *= float3(0.9, 0.4, 1.2); // Void
                } else if (color.r < 0.3 && color.g < 0.3) {
                    glow *= 1.0; color.rgb *= float3(0.4, 0.2, 0.5); // Shadow
                }

                return float4(color * glow * 1.3, in.color.a * (1.0 - dist));
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

                // ✅ Additive blend mode fix
                desc.colorAttachments[0].isBlendingEnabled = true
                desc.colorAttachments[0].rgbBlendOperation = .add
                desc.colorAttachments[0].alphaBlendOperation = .add
                desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                desc.colorAttachments[0].destinationRGBBlendFactor = .one
                desc.colorAttachments[0].sourceAlphaBlendFactor = .one
                desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

                pipelineState = try device.makeRenderPipelineState(descriptor: desc)
            } catch {
                print("❌ Metal Pipeline Error:", error.localizedDescription)
            }
        }

        // MARK: - Trigger
        func triggerIfNeeded(_ trigger: Bool, element: String, style: String) {
            guard trigger else { return }
            life = 1.0
            baseColor = colorForElement(element)
            generatePattern(for: style, color: baseColor)
        }

        private func colorForElement(_ element: String) -> SIMD4<Float> {
            switch element.lowercased() {
            case "fire": return SIMD4(1.0, 0.3, 0.0, 1.0)
            case "ice": return SIMD4(0.5, 0.9, 1.0, 1.0)
            case "thunder": return SIMD4(1.0, 1.0, 0.3, 1.0)
            case "void": return SIMD4(0.8, 0.3, 1.0, 1.0)
            case "shadow": return SIMD4(0.2, 0.2, 0.3, 1.0)
            case "wind": return SIMD4(0.6, 1.0, 0.8, 1.0)
            case "water": return SIMD4(0.6, 1.0, 0.8, 1.0)
            case "tornado": return SIMD4(0.6, 1.0, 0.8, 1.0)

            case "shadowclone": return SIMD4(0.6, 1.0, 0.8, 1.0)


            default: return SIMD4(1, 1, 1, 1)
            }
        }

        // MARK: - Particle Patterns
        private func generatePattern(for style: String, color: SIMD4<Float>) {
            let count = Int(180 * scale)
            particles.removeAll(keepingCapacity: true)

            for i in 0..<count {
                var pos = SIMD2<Float>(0, -0.6)
                var vel = SIMD2<Float>(0, 0)
                var c = color

                switch style {
                case "burst": // Fire
                    vel = normalize(SIMD2(Float.random(in: -1...1), Float.random(in: -1...1))) * 0.05 * scale
                    c.x += Float.random(in: 0.1...0.3)
                    c.y *= 0.7
                    c.z *= 0.4

                case "ring": // Ice
                    let angle = Float(i) / Float(count) * (.pi * 2)
                    pos = SIMD2<Float>(cos(angle) * 0.2, sin(angle) * 0.2)
                    vel = SIMD2<Float>(0, 0.01 + Float.random(in: 0.01...0.02))
                    c.w = Float.random(in: 0.5...0.9)

                case "beam": // Thunder
                    vel = SIMD2<Float>(Float.random(in: -0.02...0.02), Float.random(in: 0.1...0.15))
                    c = SIMD4<Float>(1.0, 1.0, 0.5, 1.0)

                case "spiral": // Void
                    let angle = Float(i) / Float(count) * (.pi * 4)
                    pos = SIMD2<Float>(cos(angle) * 0.2, sin(angle) * 0.2)
                    vel = SIMD2<Float>(-pos.y, pos.x) * 0.025 * scale
                    c = SIMD4<Float>(0.9, 0.5, 1.0, 1.0)

                case "wave": // Shadow
                    vel = SIMD2<Float>(sin(Float(i) * 0.3) * 0.03, Float.random(in: 0.02...0.04))
                    c = SIMD4<Float>(0.4, 0.3, 0.5, 1.0)
                    c.w = Float.random(in: 0.6...0.9)

                case "tornado": // Wind
                    let revolutions: Float = 8.0
                    let angle = Float(i) / Float(count) * (.pi * revolutions)
                    let height = Float(i) / Float(count)
                    let radius = 0.05 + height * 0.25
                    pos = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius - 0.8 + height * 1.6)
                    vel = SIMD2<Float>(-sin(angle) * 0.015 * scale, 0.02 + Float.random(in: 0.005...0.02) * scale)
                    c = SIMD4<Float>(0.7, 1.0, 0.9, 1.0)
                    c.w = Float.random(in: 0.5...1.0)
                    
                case "shadowclone":
                    // 🌑 Schattenhafte Erscheinung
                    let pulse = sin(Float(i) * 0.3) * 0.1
                    let spread = Float.random(in: -0.25...0.25)
                    
                    // Ausgangsposition – leicht unterhalb des Charakters
                    pos = SIMD2<Float>(spread, -0.7 + Float.random(in: -0.05...0.05))
                    
                    // Langsames Aufsteigen und leicht pulsierende Bewegung
                    vel = SIMD2<Float>(
                        Float.random(in: -0.005...0.005),
                        Float.random(in: 0.01...0.025) + pulse
                    ) * scale
                    
                    // Dunkles, violett-bläuliches Leuchten
                    c = SIMD4<Float>(
                        0.25 + Float.random(in: 0.1...0.2),
                        0.15 + Float.random(in: 0.05...0.1),
                        0.35 + Float.random(in: 0.1...0.2),
                        1.0
                    )
                    
                    // Manche Partikel sind leicht transparent für „Rauch“-Effekt
                    c.w = Float.random(in: 0.3...0.8)


                default:
                    vel = SIMD2<Float>(Float.random(in: -0.02...0.02), Float.random(in: 0.03...0.05))
                }

                particles.append(Particle(position: pos, velocity: vel, color: c))
            }
        }


        // MARK: - Draw
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        func draw(in view: MTKView) {
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let pass = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable else { return }

            if life > 0 {
                life -= 0.02
                for i in 0..<particles.count {
                    particles[i].position += particles[i].velocity
                    particles[i].velocity.x += Float.random(in: -0.0003...0.0003)
                    particles[i].velocity.y += 0.0002
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

            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
            encoder.setRenderPipelineState(pipelineState)

            let posBuffer = device.makeBuffer(bytes: particles.map { $0.position },
                                              length: MemoryLayout<SIMD2<Float>>.stride * particles.count)
            let colBuffer = device.makeBuffer(bytes: particles.map { $0.color },
                                              length: MemoryLayout<SIMD4<Float>>.stride * particles.count)
            encoder.setVertexBuffer(posBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(colBuffer, offset: 0, index: 1)

            var pointSize: Float = 10.0 * scale
            encoder.setVertexBytes(&pointSize, length: MemoryLayout<Float>.stride, index: 2)

            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particles.count)
            encoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
