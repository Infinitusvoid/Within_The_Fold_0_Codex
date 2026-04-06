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
    return vec2(sin(uv.x * 6.0 + iTime * 1.2), cos(uv.y * 5.0 - iTime * 1.5));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.5 + 0.5 * sin(w.x * 2.0 + iTime * 0.4);
    float g = 0.5 + 0.5 * sin(w.y * 3.5 - iTime * 0.6);
    float b = 0.5 + 0.5 * sin(w.x * 1.5 - w.y * 1.8 + iTime * 0.2);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.4;
    float scale_x = 1.0 + 0.05 * sin(t + uv.x * 20.0);
    float scale_y = 1.0 + 0.04 * cos(t + uv.y * 12.0);
    uv.x *= scale_x;
    uv.y *= scale_y;
    uv.x += iTime * 0.1;
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

    float angle = iTime * 0.8 + sin(uv.x * 4.0 + uv.y * 3.0) * 0.2;
    mat2 rot = rotate(angle);
    uv = rot * uv;

    vec2 w = wave(uv);

    vec3 col = colorFromWave(w);

    float freq_x = uv.x * 7.0 + iTime * 0.9;
    float freq_y = uv.y * 6.0 + iTime * 0.5;

    float ripple = sin(freq_x * 12.0) * 0.15;

    float v = smoothstep(0.3, 0.7, uv.x * 2.0 + ripple);
    col.r = v;

    col.g = cos(freq_x * 9.0 + iTime * 0.3);
    col.b = 0.1 + 0.5 * sin((col.r + col.g) * 15.0 + iTime * 0.1) * cos(uv.y * 10.0);

    col.r = sin(col.g * 1.8 + iTime * 0.6);
    col.g = cos(col.r * 1.5 + uv.y * 8.0 + iTime * 0.2);
    col.b = 0.4 + 0.4 * sin(freq_y * 4.0 + iTime * 0.7);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
