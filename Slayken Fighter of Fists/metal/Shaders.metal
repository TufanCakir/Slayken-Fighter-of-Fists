#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
};

vertex VertexOut basic_vertex(uint vid [[vertex_id]],
                              const device float2 *vertices [[buffer(0)]]) {
    VertexOut out;
    float2 pos = vertices[vid];
    // Partikel von [-1,1] -> Viewport
    out.position = float4(pos, 0.0, 1.0);
    out.pointSize = 20.0; // 👈 macht Punkte sichtbar!
    return out;
}

fragment float4 basic_fragment(constant float4 &color [[buffer(0)]]) {
    return color;
}
