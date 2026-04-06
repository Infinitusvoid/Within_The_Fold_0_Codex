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
    return vec2(sin(uv.x * 7.0 + iTime * 0.5), cos(uv.y * 6.0 - iTime * 0.3));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.1 + 0.9 * sin(w.x * 4.0 + iTime * 0.1);
    float g = 0.2 + 0.8 * cos(w.y * 5.0 + iTime * 0.2);
    float b = 0.7;
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.4;
    float scale = 2.0 + 1.5 * sin(t * 2.0 + uv.x * 30.0);
    float shift = 2.0 + 1.5 * cos(t * 2.5 + uv.y * 40.0);
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
    return uv + vec2(sin(uv.x * 3.0 + iTime * 1.2) * tan(uv.y * 3.0), cos(uv.y * 4.0 + iTime * 0.7) * sin(uv.x * 2.5));
}

vec3 pattern(vec2 uv, float t)
{
    float g = sin(uv.x * 15.0 + t * 0.6);
    float h = cos(uv.y * 10.0 + t * 0.8);
    float index = (uv.x * 5.0 + uv.y * 8.0) * 18.0 - iTime * 0.03 * t;
    float v = fract(sin(index * 3.0) * 40.0);
    return vec3(g, h, 0.5 + 0.5 * sin(v + t * 3.0));
}

vec2 curl(vec2 uv)
{
    float angle = iTime * 0.6 + sin(uv.x * 2.0 + uv.y * 1.5) * cos(uv.y * 2.0);
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    return rotationMatrix * uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Apply initial coordinate transformation
    vec2 uv_initial = uv * vec2(6.0, 3.0) - vec2(0.2, 0.0);

    // Apply Curl warping and successive transformations
    vec2 f = curl(uv_initial);
    f = curl(f);
    f = distort(f);

    // Use polar coordinates derived from the warped field f
    float r = length(f);
    float a = atan(f.y, f.x);

    // Generate complex patterns based on the warped field f
    vec3 col1 = pattern(f, iTime * 2.5);
    vec3 col2 = pattern(f * 0.5 + vec2(iTime * 0.1), iTime * 2.0);

    // Calculate dynamic field dependency
    float f_sum = f.x * 1.5 + f.y * 1.0;
    float d = sin(f_sum * 6.0 + iTime * 1.8) + cos(r * 5.0 + iTime * 0.5);

    vec3 finalCol = col1 * 0.7 + col2 * 0.3;

    // Apply complex color interactions
    finalCol.r = 0.2 * sin(d * 3.0) + 0.8 * sin(f.x * 12.0 + iTime * 0.6);
    finalCol.g = 0.4 * cos(f.y * 7.0 + iTime * 0.4) + 0.5 * sin(f.y * 10.0);
    finalCol.b = 1.0 - pow(abs(f.x - 0.3), 2.0) * f.y * 0.7; 

    // Apply frame influence modulated by field data
    finalCol.r *= (0.7 + 0.3 * sin(iTime * 0.7 + iFrame * 0.1));
    finalCol.g *= (0.9 - 0.3 * cos(iTime * 0.5 + iFrame * 0.2));
    finalCol.b *= (0.5 + 0.5 * sin(iFrame * 0.3));

    // Integrate the radial effect
    float radial_effect = 1.0 - r * 0.7;
    finalCol *= (0.6 + 0.4 * radial_effect);

    fragColor = vec4(finalCol, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
