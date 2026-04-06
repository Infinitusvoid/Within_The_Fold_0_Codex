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
    vec2 uv = fragCoord/iResolution.xy;

    // --- Shader A components (Geometric filtering) ---
    // Modify geometry constraints for more organic, smaller shapes
    float x_offset = 0.3 * sin(iTime * 3.0);
    float d1 = circle(uv, vec2(-x_offset * 0.8, 0.0), 0.15);
    float d2 = circle(uv, vec2( x_offset * 0.8, 0.0), 0.15);
    float d = smin(d1, d2, 0.10); // Tighter constraint
    float shape_mask = smoothstep(0.01, 0.0, d); // Sharper edge

    // --- Shader B components (Waving, Flow, Palette, Radial) ---

    // Initial wave structure based on waveB
    vec2 warped_uv = waveB(uv * 2.0);

    // Apply complex rotational flow
    float angle = iTime * 1.5 + warped_uv.x * 3.0;
    float flow_speed = 1.0 + sin(uv.y * 2.0) * 0.5; // Flow based on vertical position

    // Use flow to rotate and distort
    float flow_offset = flow_speed * 0.7;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;
    warped_uv.x += flow_offset * 0.2;
    warped_uv.y += flow_offset * 0.2;

    // Apply secondary wave structure based on waveA
    warped_uv = waveA(warped_uv * 1.2);

    // Generate dynamic value based on polar coordinates and time (Shader B concept)
    vec2 p = warped_uv;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // Radial fading based on B (Stronger fade effect)
    float rays = 0.5 + 0.5 * sin(theta * 10.0 + iTime * 4.0);
    vec3 radial_base = vec3(rays * (1.0 - r * 0.4));

    // Color generation based on A's palette and flow
    float t = r * 1.5 + iTime * 2.0;
    vec3 col1 = palette(t);

    // Introduce flow-based hue shift (More aggressive interaction)
    float flow_influence = sin(p.x * 3.0 + iTime * 2.5) * 0.4 + cos(p.y * 3.0 + iTime * 1.5) * 0.6;
    vec3 col2 = palette(flow_influence * 6.0 + p.x * 0.5);

    // Blend colors based on flow and incorporate radial base
    vec3 final_color = mix(col1, col2, flow_influence) * (0.5 + 0.5 * radial_base.r);

    // Introduce chromatic aberration based on radial position (from A)
    float dist_factor = 1.0 - r * 0.3;
    final_color += vec3(sin(theta * 9.0) * dist_factor * 0.15, cos(theta * 9.0) * dist_factor * 0.15, 0.0) * 0.2;

    // Fractal noise based on high frequency interaction (from A)
    float noise_factor = sin(p.x * 25.0 + iTime * 5.0) * cos(p.y * 15.0 - iTime * 3.0);

    // --- Final Integration ---

    // Apply the geometric shape mask derived from Shader A
    final_color *= (1.0 - shape_mask) * 0.7 + shape_mask * 1.3;

    // Introduce depth based on flow influence
    final_color = mix(final_color, vec3(0.3, 0.2, 0.1), flow_influence * 0.5);

    // Apply noise and contrast boost
    final_color = mix(final_color, vec3(0.01, 0.03, 0.0), noise_factor * 0.7);

    // Final intensity adjustment
    final_color *= 2.0;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
