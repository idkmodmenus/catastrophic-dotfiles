#version 440
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
