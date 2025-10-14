#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct GradientUniforms {
    float4 topColor;
    float4 bottomColor;
    float4 bossColor;
    float intensity;   // 🔹 Kontrolle über Boss-Tint-Stärke
    float height;      // 🔹 Dynamische Höhe (Viewport)
};

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant GradientUniforms &uniforms [[buffer(0)]]) {

    // 🔹 Normalisierte Y-Koordinate (0 = unten, 1 = oben)
    float gradient = saturate(in.uv.y);

    // 🔹 Grundfarbverlauf
    float4 baseColor = mix(uniforms.bottomColor, uniforms.topColor, gradient);

    // 🔹 Subtiler Boss-Tint mit glühendem Einfluss
    float tintFactor = uniforms.intensity * smoothstep(0.3, 1.0, gradient);
    float3 tinted = mix(baseColor.rgb, uniforms.bossColor.rgb, tintFactor);

    // 🔹 Optionale atmosphärische Tiefe (leicht dunkler nach unten)
    float depthFade = smoothstep(0.0, 1.0, gradient);
    tinted *= mix(0.8, 1.0, depthFade);

    return float4(tinted, 1.0);
}
