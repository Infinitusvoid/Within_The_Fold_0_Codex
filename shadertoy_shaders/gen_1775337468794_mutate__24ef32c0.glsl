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
    return vec2(sin(uv.x * 5.0 + iTime * 0.4), cos(uv.y * 5.0 - iTime * 0.7));
}

vec3 colorFromWave(vec2 w)
{
    float r = 0.1 + 0.9 * sin(w.x * 3.0 + iTime * 0.1);
    float g = 0.2 + 0.8 * cos(w.y * 4.0 + iTime * 0.2);
    float b = 0.7;
    return vec3(r, g, b);
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

vec2 wave_B(vec2 uv)
{
    return uv + vec2(sin(uv.x * 5.0 + iTime * 0.5) * tan(uv.y * 2.0 + iTime * 0.8), cos(uv.y * 3.0 + iTime * 0.6) * sin(uv.x * 1.5 + iTime * 0.5));
}

vec3 pattern(vec2 uv, float t)
{
    float g = sin(uv.x * 12.0 + t * 0.5);
    float h = cos(uv.y * 8.0 + t * 0.6);
    float index = (uv.x * 3.0 + uv.y * 4.0) * 20.0 - iTime * 0.05 * t;
    float v = fract(sin(index * 2.5) * 30.0);
    return vec3(g, h, 0.5 + 0.5 * sin(v + t * 2.0));
}

vec2 curl(vec2 uv)
{
    float angle = iTime * 0.4 + sin(uv.x * 1.5) * cos(uv.y * 1.5);
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    return rotationMatrix * uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Define initial complex flow based on coordinates
    vec2 flow = uv * vec2(6.0, 3.0) - vec2(0.2, 0.15);

    // Apply Curl warping multiple times for dense swirling effect
    vec2 f = curl(flow);
    f = curl(f);
    f = curl(f);

    // Apply wave distortion
    f = distort(f);

    // Generate primary and secondary pattern colors
    vec3 col1 = pattern(f * 1.2, iTime * 2.5);
    vec3 col2 = pattern(f * 0.8 + iTime * 0.5, iTime * 1.9);

    // Calculate dynamic field dependency based on the warped coordinates
    float f_sum = f.x * 2.0 + f.y * 1.5;
    float d = sin(f_sum * 5.0 + iTime * 1.8) + cos(f.x * 7.0 + iTime * 1.1);

    vec3 finalCol = col1 * 0.5 + col2 * 0.5;

    // Introduce subtle color shifts based on the spatial variation
    finalCol.r = colorFromWave(f * 2.0).r * 0.7 + 0.2;
    finalCol.g = colorFromWave(f * 1.5).g * 0.8 + 0.1;
    finalCol.b = colorFromWave(f * 3.0).b * 0.9;

    // Modulate colors using the field influence 'd' and time
    finalCol *= (0.5 + 0.5 * sin(d * 1.5 + iTime * 0.5));

    // Apply final time and frame influence
    finalCol.r += sin(iTime * 3.0) * 0.1;
    finalCol.g += cos(iTime * 2.5) * 0.05;
    finalCol.b += sin(iFrame * 2.0) * 0.15;

    fragColor = vec4(finalCol, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
