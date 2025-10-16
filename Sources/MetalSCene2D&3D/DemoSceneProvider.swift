import MetalKit
import simd

public final class DemoSceneProvider: SceneProvider {
    private var device: MTLDevice!
    private var hud:  [DrawItem] = []
    private var world:[DrawItem] = []

    public init() {}

    public func buildResources(device: MTLDevice, viewSize: CGSize) {
        self.device = device
        hud.removeAll()
        world.removeAll()

        // HUD 2D: elipse/círculo en clip-space
        do {
            let (buf, count) = makeCircle(device: device, radius: 0.4, segments: 80,
                                          color: SIMD4<Float>(0.9,0.9,0.9,1), z: 0)
            hud.append(DrawItem(buffer: buf, vertexCount: count))
        }

        // WORLD 3D: dos aros en XZ/YZ alrededor del origen
        do {
            let (b1, c1) = makeRing3D(device: device, radius: 1.0, segments: 120,
                                      color: SIMD4<Float>(0.9,0.2,0.2,1), axis: .xz)
            world.append(DrawItem(buffer: b1, vertexCount: c1))
            let (b2, c2) = makeRing3D(device: device, radius: 1.0, segments: 120,
                                      color: SIMD4<Float>(0.2,0.6,1.0,1), axis: .yz)
            world.append(DrawItem(buffer: b2, vertexCount: c2))
        }
    }

    public func update(dt: CFTimeInterval) {
        // anima si quieres (rotaciones, etc.)
    }

    public func hud2DItems() -> [DrawItem]   { hud }
    public func world3DItems() -> [DrawItem] { world }

    // MARK: - helpers
    private func makeCircle(device: MTLDevice, radius: Float, segments: Int,
                            color: SIMD4<Float>, z: Float) -> (MTLBuffer, Int) {
        var v: [Vtx] = []
        for i in 0..<segments {
            let a0 = Float(i) / Float(segments) * 2*Float.pi
            let a1 = Float(i+1) / Float(segments) * 2*Float.pi
            let p0 = SIMD4<Float>(radius*cos(a0), radius*sin(a0), z, 1)
            let p1 = SIMD4<Float>(radius*cos(a1), radius*sin(a1), z, 1)
            v.append(Vtx(p0, color))
            v.append(Vtx(p1, color))
        }
        let buf = device.makeBuffer(bytes: v, length: MemoryLayout<Vtx>.stride * v.count, options: .storageModeShared)!
        return (buf, v.count)
    }

    private enum RingAxis { case xz, yz }
    private func makeRing3D(device: MTLDevice, radius: Float, segments: Int,
                            color: SIMD4<Float>, axis: RingAxis) -> (MTLBuffer, Int) {
        var v: [Vtx] = []
        for i in 0..<segments {
            let a0 = Float(i) / Float(segments) * 2*Float.pi
            let a1 = Float(i+1) / Float(segments) * 2*Float.pi
            let c0 = cos(a0), s0 = sin(a0)
            let c1 = cos(a1), s1 = sin(a1)
            let p0, p1: SIMD4<Float>
            switch axis {
            case .xz:
                p0 = SIMD4<Float>(radius*c0, 0, radius*s0, 1)
                p1 = SIMD4<Float>(radius*c1, 0, radius*s1, 1)
            case .yz:
                p0 = SIMD4<Float>(0, radius*c0, radius*s0, 1)
                p1 = SIMD4<Float>(0, radius*c1, radius*s1, 1)
            }
            v.append(Vtx(p0, color))
            v.append(Vtx(p1, color))
        }
        let buf = device.makeBuffer(bytes: v, length: MemoryLayout<Vtx>.stride * v.count, options: .storageModeShared)!
        return (buf, v.count)
    }
}

