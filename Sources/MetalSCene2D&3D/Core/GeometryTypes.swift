import simd

public struct Vtx {
    public var pos: simd_float4
    public var col: simd_float4
    public init(_ pos: simd_float4, _ col: simd_float4) {
        self.pos = pos
        self.col = col
    }
}

/// Uniforms para el shader (MVP)
public struct Uniforms {
    public var mvp: simd_float4x4
    public init(mvp: simd_float4x4) { self.mvp = mvp }
}

