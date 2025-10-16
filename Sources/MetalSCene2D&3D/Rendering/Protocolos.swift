import MetalKit

public enum RenderMode {
    case hud2DOnly
    case world3DOnly
    case both
}

public struct DrawItem {
    public let buffer: MTLBuffer
    public let vertexCount: Int
    public init(buffer: MTLBuffer, vertexCount: Int) {
        self.buffer = buffer
        self.vertexCount = vertexCount
    }
}

public protocol SceneProvider: AnyObject {
    func buildResources(device: MTLDevice, viewSize: CGSize)
    func update(dt: CFTimeInterval)
    func hud2DItems() -> [DrawItem]
    func world3DItems() -> [DrawItem]
}

@objc public protocol MetalCanvasGestureHandling: AnyObject {
    @objc optional func handlePan(_ g: NSPanGestureRecognizer)
    @objc optional func handleMagnify(_ g: NSMagnificationGestureRecognizer)
    @objc optional func handleRotate(_ g: NSRotationGestureRecognizer)
}

public protocol MetalRenderable: MTKViewDelegate {
    var queue: MTLCommandQueue? { get set }
    func configure(view: MTKView, mode: RenderMode, provider: SceneProvider)
    func updateMode(_ newMode: RenderMode)
}

