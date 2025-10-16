import SwiftUI
import MetalKit

public struct MetalCanvas<R: MetalRenderable>: NSViewRepresentable {
    public typealias NSViewType = MTKView

    private let renderer: R
    private let mode: RenderMode
    private let provider: SceneProvider

    public init(renderer: R, mode: RenderMode = .both, provider: SceneProvider) {
        self.renderer = renderer
        self.mode = mode
        self.provider = provider   // ← NO 'this', debe ser 'self'
    }

    public func makeNSView(context: Context) -> MTKView {
        let v = MTKView()
        v.device = MTLCreateSystemDefaultDevice()
        v.colorPixelFormat = .bgra8Unorm
        v.depthStencilPixelFormat = .invalid   // líneas → sin depth
        v.framebufferOnly = true
        v.enableSetNeedsDisplay = false
        v.isPaused = false

        v.delegate = renderer
        renderer.queue = v.device?.makeCommandQueue()
        renderer.configure(view: v, mode: mode, provider: provider)

        // gestos básicos
        let pan = NSPanGestureRecognizer(target: renderer, action: #selector(Renderer3D.handlePan(_:)))
        v.addGestureRecognizer(pan)
        let mag = NSMagnificationGestureRecognizer(target: renderer, action: #selector(Renderer3D.handleMagnify(_:)))
        v.addGestureRecognizer(mag)

        return v
    }

    public func updateNSView(_ nsView: MTKView, context: Context) {}
}

