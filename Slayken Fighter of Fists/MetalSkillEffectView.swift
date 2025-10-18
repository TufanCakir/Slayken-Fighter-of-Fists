// MetalSkillEffectView.swift
import SwiftUI
import MetalKit

struct MetalSkillEffectView: UIViewRepresentable {
    let element: String
    let trigger: Bool
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.framebufferOnly = false
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        context.coordinator.setup(device: view.device!)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
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
        }
        
        var particles: [Particle] = []
        var life: Float = 0
        
        func setup(device: MTLDevice) {
            self.device = device
            commandQueue = device.makeCommandQueue()
            
            let library = device.makeDefaultLibrary()
            let vertex = library?.makeFunction(name: "basic_vertex")
            let fragment = library?.makeFunction(name: "basic_fragment")
            
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = vertex
            desc.fragmentFunction = fragment
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineState = try! device.makeRenderPipelineState(descriptor: desc)
        }
        
        func triggerIfNeeded(_ trigger: Bool, element: String) {
            guard trigger else { return }
            life = 1.0
            
            let color: SIMD4<Float>
            switch element {
            case "fire": color = SIMD4(1, 0.3, 0, 1)
            case "ice": color = SIMD4(0.4, 0.8, 1, 1)
            case "thunder": color = SIMD4(1, 1, 0.2, 1)
            case "void": color = SIMD4(0.6, 0.2, 0.8, 1)
            default: color = SIMD4(1, 1, 1, 1)
            }
            generateProjectile(color: color)
        }
        
        func generateProjectile(color: SIMD4<Float>) {
            particles = (0..<150).map { _ in
                let start = SIMD2<Float>(0, -0.7)
                let vel = SIMD2<Float>(
                    Float.random(in: -0.01...0.01),
                    Float.random(in: 0.02...0.04)
                )
                return Particle(position: start, velocity: vel)
            }
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPass = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable else { return }
            
            if life > 0 {
                life -= 0.02
                for i in 0..<particles.count {
                    particles[i].position += particles[i].velocity
                    particles[i].velocity.y += 0.0003 // acceleration
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
            let buffer = device.makeBuffer(bytes: particles.map { $0.position },
                                           length: MemoryLayout<SIMD2<Float>>.stride * particles.count,
                                           options: [])
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            var color = SIMD4<Float>(1, 0.5, 0.2, 1)
            encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particles.count)
            encoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
