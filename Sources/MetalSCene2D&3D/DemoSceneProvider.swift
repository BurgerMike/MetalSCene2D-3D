//
//  DemoSceneProvider.swift
//  MetalSCene2D&3D
//
//  Created by Miguel Carlos Elizondo Mrtinez on 15/10/25.
//

import Foundation
import simd
import MetalKit

// MARK: - Helpers de construcción de líneas

@inline(__always)
private func circlePolyline2DClip(radius: Float = 0.6, segments: Int = 160, color: SIMD4<Float>) -> [Vtx] {
    // círculo 2D en clip-space (z = 0), cerrado
    let n = max(3, segments)
    var verts: [Vtx] = []
    verts.reserveCapacity(n + 1)
    for i in 0...n {
        let t = Float(i) / Float(n) * 2 * .pi
        let x = radius * cos(t)
        let y = radius * sin(t)
        verts.append(Vtx(pos: SIMD4<Float>(x, y, 0, 1), col: color))
    }
    return verts
}

@inline(__always)
private func circlePolyline3D(radius: Float, segments: Int, axis: SIMD3<Float>, color: SIMD4<Float>) -> [Vtx] {
    // círculo 3D en el plano ortogonal a 'axis'
    let n = max(3, segments)
    var verts: [Vtx] = []
    verts.reserveCapacity(n + 1)

    // Elegimos dos vectores ortogonales al eje para definir la base del plano
    let up = simd_normalize(axis)
    let helper = abs(up.x) < 0.9 ? SIMD3<Float>(1,0,0) : SIMD3<Float>(0,1,0)
    let u = simd_normalize(simd_cross(up, helper))
    let v = simd_cross(up, u)

    for i in 0...n {
        let t = Float(i) / Float(n) * 2 * .pi
        let p = radius * (cos(t) * u + sin(t) * v) // centro en origen
        verts.append(Vtx(pos: SIMD4<Float>(p.x, p.y, p.z, 1), col: color))
    }
    return verts
}

@inline(__always)
private func makeBuffer(_ device: MTLDevice, verts: [Vtx]) -> DrawItem? {
    guard !verts.isEmpty else { return nil }
    let len = verts.count * MemoryLayout<Vtx>.stride
    guard let buf = device.makeBuffer(bytes: verts, length: len, options: []) else { return nil }
    return DrawItem(buffer: buf, vertexCount: verts.count)
}

// MARK: - Demo provider

public final class DemoSceneProvider: SceneProvider {
    private var device: MTLDevice!
    private var viewSize: CGSize = .zero

    private var hudItems: [DrawItem] = []
    private var worldItems: [DrawItem] = []

    public init() {}

    public func buildResources(device: MTLDevice, viewSize: CGSize) {
        self.device = device
        self.viewSize = viewSize
        rebuild()
    }

    public func update(dt: CFTimeInterval) {
        // animaciones si quisieras (giro, etc.). Por ahora nada.
    }

    public func viewResized(to size: CGSize) {
        self.viewSize = size
        // HUD 2D suele depender de tamaño; aquí no hace falta recomputar, pero lo dejamos por claridad.
        rebuild()
    }

    public func hud2DItems() -> [DrawItem] { hudItems }
    public func world3DItems() -> [DrawItem] { worldItems }

    // MARK: - Construcción de ejemplos

    private func rebuild() {
        guard let device else { return }

        // 2D: círculo en clip-space
        let circle2D = circlePolyline2DClip(radius: 0.7,
                                            segments: 160,
                                            color: SIMD4<Float>(0.95, 0.3, 0.3, 1))
        let hud = makeBuffer(device, verts: circle2D)

        // 3D: dos “aros de ejes”: plano XZ y plano YZ
        let ringXZ = circlePolyline3D(radius: 1.0,
                                      segments: 200,
                                      axis: SIMD3<Float>(0, 1, 0),   // eje Y → plano XZ
                                      color: SIMD4<Float>(0.2, 0.8, 1.0, 1))
        let ringYZ = circlePolyline3D(radius: 0.8,
                                      segments: 200,
                                      axis: SIMD3<Float>(1, 0, 0),   // eje X → plano YZ
                                      color: SIMD4<Float>(0.9, 0.9, 0.2, 1))

        let w1 = makeBuffer(device, verts: ringXZ)
        let w2 = makeBuffer(device, verts: ringYZ)

        hudItems = [hud,].compactMap { $0 }
        worldItems = [w1, w2].compactMap { $0 }
    }
}
