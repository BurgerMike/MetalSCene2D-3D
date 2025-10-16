import MetalKit
import simd

public enum RenderMode { case hud2DOnly, world3DOnly, both }

public struct DrawItem {
    public let buffer: MTLBuffer
    public let vertexCount: Int
    public init(buffer: MTLBuffer, vertexCount: Int) {
        self.buffer = buffer; self.vertexCount = vertexCount
    }
}

/// Proveedor de escena (lo implementas para cambiar contenido)
public protocol SceneProvider: AnyObject {
    func buildResources(device: MTLDevice, viewSize: CGSize)
    func update(dt: Double)
    func hud2DItems() -> [DrawItem]     // clip-space (MVP identidad)
    func world3DItems() -> [DrawItem]   // mundo 3D (usa MVP 3D)
}

@objc public protocol InputHandler: AnyObject {
    @objc optional func handlePan(_ g: NSPanGestureRecognizer)
    @objc optional func handleMagnify(_ g: NSMagnificationGestureRecognizer)
    @objc optional func handleScroll(_ e: NSEvent)
}

public protocol MetalRenderable: AnyObject, MTKViewDelegate, InputHandler {
    var queue: MTLCommandQueue? { get set }
    func configure(view: MTKView, mode: RenderMode, provider: SceneProvider)
}

