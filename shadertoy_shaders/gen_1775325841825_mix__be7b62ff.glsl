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

vec3 palette(float t) {
    return vec3(0.3 + 0.7*sin(t + iTime * 0.1), 0.2 + 0.8*sin(t + iTime * 0.2), 0.4 + 0.6*cos(t + iTime * 0.3));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv *= 1.0 + sin(iTime * 1.5) * 0.3;

    // Geometric transformation based on Shader A structure
    float angleA = iTime * 0.5 + uv.x * uv.y * 2.5;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    uv = rotA * uv;

    float angleB = sin(iTime * 0.7) + uv.x * uv.y * 1.5;
    uv = rotate(uv, angleB);

    // Wave application
    vec2 w = wave(uv);

    // Complex color modulation and palette application based on Shader B structure
    float t = (uv.x + uv.y) * 10.0 + iTime * 0.5;
    vec3 col = palette(t);

    // Add complex color components
    col += 0.7 * sin(iTime * 0.3 + uv.x * 1.5 + w.x * 2.0);
    col += 0.5 * sin(uv.y * 9.0 + iTime * 0.7 + w.y * 1.0);

    float freq = uv.x * 2.0 + sin(iTime * 0.5);
    float offset = sin(freq * 10.0) * 0.05;
    float v = smoothstep(0.4, 0.6, uv.y - offset);

    col.r = v;

    // Complex interactions for G and B channels
    col.g = sin(uv.x * 10.0 + iTime * 0.5 + w.x * 0.5);
    col.r = sin(col.g + iTime + 0.42 * sin(iTime * 0.2 + uv.x * 10.0));

    // Final B channel calculation
    col.b = 0.4 + 0.32 * abs(sin(abs(sin((col.g * col.r) * 32.0)) / sin((sin(col.g) / sin(col.r)) * sin(uv.x * iTime * cos(uv.y * iTime * 1.24)) * 10.0)));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
