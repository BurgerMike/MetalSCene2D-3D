//
//  File.metal
//  MetalScene2Dor3D
//
//  Created by Miguel Carlos Elizondo Mrtinez on 15/10/25.
//

#include <metal_stdlib>
using namespace metal;

// ===== Debe reflejar GeometryTypes.swift =====
// Swift: public struct Vtx { var pos: SIMD4<Float>; var col: SIMD4<Float> }
// Swift: public struct Uniforms { var mvp: simd_float4x4 }
struct Vtx {
    float4 pos;
    float4 col;
};

struct Uniforms {
    float4x4 mvp;
};

struct VSOut {
    float4 position [[position]];
    float4 color;
};

// Vertex shader: toma vértices desde buffer(0) por índice, usa MVP en buffer(1)
vertex VSOut vs_main(uint vid                      [[vertex_id]],
                     constant Vtx      *inVerts    [[buffer(0)]],
                     constant Uniforms &U          [[buffer(1)]])
{
    VSOut out;
    Vtx v = inVerts[vid];
    out.position = U.mvp * v.pos;
    out.color    = v.col;
    return out;
}

// Fragment: colorea tal cual
fragment float4 fs_main(VSOut in [[stage_in]])
{
    return in.color;
}

