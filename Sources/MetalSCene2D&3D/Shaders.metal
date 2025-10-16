#include <metal_stdlib>
using namespace metal;

struct GridVertex {
    float3 position;
    float4 color;
};

struct GridUniforms {
    float4x4 mvp;
};

struct VOut {
    float4 position [[position]];
    float4 color;
};

vertex VOut vtx_color3d(uint vid [[vertex_id]],
                        const device GridVertex *verts [[buffer(0)]],
                        constant GridUniforms &U [[buffer(1)]])
{
    VOut o;
    o.position = U.mvp * float4(verts[vid].position, 1.0);
    o.color = verts[vid].color;
    return o;
}

fragment float4 frag_color(VOut in [[stage_in]]) {
    return in.color;
}

