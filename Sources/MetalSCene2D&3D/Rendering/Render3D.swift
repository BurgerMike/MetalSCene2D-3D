import MetalKit
import simd
import CoreGraphics

public final class Renderer3D: NSObject, MetalRenderable {
    public var queue: MTLCommandQueue?
    private var pipeline: MTLRenderPipelineState!
    private var uBuf: MTLBuffer!
    private weak var provider: SceneProvider?
    private var mode: RenderMode = .both

    // cámara orbital
    private var yaw: Float = 0, pitch: Float = -0.25, radius: Float = 3
    private var eye = SIMD3<Float>(0,1.5,3), target = SIMD3<Float>(0,0,0), up = SIMD3<Float>(0,1,0)
    private var lastTS: CFTimeInterval = CACurrentMediaTime()
    private var fovY: Float = .pi/3, nearZ: Float = 0.01, farZ: Float = 100

    public override init() {}

    public func configure(view: MTKView, mode: RenderMode, provider: SceneProvider) {
        self.mode = mode
        self.provider = provider
        guard let device = view.device else { return }
        let lib = try! device.makeDefaultLibrary(bundle: .module) // shaders del package

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction   = lib.makeFunction(name: "vs_main")
        desc.fragmentFunction = lib.makeFunction(name: "fs_main")
        desc.colorAttachments[0].pixelFormat = view.colorPixelFormat
        // sin depth

        pipeline = try! device.makeRenderPipelineState(descriptor: desc)
        uBuf = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)

        provider.buildResources(device: device, viewSize: view.drawableSize)
        updateEyeFromOrbit()
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if let d = view.device { provider?.buildResources(device: d, viewSize: size) }
    }

    public func draw(in view: MTKView) {
        // dt
        let now = CACurrentMediaTime()
        var dt = now - lastTS; lastTS = now
        if !dt.isFinite || dt <= 0 { dt = 1/240.0 }; if dt > 0.050 { dt = 0.050 }
        provider?.update(dt: dt)

        guard let rpd = view.currentRenderPassDescriptor,
              let cb  = queue?.makeCommandBuffer(),
              let enc = cb.makeRenderCommandEncoder(descriptor: rpd),
              let drawable = view.currentDrawable else { return }

        enc.setRenderPipelineState(pipeline)

        // === WORLD 3D ===
        if mode == .world3DOnly || mode == .both {
            let aspect = max(Float(view.drawableSize.width / max(view.drawableSize.height, 1)), 0.0001)
            let P = perspectiveRH(fovy: fovY, aspect: aspect, nearZ: nearZ, farZ: farZ)
            let V = lookAtRH(eye: eye, target: target, up: up)
            var U3D = Uniforms(mvp: P * V * matrix_identity_float4x4)
            memcpy(uBuf.contents(), &U3D, MemoryLayout<Uniforms>.stride)
            enc.setVertexBuffer(uBuf, offset: 0, index: 1)

            for item in provider?.world3DItems() ?? [] where item.vertexCount > 0 {
                enc.setVertexBuffer(item.buffer, offset: 0, index: 0)
                enc.drawPrimitives(type: .line, vertexStart: 0, vertexCount: item.vertexCount)
            }
        }

        // === HUD 2D ===
        if mode == .hud2DOnly || mode == .both {
            var U2D = Uniforms(mvp: matrix_identity_float4x4)
            memcpy(uBuf.contents(), &U2D, MemoryLayout<Uniforms>.stride)
            enc.setVertexBuffer(uBuf, offset: 0, index: 1)

            for item in provider?.hud2DItems() ?? [] where item.vertexCount > 0 {
                enc.setVertexBuffer(item.buffer, offset: 0, index: 0)
                enc.drawPrimitives(type: .line, vertexStart: 0, vertexCount: item.vertexCount)
            }
        }

        enc.endEncoding()
        cb.present(drawable)
        cb.commit()
    }

    // MARK: - cámara
    private func updateEyeFromOrbit() {
        let minP: Float = -.pi*0.49, maxP: Float = .pi*0.49
        pitch = max(min(pitch, maxP), minP)
        let cx = radius * cos(pitch) * sin(yaw)
        let cy = radius * sin(pitch)
        let cz = radius * cos(pitch) * cos(yaw)
        eye = SIMD3<Float>(cx, cy, cz)
    }
    private func perspectiveRH(fovy: Float, aspect: Float, nearZ: Float, farZ: Float) -> simd_float4x4 {
        let y = 1.0 / tan(fovy * 0.5); let x = y / aspect
        let z = farZ / (nearZ - farZ); let wz = (farZ * nearZ) / (nearZ - farZ)
        return simd_float4x4(
            SIMD4<Float>(x,0,0,0), SIMD4<Float>(0,y,0,0),
            SIMD4<Float>(0,0,z,-1), SIMD4<Float>(0,0,wz,0))
    }
    private func lookAtRH(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
        let z = simd_normalize(eye - target)
        let x = simd_normalize(simd_cross(up, z))
        let y = simd_cross(z, x)
        let t = SIMD3<Float>(-simd_dot(x, eye), -simd_dot(y, eye), -simd_dot(z, eye))
        return simd_float4x4(SIMD4<Float>(x.x,y.x,z.x,0), SIMD4<Float>(x.y,y.y,z.y,0),
                             SIMD4<Float>(x.z,y.z,z.z,0), SIMD4<Float>(t.x,t.y,t.z,1))
    }

    // MARK: - gestos
    public func handlePan(_ g: NSPanGestureRecognizer) {
        #if os(macOS)
        let p = g.translation(in: g.view)
        yaw   -= Float(p.x) * 0.005
        pitch -= Float(p.y) * 0.003
        updateEyeFromOrbit()
        #endif
    }
    public func handleMagnify(_ g: NSMagnificationGestureRecognizer) {
        #if os(macOS)
        let f = Float(1.0 + g.magnification)
        radius = max(0.5, min(20.0, radius * (1.0 + (1.0 - f))))
        updateEyeFromOrbit()
        #endif
    }
}

