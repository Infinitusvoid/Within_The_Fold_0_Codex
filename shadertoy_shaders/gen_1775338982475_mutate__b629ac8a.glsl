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

vec2 waveA(vec2 uv)
{
    return uv * 2.0 + vec2(sin(uv.x * 8.0 + iTime * 3.0) * 0.5, cos(uv.y * 10.0 + iTime * 1.5) * 0.5);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 4.0) * 0.7, cos(uv.y * 8.0 + iTime * 2.5) * 0.3);
}

float palette(float t)
{
    return 0.1 + 0.9 * fract(t * 3.14159);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.4;
    // Radial effect based on distance from center
    float dist = length(uv);
    float ripple = sin(dist * 20.0 + t * 5.0) * 0.05;
    return uv * (1.0 + ripple) + vec2(ripple * 0.5, ripple * 0.5);
}

vec3 colorFromUV(vec2 uv, float t) {
    // High frequency modulation
    float r = 0.5 + sin(uv.x * 15.0 + t * 0.5);
    float g = 0.5 + cos(uv.y * 12.0 - t * 0.7);
    float b = 0.3 + sin(uv.x * 10.0 + uv.y * 5.0 + t * 1.0);
    return vec3(r, g, b);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.6;
    return vec2(
        sin(uv.x * 10.0 + t * 4.0),
        cos(uv.y * 15.0 + t * 3.0)
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
    // Highly modulated colors
    float r = 0.1 + 0.8 * sin(w.x * 30.0 + iTime * 0.8);
    float g = 0.7 + 0.3 * cos(w.y * 20.0 - iTime * 1.2);
    float b = 0.5 + 0.4 * sin(w.x * 5.0 + w.y * 10.0 + iTime * 0.5);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Normalize and center
    uv = uv * 2.0 - 1.0;

    // Apply base dynamic movement
    vec2 motion_uv = uv * 1.5 + iTime * 0.5;

    // 1. Complex Flow Field (Angled Distortion)
    float angle_flow = motion_uv.x * 10.0 + motion_uv.y * 5.0;
    vec2 rotated_uv = rotate(motion_uv, angle_flow * 1.5);

    // 2. Radial Distortion
    vec2 distorted_uv = distort(rotated_uv);

    // 3. Chain Wave Patterns
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 4. Material Data Retrieval
    vec3 col_base = colorFromUV(distorted_uv, iTime * 0.5);
    vec2 w = waveB(distorted_uv);
    vec3 wave_color = colorFromWave(w);

    // 5. Dynamic Gradient Generation
    float time_scale = iTime * 1.5;
    float flow_depth = sin(distorted_uv.x * 5.0 + time_scale) * 0.5 + 0.5;

    // Mix base color and wave color based on flow depth
    vec3 intermediate_color = mix(col_base, wave_color, flow_depth);

    // 6. Final Sculpting and Coloring
    float distance_factor = 1.0 - smoothstep(0.0, 1.0, length(distorted_uv) * 1.5);

    // Apply complex chromatic shift based on position
    float x_shift = sin(distorted_uv.x * 50.0 + iTime * 2.0) * 0.1;
    float y_shift = cos(distorted_uv.y * 60.0 + iTime * 1.0) * 0.1;

    vec3 final_color = intermediate_color;
    final_color.r += x_shift * 0.5;
    final_color.g += y_shift * 0.5;
    final_color.b = 0.2 + distance_factor * 0.8;

    // Apply noise texture for final grain
    float texture_val = noise(distorted_uv * 8.0 + iTime * 1.0).x;
    final_color = mix(final_color, vec3(texture_val * 0.5), 0.2);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
