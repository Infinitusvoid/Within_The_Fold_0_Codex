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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.0,0.25,0.6)+t)); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // --- Shader A: Field Warping ---

    // Apply initial coordinate transformation (From A)
    vec2 uv_initial = uv * vec2(6.0, 3.0) - vec2(0.5, 0.2);

    // Apply Curl warping and successive transformations (From A)
    vec2 f = curl(uv_initial);
    f = curl(f);

    // Apply Wave distortion (From A)
    f = distort(f);

    // Generate complex pattern based on field data (From A)
    float time_offset = iTime * 3.0;
    vec3 base_color = pattern(f * 1.5, time_offset);

    // Introduce secondary layer based on field data (From A)
    vec3 secondary_layer = pattern(f * 0.8 + iTime * 1.0, time_offset * 0.5);

    // Calculate dynamic field dependency (From A)
    float f_sum = f.x * 2.0 + f.y * 3.0;
    float d = sin(f_sum * 6.0 + iTime * 1.5) + cos(f.x * 5.0 + iTime * 0.8);

    vec3 finalCol = base_color * 0.7 + secondary_layer * 0.3;

    // Apply color mixing derived from spatial features (From A)
    finalCol.r = mix(0.2, 1.0, d * 0.5) * base_color.r;
    finalCol.g = mix(0.5, 0.9, d * 0.3) * secondary_layer.g;
    finalCol.b = 0.8 + sin(f.y * 10.0) * (1.0 - f.x * 0.5);

    // --- Shader B: Radial and Flow Modulation ---

    // Use the distorted field coordinates for radial calculations
    vec2 f_radial = f;

    float r = length(f_radial);
    float a = atan(f_radial.y, f_radial.x);

    float n = 16.0;
    float q = floor((a/6.28318 + 0.5)*n)/n;

    // Angle and Time based modulation
    float angle_factor = a * 0.5 + iTime * 0.2;
    float pulse = 0.5 + 0.5*sin(8.0*r - 3.0*iTime + q*12.0 + angle_factor);
    float fan = smoothstep(0.4,0.9,pulse);

    // Radial decay and complex scaling using the palette function
    vec3 col = pal(q + 0.1*iTime) * fan * exp(-r * (0.3 + 0.1 * d)); // Incorporate field dependency 'd' into decay

    // Add a slight rotation effect based on angle
    float rotation = (a + iTime * 0.5) * 0.1;
    col.rgb = mix(col.rgb, col.rgb * cos(rotation * 3.14159), 0.5);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
