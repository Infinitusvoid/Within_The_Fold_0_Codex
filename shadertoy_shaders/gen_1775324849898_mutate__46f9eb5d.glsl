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

vec2 wave(vec2 uv)
{
    float t = iTime * 0.5;
    float s = sin(uv.x * 8.0 + t * 0.2);
    float c = cos(uv.y * 6.0 + t * 0.1);
    return vec2(s * 0.5 + 0.5 * c, s * 0.5 - 0.5 * c);
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 3.0 + iTime * 0.1);
    float g = 0.5 + 0.5 * cos(t * 2.5 + iTime * 0.2);
    float b = 0.5 + 0.5 * sin(t * 1.5 + iTime * 0.3);
    return vec3(r, g, b);
}

vec2 distortA(vec2 uv)
{
    float t = iTime * 0.5;
    uv += vec2(sin(t + uv.x * 20.0), cos(t * 0.5 + uv.y * 15.0)) * 0.08;
    return uv;
}

vec2 waveB(vec2 uv)
{
    return uv + vec2(sin(uv.x * 4.0 + iTime * 0.3), cos(uv.y * 3.5 + iTime * 0.7));
}

vec3 colorFromWaveA(vec2 w)
{
    float r = sin(w.x * 3.5 + iTime * 0.3) * 0.5 + 0.5;
    float g = cos(w.y * 4.0 + iTime * 0.1) * 0.5 + 0.5;
    float b = sin(w.x * 2.5 - w.y * 1.5 + iTime * 0.4) * 0.5 + 0.5;
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply transformations
    uv = distortA(uv);
    uv = wave(uv);
    uv = waveB(uv);

    // Base color derived from Shader A's logic
    vec3 col = colorFromWaveA(uv);

    // Apply a dynamic palette based on combined UV values
    float t = sin(uv.x * uv.y * 12.0 + iTime * 0.5) * 0.5 + 0.5;
    vec3 palette_col = palette(t);

    // Blend colors using modulation based on UV and time
    float blend_factor = 0.5 + 0.5 * sin(uv.x * 12.0 + iTime * 0.2);
    float mod_g = 0.5 + 0.5 * cos(uv.y * 8.0 + iTime * 0.3);
    float mod_r = 0.5 + 0.5 * sin(iTime * 0.3);

    col.r = palette_col.r * mod_r;
    col.g = col.g * mod_g;
    col.b = col.b * (0.5 + 0.5 * sin(uv.x * 5.0 + iTime * 0.1));

    // Final adjustment
    col = mix(col, palette_col, 0.2);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
