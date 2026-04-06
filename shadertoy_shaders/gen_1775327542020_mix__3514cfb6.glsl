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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 0.5), cos(uv.y * 10.0 + iTime * 0.3));
}

vec2 waveA_blend(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.8) * 0.1,
        cos(uv.y * 5.0 + iTime * 0.4) * 0.2
    );
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.4*sin(t + iTime * 0.2), 0.4 + 0.4*cos(t + iTime * 0.1), 0.7 + 0.3*sin(t + iTime * 0.3));
}

float sq(float x)
{
    return x * x;
}

/** Extracts a generic wave function component */
vec2 generate_waves(vec2 uv)
{
    vec2 w1 = waveB(uv);
    vec2 w2 = waveA_blend(uv);
    return w1 + w2;
}

// B Helper functions potentially useful
vec3 colorFromInteraction(vec2 w)
{
    float r = 0.5 + 0.5 * sin(w.x * 3.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * sin(w.y * 2.5 - iTime * 0.7);
    float b = 0.5 + 0.5 * sin(w.x * 1.5 - w.y * 1.7 + iTime * 0.3);
    return vec3(r, g, b);
}

// Applying a combined, noisy deformation technique
vec2 distort(vec2 uv)
{
    float t_mod = iTime * 0.5;
    float scale_x = 1.0 + 0.1 * sin(t_mod + uv.x * 30.0);
    float scale_y = 1.0 + 0.12 * cos(t_mod + uv.y * 25.0);
    uv.x *= scale_x;
    uv.y *= scale_y;
    uv.x += iTime * 0.15;
    uv.y += iTime * 0.1;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // 1. Initial distortion from B
    uv = distort(uv);

    // 2. Add temporal movement mixing coordinates and wave component
    uv = waveB(uv);
    // uv is the wavy version incorporating time movement effects inherently set by uv structure. 
    // Applying structure combining wave deformation A and B explicit positioning relies on adjusting the spatial structure heavily.

    // Use rotation similar to B for dynamic warping derived from spatial interaction
    float rotation_source = iTime * 1.1 + sin(uv.x * 5.0 + uv.y * 5.0) * 0.3;
    mat2 rot = rotate(rotation_source);
    uv = rot * uv;

    // B Final wave reading
    vec2 w = waveB(uv);

    // Primary Color setup: Color derived using a function influenced by the layered wave
    vec3 col = colorFromInteraction(w);

    // Secondary complex detail based on texture changes from B
    float freq_x = uv.x * 8.0 + iTime * 1.2;
    float freq_y = uv.y * 7.0 + iTime * 0.8;

    float ripple = sin(freq_x * 15.0) * 0.18;

    // Intensity gating via interaction derived waves
    float intensity = smoothstep(0.35, 0.8, uv.x * 2.5 + ripple);

    col.r = intensity;

    // Refined detail layers inspired by B's specific feedback mechanism
    col.g = 0.5 + 0.5 * sin(freq_x * 9.0 + iTime * 0.4);
    col.b = 0.2 + 0.5 * sin((col.r + col.g) * 20.0 + iTime * 0.15) * cos(uv.y * 11.0);

    // Final UV/Color modulation step derived from B, enhanced spatially
    col.r = sin(col.g * 2.2 + iTime * 0.7);
    col.g = cos(col.r * 1.8 + uv.y * 9.0 + iTime * 0.3);
    col.b = 0.6 + 0.4 * sin(freq_y * 3.5 + iTime * 0.6);

    // Final implicit wave addition/influence derived from specific A coordinates modulation
    col += sin(float(uv.x + iTime) * 1.5) * 0.1;

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
