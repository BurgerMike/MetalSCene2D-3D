//
//  FormaKitAdapter.swift
//  MetalScene2Dor3D
//
//  Created by Miguel Carlos Elizondo Mrtinez on 15/10/25.
//

import MetalKit
import CoreGraphics

/// Espacios de entrada para polilíneas
public enum FKSpace {
    case clipXY                        // clip-space (x,y) z=0
    case worldXY(scale: Double, z: Double)
    case worldXZ(scale: Double, y: Double)
    case worldYZ(scale: Double, x: Double)
}

public enum FormaKitAdapter {
    /// Crea un buffer de líneas a partir de puntos 2D interpretados en el espacio indicado
    public static func makePolylineBuffer(
        device: MTLDevice,
        points: [CGPoint],
        space: FKSpace,
        color: SIMD4<Float>,
        closed: Bool = false
    ) -> (buffer: MTLBuffer, vertexCount: Int) {

        guard points.count >= 2 else {
            let buf = device.makeBuffer(length: MemoryLayout<Vtx>.stride, options: .storageModeShared)!
            return (buf, 0)
        }

        func toSIMD(_ p: CGPoint) -> SIMD3<Float> {
            switch space {
            case .clipXY:
                return SIMD3(Float(p.x), Float(p.y), 0)
            case .worldXY(let s, let z):
                return SIMD3(Float(p.x * s), Float(p.y * s), Float(z))
            case .worldXZ(let s, let y):
                return SIMD3(Float(p.x * s), Float(y), Float(p.y * s))
            case .worldYZ(let s, let x):
                return SIMD3(Float(x), Float(p.x * s), Float(p.y * s))
            }
        }

        var verts: [Vtx] = []
        verts.reserveCapacity((points.count - 1 + (closed ? 1 : 0)) * 2)

        for i in 0..<(points.count - 1) {
            let a = toSIMD(points[i]);     let b = toSIMD(points[i+1])
            verts.append(Vtx(pos: SIMD4<Float>(a, 1), col: color))
            verts.append(Vtx(pos: SIMD4<Float>(b, 1), col: color))
        }
        if closed {
            let a = toSIMD(points.last!);  let b = toSIMD(points.first!)
            verts.append(Vtx(pos: SIMD4<Float>(a, 1), col: color))
            verts.append(Vtx(pos: SIMD4<Float>(b, 1), col: color))
        }

        let byteCount = verts.count * MemoryLayout<Vtx>.stride
        guard byteCount > 0 else {
            let buf = device.makeBuffer(length: MemoryLayout<Vtx>.stride, options: .storageModeShared)!
            return (buf, 0)
        }

        let buf: MTLBuffer = verts.withUnsafeBytes { raw in
            device.makeBuffer(bytes: raw.baseAddress!, length: raw.count, options: .storageModeShared)!
        }
        return (buf, verts.count)
    }
}
