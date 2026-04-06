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
    float r = sin(uv.x * 15.0 + t * 1.5);
    float g = cos(uv.y * 18.0 - t * 1.2);
    return vec2(r, g);
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.5 + 0.5 * sin(w.x * 3.0 + iTime * 0.3);
    float g = 0.5 + 0.5 * cos(w.y * 2.5 + iTime * 0.4);
    float b = 0.5 + 0.5 * sin(w.x * 1.5 - w.y * 1.0 + iTime * 0.1);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.6;
    float scale_x = 1.0 + 0.05 * sin(t + uv.x * 30.0);
    float scale_y = 1.0 + 0.05 * cos(t + uv.y * 25.0);
    uv.x *= scale_x;
    uv.y *= scale_y;
    uv.x += iTime * 0.02;
    uv.y += iTime * 0.01;
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

    // Complex angle generation for rotation
    float angle = iTime * 2.5 + uv.x * 8.0 + uv.y * 12.0;
    mat2 rot = rotate(angle);
    uv = rot * uv;

    vec2 w = wave(uv);

    vec3 col = colorFromWave(w);

    // Flow fields based on distorted coordinates and time
    float freq_x = uv.x * 20.0 + iTime * 1.8;
    float freq_y = uv.y * 16.0 + iTime * 1.6;

    // Flow calculation incorporating rotation and offset
    float flow = sin(freq_x * 25.0 + iTime * 3.0) * 0.15;

    // Primary modulation based on flow and coordinates
    float mix_r = smoothstep(0.1, 0.8, uv.x * 3.5 + flow * 3.0);

    col.r = mix_r;

    // Secondary modulation based on flow and frequency interaction
    float modulation_g = sin(freq_y * 12.0 + iTime * 0.7) * 0.5;
    float modulation_b = cos(freq_x * 10.0 + iTime * 1.0) * 0.5;

    col.g = modulation_g;
    col.b = modulation_b;

    // Final channel interaction using sine/cosine interplay
    col.r = sin(col.g * 2.5 + iTime * 1.1);
    col.g = cos(col.r * 3.0 + uv.y * 15.0 + iTime * 0.5);
    col.b = 0.5 + 0.5 * sin(freq_y * 5.0 + iTime * 0.6) * col.r;

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
