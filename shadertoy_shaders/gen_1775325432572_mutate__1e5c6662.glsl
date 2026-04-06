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

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 5.0 + t * 1.5),
        cos(uv.y * 4.0 + t * 0.8)
    );
}

float palette(float t) {
    t = fract(t * 3.14159);
    return 0.5 + 0.5 * sin(t * 12.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Global UV shift and distortion
    float time_shift = iTime * 0.5;
    uv += sin(uv.x * 10.0 + time_shift) * 0.05;
    uv += cos(uv.y * 10.0 + time_shift) * 0.05;

    // Rotations based on modified coordinates
    float angleA = iTime * 0.5 + uv.x * uv.y * 3.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    uv = rotA * uv;

    float angleB = sin(iTime * 0.7) + uv.x * uv.y * 2.0;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    uv = rotB * uv;

    vec2 w = wave(uv);

    // Introduce color variation based on wave influence
    float v = smoothstep(0.4, 0.6, w.x * 2.0 + w.y);

    vec3 color = vec3(
        sin(iTime * 5.0 + uv.x * 3.0 + w.x * 1.5),
        cos(iTime * 4.0 + uv.y * 4.0 + w.y * 1.0),
        sin(iTime * 6.0 + uv.x * 1.5 + uv.y * 2.0)
    );

    // Apply palette modulation
    float p = palette(iTime + uv.x * 2.0);
    color = mix(color, vec3(p * 0.8), 0.3);

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
