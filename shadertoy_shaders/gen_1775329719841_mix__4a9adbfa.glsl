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


vec2 waveA(vec2 uv) {
    uv += vec2(sin(uv.x * 5.0 + iTime * 0.5), sin(uv.y * 3.0 + iTime * 0.3));
    uv += vec2(sin(uv.x * 4.0 + iTime * 0.6), sin(uv.y * 2.5 + iTime * 0.4));
    uv = vec2(cos(uv.x * 3.0 + iTime * 0.4), sin(uv.y * 1.2 + iTime * 0.6));
    uv = vec2(cos(uv.x * 2.0 + iTime * 0.3), sin(uv.y * 1.5 + iTime * 0.7));
    uv += vec2(tan(uv.x * (3.0 + sin(iTime * 0.4))) * 0.15, tan(uv.y * (3.0 + sin(iTime * 0.4))) * 0.1);
    return uv;
}

vec2 waveB(vec2 uv) {
    return vec2(sin(uv.x * 8.0 + iTime * 0.5), cos(uv.y * 12.0 - iTime * 0.3));
}

vec2 waveC(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 0.5), cos(uv.y * 5.0 + iTime * 0.7));
}

vec2 waveD(vec2 uv)
{
    return vec2(sin(uv.y * 6.0 + iTime * 0.3), cos(uv.x * 3.5 + iTime * 0.6));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5*sin(t * 0.7 + iTime * 0.3);
    float g = 0.4 + 0.4 * cos(t * 1.1 - iTime * 0.2);
    float b = 0.2 + 0.6 * sin(t * 1.5 + iTime * 0.1);
    return vec3(r, g, b);
}

vec3 colorFromWave(vec2 w) {
    float r = cos(w.x * 1.8 + iTime * 0.4) * 0.5 + 0.5;
    float g = sin(w.y * 1.6 - iTime * 0.3) * 0.5 + 0.5;
    float b = 0.5 + 0.5 * sin(w.x * 3.0 - w.y * 2.5 + iTime * 0.7);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    uv *= vec2(1.0 + 0.03 * sin(t + uv.x * 10.0), 1.0 + 0.03 * sin(t + uv.y * 15.0));
    return uv;
}

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    uv = distort(uv);

    // Apply wave transformations sequentially (A's complex interaction)
    uv = waveB(uv);
    uv = waveA(uv);

    // Apply rotation (B's rotation mechanism)
    float angle = iTime * 0.5 + sin(uv.x * 10.0 + iTime * 0.2) * cos(uv.y * 5.0) * 0.3;
    mat2 rot = rotate(angle);
    uv = rot * uv;

    // Apply simpler waves (B's simple interactions)
    uv = waveC(uv);
    uv = waveD(uv);

    // Use the combined UV for initial coloring
    vec2 w = uv;
    vec3 col = colorFromWave(w);

    // Use a time-dependent palette
    float t = uv.x * uv.y * 8.0 + iTime * 0.4;
    vec3 paletteCol = palette(t);
    col = mix(col, paletteCol, 0.5);

    // Introduce flow and modulation based on interaction (A's complexity)
    float freq = uv.x * 2.0 + cos(iTime * 0.5);
    float offset = cos(freq * 20.0) * 0.05;
    float v = smoothstep(0.4, 0.6, uv.y - offset);
    col.g = v;

    // Complex color manipulation mixing A's style
    col.r += 0.1 * sin(uv.y * 10.0 + iTime * 0.1);
    col.b += 0.1 * cos(uv.x * 15.0 + iTime * 0.2);
    col.g = 0.3 + 0.4 * sin((col.r + col.b) * 10.0 + iTime * 0.1) * cos(uv.y * iTime * 1.2);

    col.r = sin(col.g + iTime + 0.4 * sin(iTime * 0.2 + uv.y * 10.0));
    col.b = 0.3 + 0.2 * abs(sin(abs(sin((col.g * col.r) * 20.0)) / sin((sin(col.g) / sin(col.r)) * sin(uv.y * iTime * cos(uv.x * iTime * 1.24)) * 10.0)));

    // Final global color adjustment
    col = 0.5 + 0.5 * sin(iTime + uv.xyx * 4.0 + vec3(0,1,2));

    // Secondary flow based on orthogonal UVs (B's flow interaction)
    float freqB = uv.y * 2.0 + sin(iTime * 0.5);
    float offsetB = sin(freqB * 10.0) * 0.05;
    float vB = smoothstep(0.4, 0.6, uv.x - offsetB);
    col.r = vB;

    col.g = sin(uv.y * 10.0 + (iTime + 0.1 * sin(uv.x * 42.42 + iTime)*sin(uv.x * 100.0 + iTime)));

    col.b = 0.4 + 0.32 * abs(sin(abs(sin((col.g * col.r) * 32.0)) / sin((sin(col.g) / sin(col.r)) * sin(uv.y * iTime * cos(uv.x * iTime * 1.24)) * 10.0)));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
