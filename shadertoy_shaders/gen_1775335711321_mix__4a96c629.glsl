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
        sin(uv.x * 4.0 + uv.y * 3.0 + t),
        cos(uv.x * 2.0 - uv.y * 1.5 + t * 0.6)
    );
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 + 0.5 * sin(w.x * 10.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 8.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.6;
    float scale = 1.5;
    uv *= scale;
    uv.x += sin(uv.y * 5.0 + t) * 0.05;
    uv.y += cos(uv.x * 5.0 + t) * 0.05;
    return uv;
}

vec2 waveB(vec2 uv)
{
    float t = iTime * 0.8;
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.6) * 0.08,
        cos(uv.y * 2.5 - iTime * 0.4) * 0.12
    );
}

vec2 ripple(vec2 uv)
{
    float r = sin(uv.x * 5.0 + iTime * 1.5);
    float g = cos(uv.y * 6.0 + iTime * 2.0);
    return vec2(r * 0.5 + 0.5, g * 0.5 + 0.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Initial scaling and centering (from B)
    uv = uv * vec2(3.0, 2.0) - vec2(0.5, 0.5);

    // --- Wave Distortion based on A and B ---
    uv = waveB(uv);
    uv = waveA(uv);

    // Apply ripple distortion (from B)
    vec2 d = ripple(uv);
    uv = uv + d * 0.7;

    // --- Geometric Rotation (from A) ---
    float angle = iTime * 0.8;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = rotationMatrix * uv;

    // --- Complex Flow and Frequency Setup ---
    vec2 flowUV = uv * 10.0;
    float freqX = 5.0 + sin(uv.y * 5.0 + iTime * 0.5) * 3.0;
    float freqY = 7.0 + cos(uv.x * 5.0 + iTime * 0.6) * 3.0;

    // Wave generation based on flow coordinates
    vec2 w = wave(flowUV * 0.5);

    // Get base color from wave coordinates (from A)
    vec3 col = colorFromWave(w);

    // Introduce a secondary rotational warp for depth effect (from A)
    vec2 finalUV = uv * 0.5 + w * 0.5;

    // Layered coloring and modulation based on flow/frequency
    float modulation = sin(finalUV.x * 4.0 + iTime * 0.4) * 0.3;

    // Apply smoothstep based coloring
    col.r = smoothstep(0.35, 0.65, finalUV.x * freqX + modulation);
    col.g = smoothstep(0.2, 0.5, finalUV.y * freqY + modulation * 0.5);
    col.b = 0.1 + 0.5 * sin(col.r * 1.5 + col.g * 1.5 + iTime * 0.7);

    // Apply flow and pulse as offsets (from A modified for dynamism)
    col.r += sin(finalUV.x * 12.0 + iTime * 1.5) * 0.5;
    col.g += cos(finalUV.y * 10.0 + iTime * 1.0) * 0.5;
    col.b += 0.3 * sin(finalUV.x * 8.0 + finalUV.y * 8.0 + iTime * 0.6);

    // Final complex transformation
    col.r = pow(col.g * 1.2 + iTime, 1.4) * 0.5 + 0.4;
    col.g = sin(col.r * 9.0 - finalUV.y * 5.0 + iTime * 0.5) * 0.5 + 0.5;
    col.b = 0.5 + 0.5 * sin(finalUV.x * 11.0 + finalUV.y * 11.0 + iTime * 0.8);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
