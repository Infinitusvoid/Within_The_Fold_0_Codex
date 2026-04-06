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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.1,0.4,0.7)+t)); }

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

    // Apply initial coordinate transformation (from A)
    vec2 uv_initial = uv * vec2(5.0, 2.0) - vec2(0.5, 0.1);

    // Apply Curl warping and successive transformations (from A)
    vec2 f = curl(uv_initial);
    f = curl(f);
    f = distort(f);

    // Use polar coordinates derived from the warped field f (from B)
    float r = length(f);
    float a = atan(f.y, f.x);

    // Generate complex patterns based on the warped field f (from A)
    vec3 col1 = pattern(f, iTime * 2.0);
    vec3 col2 = pattern(f * 0.4 + iTime * 0.5, iTime * 1.8);

    // Calculate dynamic field dependency (from A)
    float f_sum = f.x + f.y;
    float d = sin(f_sum * 5.0 + iTime * 1.5) + cos(f.x * 6.0 + iTime * 0.8);

    vec3 finalCol = col1 * 0.6 + col2 * 0.4;

    // Apply complex color interactions derived from field data (from A)
    finalCol.r = 0.3 * sin(d * 2.0) + 0.7 * sin(f.x * 10.0 + iTime * 0.5);
    finalCol.g = 0.5 * cos(f.y * 8.0 + iTime * 0.3) + 0.3 * sin(f.y * 15.0);
    finalCol.b = 0.9 - pow(abs(f.x - 0.5), 1.5) * f.y * 0.5; 

    // Apply frame influence modulated by field data (from A)
    finalCol.r *= (0.8 + 0.2 * sin(iTime * 0.6 + iFrame * 0.15));
    finalCol.g *= (1.0 - 0.3 * cos(iTime * 0.4 + iFrame * 0.2));
    finalCol.b *= (0.6 + 0.4 * sin(iFrame * 0.2));

    // Integrate the radial effect (from B) into the color intensity
    float radial_effect = 1.0 - r * 0.5;
    finalCol *= (0.5 + 0.5 * radial_effect);

    // Introduce a second layer of color modification based on the angle 'a'
    finalCol.r += 0.1 * sin(a * 10.0 + iTime * 1.5);
    finalCol.g += 0.1 * cos(a * 5.0 + iTime * 1.0);
    finalCol.b += 0.1 * sin(r * 15.0 + iTime * 0.5);

    fragColor = vec4(finalCol, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
