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

vec3 pal(float t){ return 0.55 + 0.45*sin(6.28318*(vec3(0.05,0.35,0.75)+t)); }

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
    float g = 0.3 + 0.7 * cos(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * sin(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 2.0), cos(uv.y * 12.0 - iTime * 3.0));
}

vec2 waveA(vec2 uv)
{
    return uv * 3.0 + vec2(
        sin(uv.x * 7.0 + iTime * 1.5) * 0.3,
        cos(uv.y * 9.0 - iTime * 2.5) * 0.3
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // --- Shader A components (Geometric filtering) ---

    // Dynamic offset based on time
    float offset = sin(iTime * 5.0) * 0.1;
    float d1 = circle(uv, vec2(-offset, 0.0), 0.2);
    float d2 = circle(uv, vec2( offset, 0.0), 0.2);
    float d = smin(d1, d2, 0.15);
    float shape_mask = smoothstep(0.005, 0.0, d);

    // --- Shader B components (Waving, Flow, Palette, Radial) ---

    // Initial wave structure based on waveB
    vec2 warped_uv = waveB(uv * 2.0);

    // Apply complex rotational flow based on coordinate interaction
    float angle = iTime * 0.8 + warped_uv.x * 3.0;
    float flow_speed = 0.4 + sin(uv.x * 2.0 + iTime * 1.0) * 0.6;

    // Use flow to rotate and distort
    float flow_offset = flow_speed * 0.2;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Introduce perpendicular flow distortion
    warped_uv.x += flow_offset * 0.05;
    warped_uv.y += flow_offset * 0.05;

    // Apply secondary wave structure based on waveA
    warped_uv = waveA(warped_uv * 1.5);

    // Generate dynamic value based on polar coordinates and time (Shader B concept)
    vec2 p = warped_uv;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // Radial fading based on B
    float rays = 0.5 + 0.5 * sin(theta * 15.0 + iTime * 3.0);
    vec3 radial_base = vec3(rays * (1.0 - r * 0.5));

    // Color generation based on palette and flow
    float t = r * 1.2 + iTime * 1.5;
    vec3 col1 = palette(t);

    // Introduce flow-based hue shift
    float flow_influence = sin(p.x * 5.0 + iTime * 2.5) * 0.5 + cos(p.y * 4.0 + iTime * 1.5) * 0.5;
    vec3 col2 = palette(flow_influence * 2.5 + p.x * 0.8);

    // Blend colors based on flow and incorporate radial base
    vec3 final_color = mix(col1, col2, flow_influence) * (0.5 + 0.5 * radial_base);

    // Introduce chromatic aberration based on radial position (from A)
    final_color += vec3(sin(theta * 8.0) * (1.0 - r * 0.4), cos(theta * 8.0) * (1.0 - r * 0.4), 0.0) * 0.1;

    // Fractal noise based on high frequency interaction (from A)
    float noise_factor = sin(p.x * 20.0 + iTime * 4.0) * cos(p.y * 15.0 - iTime * 2.0);

    // --- Final Integration ---

    // Apply the geometric shape mask derived from Shader A
    final_color *= (1.0 - shape_mask) * 0.4 + shape_mask * 1.6;

    // Introduce depth based on flow influence
    final_color = mix(final_color, vec3(0.2, 0.8, 0.3), flow_influence * 0.7);

    // Apply noise and contrast boost
    final_color = mix(final_color, vec3(0.02, 0.05, 0.01), noise_factor * 0.7);

    // Final intensity adjustment
    final_color *= 1.8;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
