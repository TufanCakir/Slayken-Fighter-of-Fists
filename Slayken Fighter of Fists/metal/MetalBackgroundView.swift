import SwiftUI
import MetalKit

struct MetalBackgroundView: UIViewRepresentable {
    let topColor: SIMD4<Float>
    let bottomColor: SIMD4<Float>
    var bossColor: SIMD4<Float> = SIMD4<Float>(0, 0, 0, 1)
    var intensity: Float = 0.4

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly = false
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.delegate = context.coordinator

        if let device = mtkView.device {
            context.coordinator.setup(device: device,
                                      top: topColor,
                                      bottom: bottomColor,
                                      boss: bossColor,
                                      intensity: intensity)
        }

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.update(top: topColor,
                                   bottom: bottomColor,
                                   boss: bossColor,
                                   intensity: intensity)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MTKViewDelegate {
        var view: MTKView!
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipeline: MTLRenderPipelineState!
        var vertexBuffer: MTLBuffer!
        var uniformBuffer: MTLBuffer!
        var time: Float = 0

        struct GradientUniforms {
            var topColor: SIMD4<Float>
            var bottomColor: SIMD4<Float>
            var bossColor: SIMD4<Float>
            var intensity: Float
            var height: Float
            var time: Float
        }

        func setup(device: MTLDevice,
                   top: SIMD4<Float>,
                   bottom: SIMD4<Float>,
                   boss: SIMD4<Float>,
                   intensity: Float)
        {
            self.device = device
            commandQueue = device.makeCommandQueue()

            // Fullscreen Quad (zwei Dreiecke)
            let vertices: [SIMD2<Float>] = [
                [-1, -1], [1, -1], [-1, 1],
                [1, -1], [1, 1], [-1, 1]
            ]
            vertexBuffer = device.makeBuffer(bytes: vertices,
                                             length: MemoryLayout<SIMD2<Float>>.stride * vertices.count)

            // 🔹 Shader mit animiertem Noise und radialem Boss-Tint
            let shaderSource = """
            #include <metal_stdlib>
            using namespace metal;

            struct VertexOut {
                float4 position [[position]];
                float2 uv;
            };

            struct GradientUniforms {
                float4 topColor;
                float4 bottomColor;
                float4 bossColor;
                float intensity;
                float height;
                float time;
            };

            float noise(float2 p) {
                return fract(sin(dot(p.xy, float2(12.9898,78.233))) * 43758.5453);
            }

            vertex VertexOut vertex_main(const device float2* vertices [[buffer(0)]],
                                         uint vid [[vertex_id]]) {
                VertexOut out;
                out.position = float4(vertices[vid], 0, 1);
                out.uv = (vertices[vid] + 1.0) * 0.5;
                return out;
            }

            fragment float4 fragment_main(VertexOut in [[stage_in]],
                                          constant GradientUniforms& uniforms [[buffer(1)]]) {
                float2 uv = in.uv;

                // Vertikaler Basisverlauf
                float t = smoothstep(0.0, 1.0, uv.y);
                float4 baseColor = mix(uniforms.bottomColor, uniforms.topColor, t);

                // Leichtes Rauschen für Bewegung
                float n = noise(uv * 8.0 + uniforms.time * 0.05);
                float flicker = mix(0.95, 1.05, n);

                // Radiale Boss-Tönung
                float2 center = float2(0.5, 0.4);
                float dist = distance(uv, center);
                float bossBlend = smoothstep(0.7, 0.0, dist) * uniforms.intensity;
                float3 mixed = mix(baseColor.rgb, uniforms.bossColor.rgb, bossBlend);

                // Kombination aus Noise + Lichtverlauf
                float3 finalColor = mixed * flicker * mix(0.85, 1.0, t);
                return float4(finalColor, 1.0);
            }
            """

            let library = try! device.makeLibrary(source: shaderSource, options: nil)
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

            // Initial Uniforms
            var uniforms = GradientUniforms(
                topColor: top,
                bottomColor: bottom,
                bossColor: boss,
                intensity: intensity,
                height: 800,
                time: 0
            )
            uniformBuffer = device.makeBuffer(bytes: &uniforms,
                                              length: MemoryLayout<GradientUniforms>.stride)
        }

        func update(top: SIMD4<Float>,
                    bottom: SIMD4<Float>,
                    boss: SIMD4<Float>,
                    intensity: Float)
        {
            guard uniformBuffer != nil else { return }
            var uniforms = GradientUniforms(
                topColor: top,
                bottomColor: bottom,
                bossColor: boss,
                intensity: intensity,
                height: Float(view?.drawableSize.height ?? 800),
                time: time
            )
            memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<GradientUniforms>.stride)
        }

        // MARK: - Draw
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let pass = view.currentRenderPassDescriptor else { return }

            time += 1 / 60.0
            self.view = view
            update(top: SIMD4(1, 1, 1, 1),
                   bottom: SIMD4(0, 0, 0, 1),
                   boss: SIMD4(0, 0, 0, 1),
                   intensity: 0.3)

            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            self.view = view
        }
    }
}
