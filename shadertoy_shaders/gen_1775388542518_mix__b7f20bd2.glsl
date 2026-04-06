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

mat2 rot(float a){ float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }
vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.0,0.33,0.67)+t)); }
float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
float circle(vec2 p, vec2 c, float r)
{
    return length(p - c) - r;
}
vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}
vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 9.0 - iTime * 0.9));
}
vec2 waveA(vec2 uv)
{
    return uv * 2.5 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 6.0 - iTime * 0.7) * 0.25
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // --- Shader A Components (Warping and Flow) ---

    // Initial wave structure
    vec2 warped_uv = waveB(uv * 1.5);

    // Apply complex rotational flow
    float angle = iTime * 0.5 + warped_uv.y * 4.0;
    float flow_speed = 0.5 + sin(uv.x * 1.5) * 0.5;

    // Use flow to rotate and distort
    float flow_offset = flow_speed * 0.5;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;
    warped_uv.x += flow_offset * 0.1;
    warped_uv.y += flow_offset * 0.1;

    // Apply secondary wave structure
    warped_uv = waveA(warped_uv * 1.2);

    // --- Shader B Components (Polar Coordinates and Grid) ---

    // Calculate radial and angular properties
    vec2 center = vec2(0.5);
    vec2 p = warped_uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Introduce grid pattern based on position and time
    float x = a / 3.14159;
    float y = 0.2 / max(r, 0.001) + iTime * 1.5;
    float grid = 0.5 + 0.5 * sin(20.0 * y + 10.0 * x);

    // Combine flow distortion and grid structure
    float final_flow_val = flow_offset * 0.5 + grid * 0.5;

    // --- Color Generation ---

    // Calculate dynamic value based on polar coordinates and time for palette
    float t = r * 1.5 + iTime * 1.2;

    // Base color calculation using palette
    vec3 col1 = palette(t * 1.5);

    // Introduce a flow-based hue shift
    float flow_influence = sin(warped_uv.x * 3.0 + iTime * 1.5) * 0.4 + cos(warped_uv.y * 3.0 + iTime * 1.0) * 0.3;
    vec3 col2 = palette(flow_influence * 3.0 + warped_uv.x * 0.5);

    // Blend colors based on flow influence and grid
    vec3 final_color = mix(col1, col2, flow_influence * 0.5 + grid * 0.5);

    // Introduce depth-based haze based on radial position
    float depth_haze = 1.0 - smoothstep(0.0, 0.15, r);
    final_color *= depth_haze;

    // Introduce chromatic aberration based on angular position
    float ca_factor = 1.0 - r * 0.3;
    final_color += vec3(sin(a * 10.0) * ca_factor, cos(a * 10.0) * ca_factor, 0.0) * 0.2;

    // Fractal noise based on high frequency interaction
    float noise_factor = sin(warped_uv.x * 15.0 + iTime * 3.0) * cos(warped_uv.y * 10.0 - iTime * 1.5);

    // Apply the geometric shape mask (from A)
    float x_offset = 0.3 * sin(iTime * 1.8);
    float d1 = circle(warped_uv, vec2(-x_offset, 0.0), 0.18);
    float d2 = circle(warped_uv, vec2( x_offset, 0.0), 0.18);
    float d = smin(d1, d2, 0.12);
    float shape_mask = smoothstep(0.01, 0.0, d);
    final_color *= (1.0 - shape_mask) * 0.5 + shape_mask * 1.5;

    // Apply noise and contrast boost
    final_color = mix(final_color, vec3(0.0, 0.2, 0.1), noise_factor * 0.8);

    // Final intensity adjustment
    final_color *= 1.2;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
