import SwiftUI
import MetalKit

struct MetalAuraView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.framebufferOnly = false
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.delegate = context.coordinator
        context.coordinator.view = view
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    // MARK: - Coordinator
    class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice!
        var pipeline: MTLRenderPipelineState!
        var commandQueue: MTLCommandQueue!
        var time: Float = 0
        weak var view: MTKView?

        override init() {
            super.init()
            device = MTLCreateSystemDefaultDevice()
            commandQueue = device.makeCommandQueue()
            buildPipeline()
        }

        func buildPipeline() {
            guard let library = device.makeDefaultLibrary() else { return }
            let vertex = library.makeFunction(name: "vertex_passthrough")
            let fragment = library.makeFunction(name: "plasma_fragment")

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertex
            descriptor.fragmentFunction = fragment
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipeline = try? device.makeRenderPipelineState(descriptor: descriptor)
        }

        // MARK: - Pflichtmethoden von MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Hier könnte man später auf Größenänderungen reagieren (z. B. bei Rotation)
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
            else { return }

            time += 0.02
            encoder.setRenderPipelineState(pipeline)
            encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
