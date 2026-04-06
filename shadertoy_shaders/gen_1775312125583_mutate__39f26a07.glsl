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
    return vec2(sin(uv.x * 2.0 + uv.y * 1.5 + t), cos(uv.x * 1.0 - uv.y * 0.8 + t * 0.3));
}

vec3 colorFromWave(vec2 w)
{
    float r = sin(w.x + iTime * 0.2) * 0.5 + 0.5;
    float g = cos(w.y + iTime * 0.1) * 0.5 + 0.5;
    float b = 0.3 + 0.7 * sin(w.x * 2.0 - w.y * 1.5 + iTime * 0.4);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.5;
    uv += vec2(sin(t + uv.x * 10.0), cos(t + uv.y * 15.0)) * 0.05;
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

    float angle = 0.3 + iTime * 0.2 + uv.x * sin(iTime + uv.y);
    mat2 rot = rotate(angle);
    uv = rot * uv;

    vec2 w = wave(uv);

    vec3 col = colorFromWave(w);

    float freq = uv.x * 3.0 + sin(iTime * 0.3);
    float offset = sin(freq * 12.0) * 0.05;
    float v = smoothstep(0.4, 0.6, uv.y - offset);
    col *= v;

    col.r += 0.1 * sin(uv.y * 10.0 + iTime * 0.1);
    col.g += 0.1 * cos(uv.x * 15.0 + iTime * 0.2);
    col.b = 0.4 + 0.3 * abs(sin(abs(sin((col.r + col.g) * 16.0)) / sin((sin(col.r) / sin(col.g)) * sin(uv.x * iTime * cos(uv.y * iTime * 1.24)) * 10.0)));

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
