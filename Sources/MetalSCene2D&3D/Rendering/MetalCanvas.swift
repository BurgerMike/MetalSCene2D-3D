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
        self.provider = provider
    }

    public func makeNSView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            let v = MTKView()
            v.isPaused = true
            v.enableSetNeedsDisplay = true
            return v
        }

        let v = MTKView(frame: .zero, device: device)
        v.colorPixelFormat = .bgra8Unorm
        v.depthStencilPixelFormat = .depth32Float
        v.sampleCount = 1
        v.preferredFramesPerSecond = 60
        v.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        v.framebufferOnly = true
        v.enableSetNeedsDisplay = false
        v.isPaused = false
        v.autoResizeDrawable = true

        let queue = device.makeCommandQueue()
        renderer.queue = queue
        v.delegate = renderer
        renderer.configure(view: v, mode: mode, provider: provider)

        if let h = renderer as? MetalCanvasGestureHandling {
            if h.handlePan != nil {
                let pan = NSPanGestureRecognizer(target: h, action: #selector(MetalCanvasGestureHandling.handlePan(_:)))
                v.addGestureRecognizer(pan)
            }
            if h.handleMagnify != nil {
                let mag = NSMagnificationGestureRecognizer(target: h, action: #selector(MetalCanvasGestureHandling.handleMagnify(_:)))
                v.addGestureRecognizer(mag)
            }
            if h.handleRotate != nil {
                let rot = NSRotationGestureRecognizer(target: h, action: #selector(MetalCanvasGestureHandling.handleRotate(_:)))
                v.addGestureRecognizer(rot)
            }
        }

        return v
    }

    public func updateNSView(_ nsView: MTKView, context: Context) {
        renderer.updateMode(mode)
    }
}

