//
//  GeometryTypes.swift
//  MetalScene2Dor3D
//
//  Created by Miguel Carlos Elizondo Mrtinez on 15/10/25.
//

import simd

public struct Vtx {
    public var pos: SIMD4<Float>
    public var col: SIMD4<Float>
    public init(pos: SIMD4<Float>, col: SIMD4<Float>) { self.pos = pos; self.col = col }
}

public struct Uniforms {
    public var mvp: simd_float4x4
    public init(mvp: simd_float4x4) { self.mvp = mvp }
}
