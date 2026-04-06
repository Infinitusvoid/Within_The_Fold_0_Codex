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

vec2 flow(vec2 uv, float t)
{
    float angle = uv.x * 15.0 + uv.y * 15.0 + t * 1.5;
    float radius = length(uv - 0.5);
    float flow_val = sin(angle * 3.0 + radius * 5.0) * 0.5 + 0.5;
    return uv + flow_val * 0.05;
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 0.4), cos(uv.y * 5.0 - iTime * 0.7));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.8) * 0.15,
        cos(uv.y * 5.0 + iTime * 0.4) * 0.25
    );
}

vec3 palette(float t)
{
    vec3 c = vec3(0.1 + 0.5*sin(t + iTime * 0.2), 0.5 + 0.4*cos(t + iTime * 0.1), 0.9 - 0.3*sin(t + iTime * 0.3));
    return c * 1.5;
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.3;
    float scale = 1.5 + 1.5 * sin(t + uv.x * 20.0);
    float shift = 1.5 + 1.5 * cos(t + uv.y * 15.0);
    uv.x *= scale;
    uv.y *= shift;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 curl(vec2 uv)
{
    float angle = iTime * 0.4 + sin(uv.x * 1.5) * cos(uv.y * 1.5);
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    return rotationMatrix * uv;
}

vec3 pattern(vec2 uv, float t)
{
    float g = sin(uv.x * 12.0 + t * 0.5);
    float h = cos(uv.y * 8.0 + t * 0.6);
    float index = (uv.x * 3.0 + uv.y * 4.0) * 20.0 - iTime * 0.05 * t;
    float v = fract(sin(index * 2.5) * 30.0);
    return vec3(g, h, 0.5 + 0.5 * sin(v + t * 2.0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial coordinate transformation derived from B
    vec2 uv_initial = uv * vec2(5.0, 2.0) - vec2(0.5, 0.1);

    // Apply complex coordinate warping (Curl)
    vec2 f = curl(uv_initial);
    f = curl(f);

    // Apply Flow warping (from A)
    f = flow(f, iTime);

    // Apply Wave distortion (from B)
    f = distort(f);

    // Generate detailed patterns
    vec3 col1 = pattern(f, iTime * 2.0);
    vec3 col2 = pattern(f * 0.4 + iTime * 0.5, iTime * 1.8);

    // Calculate dynamic field dependency
    float f_sum = f.x + f.y;
    float d = sin(f_sum * 5.0 + iTime * 1.5) + cos(f.x * 6.0 + iTime * 0.8);

    vec3 finalCol = col1 * 0.6 + col2 * 0.4;

    // Apply complex color interactions derived from field data (A style mixing)
    finalCol.r = 0.3 * sin(d * 2.0) + 0.7 * sin(f.x * 10.0 + iTime * 0.5);
    finalCol.g = 0.5 * cos(f.y * 8.0 + iTime * 0.3) + 0.3 * sin(f.y * 15.0);
    finalCol.b = 0.9 - pow(abs(f.x - 0.5), 1.5) * f.y * 0.5; 

    // Introduce frame influence modulated by field data
    finalCol.r *= (0.8 + 0.2 * sin(iTime * 0.6 + iFrame * 0.15));
    finalCol.g *= (1.0 - 0.3 * cos(iTime * 0.4 + iFrame * 0.2));
    finalCol.b *= (0.6 + 0.4 * sin(iFrame * 0.2));

    fragColor = vec4(finalCol, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
