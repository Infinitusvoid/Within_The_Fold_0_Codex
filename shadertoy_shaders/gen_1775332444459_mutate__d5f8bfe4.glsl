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
    return vec2(sin(uv.x * 8.0 + iTime * 0.5), cos(uv.y * 15.0 - iTime * 0.7));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.5 + 0.5 * sin(w.x * 4.0 + iTime * 0.3);
    float g = 0.5 + 0.5 * sin(w.y * 3.2 + iTime * 0.5);
    float b = 0.5 + 0.5 * sin(w.x * 1.5 - w.y * 1.2 + iTime * 0.1);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.5;
    float scale_x = 1.0 + 0.15 * sin(t + uv.x * 25.0);
    float scale_y = 1.0 + 0.08 * cos(t + uv.y * 20.0);
    uv.x *= scale_x;
    uv.y *= scale_y;
    uv.x += iTime * 0.03;
    uv.y += iTime * 0.015;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv = distort(uv);

    float angle = iTime * 3.5 + sin(uv.x * 10.0 + uv.y * 10.0) * 1.2;
    mat2 rot = rotate(angle);
    uv = rot * uv;

    vec2 w = wave(uv);

    vec3 col = colorFromWave(w);

    float freq_x = uv.x * 15.0 + iTime * 1.6;
    float freq_y = uv.y * 12.0 + iTime * 1.1;

    float ripple = sin(freq_x * 25.0) * 0.1;

    // Primary modulation based on X coordinate and ripple
    float mix_r = smoothstep(0.25, 0.5, uv.x * 4.0 + ripple * 2.0);

    col.r = mix_r;

    // Secondary modulation based on Y coordinate and time
    float g_val = sin(freq_y * 18.0 + iTime * 0.5);
    col.g = g_val;

    // Tertiary modulation for Blue channel based on interaction
    float b_mod = sin(col.r * 1.5 + col.g * 1.5 + iTime * 0.3) * sin(uv.y * 9.0);
    col.b = 0.2 + 0.8 * b_mod;

    // Final complex channel interaction
    col.r = abs(sin(col.g * 2.0 + freq_x * 0.5 + iTime * 0.4));
    col.g = cos(col.r * 3.0 + uv.x * 13.0 + iTime * 0.2);
    col.b = sin(freq_y * 6.0 + iTime * 0.7);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
