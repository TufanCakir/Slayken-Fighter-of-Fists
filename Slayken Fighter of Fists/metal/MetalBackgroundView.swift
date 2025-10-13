import SwiftUI
import MetalKit

struct MetalBackgroundView: UIViewRepresentable {
    let topColor: SIMD4<Float>   // z. B. Himmel
    let bottomColor: SIMD4<Float> // z. B. Boden

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.framebufferOnly = false
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.delegate = context.coordinator
        context.coordinator.view = view
        context.coordinator.setup(device: view.device!, top: topColor, bottom: bottomColor)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.update(top: topColor, bottom: bottomColor)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var view: MTKView!
        var device: MTLDevice!
        var pipeline: MTLRenderPipelineState!
        var vertexBuffer: MTLBuffer!
        var colorBuffer: MTLBuffer!

        func setup(device: MTLDevice, top: SIMD4<Float>, bottom: SIMD4<Float>) {
            self.device = device

            // Simple Quad (Fullscreen)
            let vertices: [SIMD2<Float>] = [
                [-1, -1], [1, -1], [-1, 1],
                [1, -1], [1, 1], [-1, 1]
            ]
            vertexBuffer = device.makeBuffer(bytes: vertices,
                                             length: MemoryLayout<SIMD2<Float>>.stride * vertices.count,
                                             options: [])

            // Farben oben/unten
            let colors = [bottom, top]
            colorBuffer = device.makeBuffer(bytes: colors,
                                            length: MemoryLayout<SIMD4<Float>>.stride * colors.count,
                                            options: [])

            // Shader Code inline
            let shaderSource = """
            #include <metal_stdlib>
            using namespace metal;

            struct VertexOut {
                float4 position [[position]];
                float2 uv;
            };

            vertex VertexOut vertex_main(const device float2* vertices [[buffer(0)]],
                                         uint vid [[vertex_id]]) {
                VertexOut out;
                out.position = float4(vertices[vid], 0, 1);
                out.uv = (vertices[vid] + 1.0) * 0.5;
                return out;
            }

            fragment float4 fragment_main(VertexOut in [[stage_in]],
                                          constant float4* colors [[buffer(1)]]) {
                float4 top = colors[1];
                float4 bottom = colors[0];
                float t = smoothstep(0.0, 1.0, in.uv.y);
                return mix(bottom, top, t);
            }
            """

            let library = try! device.makeLibrary(source: shaderSource, options: nil)
            let pipelineDesc = MTLRenderPipelineDescriptor()
            pipelineDesc.vertexFunction = library.makeFunction(name: "vertex_main")
            pipelineDesc.fragmentFunction = library.makeFunction(name: "fragment_main")
            pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipeline = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
        }

        func update(top: SIMD4<Float>, bottom: SIMD4<Float>) {
            let colors = [bottom, top]
            colorBuffer.contents().copyMemory(from: colors,
                                              byteCount: MemoryLayout<SIMD4<Float>>.stride * 2)
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let pass = view.currentRenderPassDescriptor else { return }

            let commandQueue = device.makeCommandQueue()!
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentBuffer(colorBuffer, offset: 0, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    }
}
