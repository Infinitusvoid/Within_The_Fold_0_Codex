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
    return vec2(sin(uv.x * 6.0 + iTime * 0.3), cos(uv.y * 7.0 - iTime * 0.5));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.15 + 0.8 * sin(w.x * 3.5 + iTime * 0.15);
    float g = 0.3 + 0.7 * cos(w.y * 4.5 + iTime * 0.25);
    float b = 0.8;
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.35;
    float scale = 1.3 + 1.8 * sin(t + uv.x * 25.0);
    float shift = 1.3 + 1.8 * cos(t + uv.y * 18.0);
    uv.x *= scale;
    uv.y *= shift;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 wave_B(vec2 uv)
{
    return uv + vec2(sin(uv.x * 7.0 + iTime * 0.6) * tan(uv.y * 3.0 + iTime * 0.9), cos(uv.y * 5.5 + iTime * 0.7) * sin(uv.x * 2.0 + iTime * 0.5));
}

vec3 pattern(vec2 uv, float t)
{
    float g = sin(uv.x * 15.0 + t * 0.4);
    float h = cos(uv.y * 10.0 + t * 0.5);
    float index = (uv.x * 4.0 + uv.y * 6.0) * 22.0 - iTime * 0.06 * t;
    float v = fract(sin(index * 2.8) * 35.0);
    return vec3(g, h, 0.5 + 0.5 * sin(v + t * 1.5));
}

vec2 curl(vec2 uv)
{
    float angle = iTime * 0.5 + sin(uv.x * 1.8) * cos(uv.y * 2.2);
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    return rotationMatrix * uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Apply initial coordinate transformation
    vec2 uv_initial = uv * vec2(6.0, 3.0) - vec2(0.4, 0.2);

    // Apply Curl warping and successive transformations
    vec2 f = curl(uv_initial);
    f = curl(f);

    // Apply Wave distortion over the warped coordinates
    f = distort(f);

    // Generate two parallel colored features based on further transformations
    vec3 col1 = pattern(f, iTime * 2.2);
    vec3 col2 = pattern(f * 0.5 + iTime * 0.4, iTime * 1.9);

    // Calculate dynamic field dependency
    float f_sum = f.x * 1.5 + f.y * 1.2;
    float d = sin(f_sum * 6.0 + iTime * 1.8) * 0.5 + cos(f.x * 5.0 + iTime * 1.0);

    vec3 finalCol = col1 * 0.7 + col2 * 0.3;

    // Apply complex color interactions derived from field data
    finalCol.r = 0.2 * sin(d * 3.0) + 0.8 * sin(f.x * 11.0 + iTime * 0.6);
    finalCol.g = 0.6 * cos(f.y * 9.0 + iTime * 0.35) + 0.4 * sin(f.y * 18.0);
    finalCol.b = 1.0 - pow(abs(f.x - 0.5) * 2.0, 1.6) * f.y * 0.7; 

    // Introduce frame influence modulated by field data
    finalCol.r *= (0.9 + 0.15 * sin(iTime * 0.7 + iFrame * 0.2));
    finalCol.g *= (0.95 - 0.2 * cos(iTime * 0.5 + iFrame * 0.1));
    finalCol.b *= (0.7 + 0.3 * sin(iFrame * 0.3));

    fragColor = vec4(finalCol, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
