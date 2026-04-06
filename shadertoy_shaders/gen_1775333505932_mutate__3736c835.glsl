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
    float r = sin(uv.x * 6.0 + t * 1.2);
    float g = cos(uv.y * 8.0 - t * 1.5);
    float b = sin(uv.x * 3.0 + uv.y * 2.0 + t * 0.8);
    return vec2(r, g);
}

vec3 colorFromWave(vec2 w)
{
    // Use the wave components to drive base colors
    float r = 0.5 + 0.5 * sin(w.x * 3.0 + iTime * 0.7);
    float g = 0.5 + 0.5 * sin(w.y * 2.5 + iTime * 0.5);
    float b = 0.5 + 0.5 * sin(w.x * 1.5 - w.y * 1.7 + iTime * 0.4);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.3;
    float scale_x = 1.0 + 0.08 * sin(t + uv.x * 15.0);
    float scale_y = 1.0 + 0.06 * cos(t + uv.y * 10.0);
    uv.x *= scale_x;
    uv.y *= scale_y;
    uv.x += iTime * 0.05;
    uv.y += iTime * 0.03;
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

    float angle = iTime * 1.5 + sin(uv.x * 5.0 + uv.y * 4.0) * 0.3;
    mat2 rot = rotate(angle);
    uv = rot * uv;

    vec2 w = wave(uv);

    vec3 col = colorFromWave(w);

    float freq_x = uv.x * 8.0 + iTime * 1.1;
    float freq_y = uv.y * 7.0 + iTime * 0.9;

    float ripple = sin(freq_x * 15.0) * 0.18;

    // Primary modulation based on X coordinate and ripple
    float mix_r = smoothstep(0.1, 0.5, uv.x * 2.5 + ripple);

    col.r = mix_r;

    // Secondary modulation based on Y coordinate and time
    float wave_y_mod = cos(freq_y * 9.0 + iTime * 0.5);

    // Introduce a secondary wave modulation for Green
    float g_mod = sin(uv.x * 4.0 + iTime * 0.3) * wave_y_mod;
    col.g = 0.5 + g_mod;

    // Tertiary modulation based on interaction
    col.b = 0.3 + 0.6 * sin((col.r + col.g) * 12.0 + iTime * 0.15) * sin(uv.y * 5.0 + iTime * 1.0);

    // Final channel swaps and complex interactions
    col.r = sin(col.g * 2.0 + iTime * 0.8);
    col.g = cos(col.r * 1.6 + uv.x * 9.0 + iTime * 0.25);
    col.b = 0.5 + 0.5 * sin(freq_x * 6.0 + iTime * 0.6);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
