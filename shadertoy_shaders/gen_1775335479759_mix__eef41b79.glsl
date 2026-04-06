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

vec2 flow(vec2 uv)
{
    float a = iTime * 0.5;
    float b = iTime * 0.3;
    float flow_x = sin(uv.x * 5.0 + a) * cos(uv.y * 3.0 + b);
    float flow_y = cos(uv.y * 4.0 + a) * sin(uv.x * 2.0 + b);
    return uv + vec2(flow_x * 0.5, flow_y * 0.5);
}

vec3 ripple(vec2 uv)
{
    float time_factor = iTime * 1.8;
    float val = sin(uv.x * 12.0 + time_factor) * cos(uv.y * 8.0 - time_factor * 0.5);
    return vec3(val, 1.0 - val, 0.5);
}

vec2 wave(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 0.4), cos(uv.y * 5.0 - iTime * 0.7));
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

    // Apply initial coordinate transformation (from B)
    vec2 uv_initial = uv * vec2(6.0, 3.0) - vec2(0.7, 0.2);

    // Apply Curl warping and successive transformations (from B)
    vec2 f = curl(uv_initial);
    f = curl(f);

    // Apply Wave distortion over the warped coordinates (from B)
    f = distort(f);

    // Apply Flow warping (from A)
    vec2 flow_uv = flow(f);

    // Apply Ripple distortion based on flow (from A)
    vec3 r = ripple(flow_uv * 1.5);

    // Generate complex pattern features (from B)
    vec3 col1 = pattern(f, iTime * 2.5);
    vec3 col2 = pattern(f * 0.3 + iTime * 0.1, iTime * 1.9);

    // Calculate dynamic field dependency (from B)
    float f_sum = f.x * 0.5 + f.y * 1.5;
    float d = sin(f_sum * 6.0 + iTime * 2.0) + cos(f.x * 8.0 + iTime * 1.2);

    vec3 finalCol = col1 * 0.7 + col2 * 0.3;

    // Apply complex color interactions derived from field data (from B)
    finalCol.r = 0.2 * sin(d * 3.0) + 0.8 * sin(f.x * 12.0 + iTime * 0.7);
    finalCol.g = 0.6 * cos(f.y * 7.0 + iTime * 0.5) + 0.4 * sin(f.y * 18.0);
    finalCol.b = 1.0 - pow(abs(f.x - 0.45), 2.0) * f.y * 0.8; 

    // Introduce frame influence modulated by field data (from B)
    finalCol.r *= (0.7 + 0.3 * sin(iTime * 0.7 + iFrame * 0.2));
    finalCol.g *= (1.0 - 0.25 * cos(iTime * 0.5 + iFrame * 0.3));
    finalCol.b *= (0.5 + 0.5 * sin(iFrame * 0.3));

    // Final color based on ripple effect
    finalCol = mix(finalCol, r, 0.5);

    fragColor = vec4(finalCol, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
