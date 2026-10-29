#include <metal_stdlib>
using namespace metal;

// Dynamic stitchable Metal Shaders compiled into the app's default Metal library.
// SwiftUI distortionEffect/colorEffect (iOS 17+) invokes these in the foreground only.
[[ stitchable ]] float2 bloubWarp(float2 position, float time, float strength) {
    float shiftX = sin(position.y * 0.065 + time * 5.0) * strength * 17.0;
    float shiftY = cos(position.x * 0.052 - time * 4.1) * strength * 8.0;
    return position + float2(shiftX, shiftY);
}

[[ stitchable ]] half4 bloubColorShift(float2 position, half4 color, float time, float strength) {
    float wave = sin(position.x * 0.045 + position.y * 0.02 + time * 7.0);
    half bias = half(wave * strength * 0.22);
    return half4(clamp(color.r + bias, half(0), half(1)),
                 clamp(color.g + bias * half(0.45), half(0), half(1)),
                 clamp(color.b - bias * half(0.7), half(0), half(1)),
                 color.a);
}
