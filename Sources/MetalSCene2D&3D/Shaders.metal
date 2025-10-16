#include <metal_stdlib>
using namespace metal;

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

// Pipeline principal (Renderer3D)
vertex VSOut vs_main(uint vid [[vertex_id]],
                     const device Vtx *inV [[buffer(0)]],
                     constant Uniforms &U [[buffer(1)]])
{
    VSOut o;
    o.position = U.mvp * inV[vid].pos;
    o.color    = inV[vid].col;
    return o;
}

fragment float4 fs_main(VSOut in [[stage_in]]) {
    return in.color;
}

// Pipeline de la rejilla (Grid3D)
vertex VSOut vtx_color3d(uint vid [[vertex_id]],
                         const device Vtx *inV [[buffer(0)]],
                         constant Uniforms &U [[buffer(1)]]) {
    VSOut o;
    o.position = U.mvp * inV[vid].pos;
    o.color = inV[vid].col;
    return o;
}

fragment float4 frag_color(VSOut in [[stage_in]]) {
    return in.color;
}

