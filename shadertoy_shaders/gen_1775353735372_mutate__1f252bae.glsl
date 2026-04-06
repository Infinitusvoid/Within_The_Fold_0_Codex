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

vec3 pal(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.08,0.35,0.67)+t));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // --- Shader A components (Geometric filtering and Flow) ---

    // Geometric filtering setup
    float x_offset = 0.3 * sin(iTime * 1.8);
    float d1 = circle(uv, vec2(-x_offset, 0.0), 0.18);
    float d2 = circle(uv, vec2( x_offset, 0.0), 0.18);
    float d = smin(d1, d2, 0.12);
    float shape_mask = smoothstep(0.01, 0.0, d);

    // Wave and Flow manipulation
    vec2 warped_uv = waveB(uv * 1.5);

    float angle = iTime * 0.5 + warped_uv.y * 4.0;
    float flow_speed = 0.5 + sin(uv.x * 1.5) * 0.5;

    float flow_offset = flow_speed * 0.5;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;
    warped_uv.x += flow_offset * 0.1;
    warped_uv.y += flow_offset * 0.1;

    warped_uv = waveA(warped_uv * 1.2);

    // --- Shader B components (Polar and Banding) ---

    vec2 final_uv = warped_uv;

    float r = length(final_uv);
    float theta = atan(final_uv.y, final_uv.x);

    // Apply radial distortion and flow to r/theta
    float flow_r = r * 0.5 + sin(theta * 5.0) * 0.1;
    float flow_theta = theta + sin(r * 20.0) * 0.1;

    // Adjust r and theta based on flow
    r += flow_r;
    theta += flow_theta;

    float z = 1.0/(r+0.18);
    float f1 = sin(10.0*theta + 3.0*z - 2.0*iTime);
    float f2 = sin(16.0*theta - 4.0*z + 1.7*iTime);

    float bands = smoothstep(0.25,0.0,abs(f1*f2));
    float ring = smoothstep(0.2,0.0,abs(sin(10.0*r - 3.0*iTime)));

    // --- Color Generation ---

    // Base color using A's dynamic palette
    vec3 col1 = palette(r * 5.0 + iTime * 2.0);

    // Color modulated by B's polar palette
    vec3 col2 = pal(r * 1.5 + iTime * 1.0);

    // Flow influence derived from A, used to mix B's palette
    float flow_influence = sin(final_uv.x * 3.0 + iTime * 1.5) * 0.4 + cos(final_uv.y * 3.0 + iTime * 1.0) * 0.3;

    // Blend colors
    vec3 base_color = mix(col1, col2, flow_influence);

    // Apply modulation from B's ring/bands
    vec3 modulated_color = base_color * (0.2 + 1.6*bands + 0.6*ring);

    // Introduce chromatic aberration based on radial position (from A)
    float dist_factor = 1.0 - r * 0.5;
    modulated_color += vec3(sin(theta * 5.0) * dist_factor, cos(theta * 5.0) * dist_factor, 0.0) * 0.15;

    // Fractal noise (from A)
    float noise_factor = sin(final_uv.x * 15.0 + iTime * 3.0) * cos(final_uv.y * 10.0 - iTime * 1.5);
    modulated_color = mix(modulated_color, vec3(0.05, 0.1, 0.0), noise_factor * 0.5);

    // Final intensity adjustment and geometric mask application
    modulated_color *= 1.3;
    modulated_color *= (1.0 - shape_mask) * 0.5 + shape_mask * 1.5;

    fragColor = vec4(modulated_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
