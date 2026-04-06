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
    float a = uv.x * 10.0 + iTime * 0.5;
    float b = uv.y * 8.0 - iTime * 0.4;
    return vec2(sin(a * 3.14159 * 2.0), cos(b * 1.5));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.5 + 0.5 * sin(w.x * 5.0 + iTime * 0.3);
    float g = 0.5 + 0.5 * sin(w.y * 5.0 + iTime * 0.2);
    float b = 0.2 + 0.8 * abs(sin(w.x * 6.0 - w.y * 3.0 + iTime * 0.5));
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.7;
    uv.x += sin(uv.y * 30.0 + t * 2.0) * 0.01;
    uv.y += cos(uv.x * 20.0 + t * 1.5) * 0.01;
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

    float angle = iTime * 0.8 + uv.x * uv.y * 10.0;
    mat2 rot = rotate(angle);
    uv = rot * uv;

    vec2 w = wave(uv);

    vec3 col = colorFromWave(w);

    float flow = uv.x + uv.y;
    float density = 1.0 + 0.5 * sin(flow * 5.0 + iTime * 0.5);
    float v = smoothstep(0.4, 0.6, uv.y * density);
    col.g = v;

    col.r = sin(col.g * 3.0 + iTime * 0.3);
    col.b = 0.3 + 0.6 * sin(uv.x * 12.0 + iTime * 0.2);
    col.r = mix(col.r, col.b, 0.5 + 0.5 * sin(uv.y * 15.0));

    col.g = 0.5 + 0.5 * sin(col.r * 1.5 + iTime * 0.1);
    col.b = 0.1 + 0.9 * abs(sin(col.g * col.r * 10.0 + iTime * 0.2));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
