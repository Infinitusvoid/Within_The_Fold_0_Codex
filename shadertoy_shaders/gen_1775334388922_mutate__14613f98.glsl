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
    float angle = iTime * 0.4 + sin(uv.x * 1.5) * cos(uv.y * 1.5) * 1.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    return rotationMatrix * uv;
}

vec2 flow(vec2 uv)
{
    float t = iTime * 0.2;
    float angle = uv.x * 6.0 + uv.y * 3.0;
    float offset = sin(angle * 3.0 + t) * 1.5;
    float strength = cos(uv.x * 8.0 + uv.y * 8.0) * 2.0;

    float dx = cos(angle * 2.0) * strength * sin(t);
    float dy = sin(angle * 2.0) * strength * cos(t);

    return uv + vec2(dx, dy);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Initial coordinate transformation, shifted and scaled
    vec2 uv_initial = (uv * 8.0) - 4.0;

    // Apply flow warping
    vec2 f = flow(uv_initial);

    // Apply Curl warping and successive transformations
    f = curl(f);
    f = distort(f);

    // Generate dynamic components
    vec3 col1 = pattern(f, iTime * 1.5);
    vec3 col2 = pattern(f * 0.5 + iTime * 0.5, iTime * 1.7);

    // Calculate dynamic field dependency based on field and time
    float field_val = sin(f.x * 4.0 + iTime * 3.0) + cos(f.y * 5.0 + iTime * 2.5);

    // Mix colors based on the field
    vec3 baseColor = mix(col1, col2, field_val * 0.5);

    // Introduce intricate detail based on the rotated coordinates
    float noise_shift = sin(f.x * 15.0 + iTime * 0.5) * f.y;

    // Final color calculation based on field interaction
    vec3 finalCol = baseColor;
    finalCol.r = mix(finalCol.r, noise_shift * 1.5, field_val * 0.8);
    finalCol.g = mix(finalCol.g, sin(f.x * 20.0 + iTime * 0.7), field_val);
    finalCol.b = mix(finalCol.b, cos(f.y * 10.0 + iTime * 1.1), field_val * 0.5);

    // Frame and Time influence modulation
    float time_factor = sin(iTime * 0.5) * 0.5 + 0.5;
    finalCol *= (1.0 + time_factor * 0.2);

    fragColor = vec4(finalCol, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
