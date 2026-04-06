#version 330 core
uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;
uniform vec4 iDate;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform float iChannelTime[4];
uniform vec3 iChannelResolution[4];
out vec4 FragColor;

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.7) * 0.3 + 0.5;
    return uv * vec2(s, s) + vec2(sin(uv.x * 10.0 + t), cos(uv.y * 15.0 - t * 0.5));
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 5.0 + uv.y * 2.0 + t),
        cos(uv.x * 3.0 - uv.y * 1.5 + t * 0.7)
    );
}

vec3 colorFromUV(vec2 uv, float t) {
    float a = sin(uv.x * 5.0 + t * 0.3);
    float b = cos(uv.y * 7.0 - t * 0.4);
    return vec3(a, b, sin(uv.x * uv.y * 3.0 + t * 0.6));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;
    float t = iTime;

    // Apply distortion and rotation based on time
    float s = sin(t * 0.7) * 0.3 + 0.5;
    uv = uv * vec2(s, s) + vec2(sin(uv.x * 10.0 + t), cos(uv.y * 15.0 - t * 0.5));
    uv *= 1.0 + sin(t * 0.5) * 0.2;

    // Complex rotation and wave application
    float angle = sin(t * 0.3) + uv.x * uv.y * 2.0;
    uv = rotate(uv, angle);
    uv *= vec2(1.0 + sin(uv.x * uv.y * 10.0 + t * 0.5) * 0.2);
    uv = wave(uv);

    vec3 col = colorFromUV(uv, t);

    // Time-based color modulation and interaction
    col = 0.5 + 0.5 * sin(iTime * 0.5 + uv.x * 8.0 + uv.y * 4.0 + vec3(0,1,2));

    // Introduce depth and contrast via frequency control
    float freq = uv.y * 3.0 + sin(t * 0.8);
    float offset = sin(freq * 15.0) * 0.06;
    float contrast = smoothstep(0.45, 0.65, uv.x - offset);

    col.r = contrast;

    // Complex layered color mixing
    float mix_g = sin(uv.x * 15.0 + t * 0.5 + uv.y * 5.0);
    col.g = mix_g;

    col.r = sin(col.g * 1.2 + t * 0.5);
    col.b = 0.4 + 0.3 * abs(sin(abs(sin(col.g * col.r * 50.0)) / sin((sin(col.g) / sin(col.r)) * sin(uv.x * t * 2.5 + uv.y * 1.5)) * 10.0));

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
