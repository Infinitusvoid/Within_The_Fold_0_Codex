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

vec2 waveA(vec2 uv)
{
    return uv + vec2(sin(uv.x * 8.0 + iTime * 1.0) * 0.4, cos(uv.y * 7.0 + iTime * 0.5) * 0.3);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 1.5) * cos(uv.y * 4.0), cos(uv.y * 8.0 + iTime * 0.8) * sin(uv.x * 3.0));
}

float palette(float t)
{
    return 0.5 + 0.5 * sin(t * 3.0);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.4;
    // Integrate motion and scale effects from B
    float scale = 1.0 + 0.05 * sin(t + uv.x * 10.0);
    float shift = 1.0 + 0.04 * cos(t + uv.y * 8.0);
    uv.x *= scale;
    uv.y *= shift;
    // Add coupling derived from A's distortion structure
    uv.x += sin(uv.y * 6.0 + t * 4.0) * 0.2;
    uv.y += cos(uv.x * 7.0 + t * 1.8) * 0.15;
    return uv;
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.5 + t * 0.4) * 0.5 + 0.5;
    float e = cos(uv.y * 9.5 - t * 0.5) * 0.4 + 0.5;
    float f = 0.2 + sin(uv.x * 4.5 + uv.y * 3.5 + t * 0.6) * 0.3;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec3 colorFromWave(vec2 w)
{
    // Mix modulation styles from B
    float r = 0.1 + 0.6 * sin(w.x * 25.0 + iTime * 0.5);
    float g = 0.4 + 0.5 * cos(w.y * 10.0 - iTime * 0.7);
    float b = 0.3 + 0.3 * sin(w.x * 8.0 + w.y * 4.0 + iTime * 0.2);
    return vec3(r, g, b);
}

vec2 flow(vec2 uv)
{
    float t = iTime * 0.8;
    float x = uv.x * 15.0 + t * 5.0;
    float y = uv.y * 12.0 + t * 4.0;
    float flow_x = sin(x * 0.6) * cos(y * 0.6 + t * 0.3);
    float flow_y = cos(x * 0.7 + t * 0.2) * sin(y * 0.4);
    return uv + vec2(flow_x * 2.5, flow_y * 2.5);
}

vec3 color_hue(vec2 uv)
{
    float t = iTime * 1.5;
    float h = atan(uv.y, uv.x) * 6.28;
    float s = 0.5 + 0.5 * cos(h * 3.0 + t * 1.2);
    float l = 0.5 + 0.5 * sin(t * 2.0);
    return h / 6.28 + vec3(s, s, s);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Base coordinates definition
    vec2 uv_base = uv * vec2(10.0, 10.0) - vec2(5.0, 5.0);

    // Apply Flow warping (B influence)
    vec2 f = flow(uv_base);

    // Apply initial time and structure smoothing (A influence)
    vec2 uv_flow = uv * 2.0 - 1.0;
    uv_flow *= 1.0 + sin(iTime * 0.7) * 0.25;

    // 1. Complex Motion Baseline (Rotation based on A structure)
    float angle1 = sin(iTime * 0.5) * 2.0 + uv_flow.x * uv_flow.y * 3.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv_flow = rotationMatrix * uv_flow;

    float angle2 = iTime * 1.2 + uv_flow.x * 1.8;
    uv_flow = rotate(uv_flow, angle2);

    // 2. Distortion (Combined A/B distortion)
    vec2 distorted_uv = distort(uv_flow);

    // 3. Chain Wave Patterns
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime);
    vec2 w = waveB(distorted_uv);
    vec3 wave_color = colorFromWave(w);

    // 5. Dynamic Variable Generation ? Color Mixing
    float t = distorted_uv.x * 5.0 + distorted_uv.y * 4.0 + iTime * 0.6;
    vec3 col_palette = colorFromUV(distorted_uv, t); 

    // Flow interaction
    float flow = sin(distorted_uv.x * 30.0 + iTime * 2.0) * 0.3;
    float warp = cos(distorted_uv.y * 15.0 + iTime * 1.5) * 0.2;

    // Mix base color and palette
    vec3 final_color = mix(col_base, col_palette, flow * 0.9);

    // 6. Advanced Sculpting (Mixing B's hue and A's depth interaction)
    float radius = length(distorted_uv);
    float dist_factor = 1.0 - smoothstep(0.0, 0.4, radius * 2.5); 

    // Mix wave color into the base
    final_color = mix(final_color, wave_color, dist_factor * 0.85);

    // Introduce chromatic shift based on UV phase
    vec3 hue_base = color_hue(distorted_uv * 2.0);
    final_color = mix(final_color, hue_base, 0.5);

    // Apply flow-based shift derived from B
    vec3 final_c_flow = color_hue(f * 1.5);
    final_color = mix(final_color, final_c_flow, 0.2);

    // Final reflection gradient
    float reflection = 1.0 - smoothstep(0.0, 0.6, radius);
    final_color *= reflection * 1.5;

    // NEW: Introduce a noise field based reflection effect
    float depth_noise = noise(distorted_uv * 5.0 + iTime * 2.0).x;
    float specular_strength = 0.5 + depth_noise * 0.5;
    final_color *= specular_strength;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
