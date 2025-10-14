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
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly = false
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = false
        mtkView.delegate = context.coordinator

        context.coordinator.view = mtkView
        context.coordinator.setup(device: mtkView.device!,
                                  top: topColor,
                                  bottom: bottomColor,
                                  boss: bossColor,
                                  intensity: intensity)
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.update(top: topColor,
                                   bottom: bottomColor,
                                   boss: bossColor,
                                   intensity: intensity)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var view: MTKView!
        var device: MTLDevice!
        var pipeline: MTLRenderPipelineState!
        var vertexBuffer: MTLBuffer!
        var uniformBuffer: MTLBuffer!
        var commandQueue: MTLCommandQueue!

        struct GradientUniforms {
            var topColor: SIMD4<Float>
            var bottomColor: SIMD4<Float>
            var bossColor: SIMD4<Float>
            var intensity: Float
            var height: Float
        }

        func setup(device: MTLDevice,
                   top: SIMD4<Float>,
                   bottom: SIMD4<Float>,
                   boss: SIMD4<Float>,
                   intensity: Float)
        {
            self.device = device
            commandQueue = device.makeCommandQueue()

            // 🔹 Fullscreen Quad
            let vertices: [SIMD2<Float>] = [
                [-1, -1], [1, -1], [-1, 1],
                [1, -1], [1, 1], [-1, 1]
            ]
            vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: MemoryLayout<SIMD2<Float>>.stride * vertices.count
            )

            // 🔹 Shader Source (dynamischer Boss-Gradient)
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
            };

            vertex VertexOut vertex_main(const device float2* vertices [[buffer(0)]],
                                         uint vid [[vertex_id]]) {
                VertexOut out;
                out.position = float4(vertices[vid], 0, 1);
                out.uv = (vertices[vid] + 1.0) * 0.5;
                return out;
            }

            fragment float4 fragment_main(VertexOut in [[stage_in]],
                                          constant GradientUniforms& uniforms [[buffer(1)]]) {
                float t = smoothstep(0.0, 1.0, in.uv.y);
                float4 baseColor = mix(uniforms.bottomColor, uniforms.topColor, t);

                // 🔥 Boss-Tint mit weichem Übergang
                float tintStrength = uniforms.intensity * smoothstep(0.3, 1.0, t);
                float3 tinted = mix(baseColor.rgb, uniforms.bossColor.rgb, tintStrength);

                // 🔹 Sanfter Depth-Fade unten dunkler
                tinted *= mix(0.85, 1.0, t);
                return float4(tinted, 1.0);
            }
            """

            let library = try! device.makeLibrary(source: shaderSource, options: nil)
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

            // 🔹 Initial Uniforms anlegen
            var uniforms = GradientUniforms(topColor: top,
                                            bottomColor: bottom,
                                            bossColor: boss,
                                            intensity: intensity,
                                            height: 800)
            uniformBuffer = device.makeBuffer(bytes: &uniforms,
                                              length: MemoryLayout<GradientUniforms>.stride)
        }

        func update(top: SIMD4<Float>,
                    bottom: SIMD4<Float>,
                    boss: SIMD4<Float>,
                    intensity: Float)
        {
            var uniforms = GradientUniforms(
                topColor: top,
                bottomColor: bottom,
                bossColor: boss,
                intensity: intensity,
                height: Float(view.drawableSize.height)
            )
            memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<GradientUniforms>.stride)
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let pass = view.currentRenderPassDescriptor else { return }

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
            update(top: SIMD4(1, 1, 1, 1),
                   bottom: SIMD4(0, 0, 0, 1),
                   boss: SIMD4(0, 0, 0, 1),
                   intensity: 0.3)
        }
    }
}
