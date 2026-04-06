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
        sin(uv.x * 4.0 + uv.y * 3.0 + t) * cos(uv.x * 2.0 + t * 0.3),
        cos(uv.x * 2.0 - uv.y * 1.5 + t * 0.6) + sin(uv.y * 5.0 + t)
    );
}

float palette(float t) {
    t = fract(t * 0.5);
    return 0.5 + 0.5 * sin(6.28319 * t);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv *= 1.0 + sin(iTime * 0.5) * 0.2;

    float angleA = iTime * 0.3 + uv.x * uv.y * 2.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    uv = rotA * uv;

    float angleB = sin(iTime * 0.5) + uv.x * uv.y * 1.5;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    uv = rotB * uv;

    vec2 w = wave(uv);

    vec3 col = 0.5 + 0.5 * sin(iTime + w.xyx * 3.0 + vec3(0,1,2));
    float freq = w.x * 2.0 + sin(iTime * 0.5);
    float offset = sin(freq * 10.0) * 0.05;
    float v = smoothstep(0.4, 0.6, w.y - offset);
    col.r = v;

    float val = sin(uv.x * 12.0 + iTime) * cos(uv.y * 18.0 + iTime);
    vec3 col2 = vec3(palette(val), palette(val + 0.4), palette(val + 0.8));
    col.g = 0.4 + 0.32 * abs(sin(abs(sin((col2.b * col2.r) * 32.0)) / sin((sin(col2.b) / sin(col2.r)) * sin(uv.y * iTime * cos(uv.x * iTime * 1.24)) * 10.0)));

    col.b = sin(uv.y * 10.0 + (iTime + 0.2 * sin(uv.x * 42.42 + iTime)*sin(uv.x * 100.0 + iTime)));
    col.r = sin(col.b + iTime + 0.42 * sin(iTime * 0.2 + uv.y * 10.0));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
