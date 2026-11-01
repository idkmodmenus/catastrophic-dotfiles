#version 440
// Directional motion blur centred on the item. `dir` is the full smear length
// in texture coordinates. Samples near the centre weigh more (tent falloff),
// so the item stays readable and the smear fades out smoothly at both ends.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 dir;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    const int N = 40;
    vec4 c = vec4(0.0);
    float total = 0.0;
    for (int i = 0; i < N; i++) {
        float t = float(i) / float(N - 1) - 0.5;
        float w = 1.0 - abs(t) * 1.6;
        c += texture(source, qt_TexCoord0 + dir * t) * w;
        total += w;
    }
    fragColor = c / total * qt_Opacity;
}
