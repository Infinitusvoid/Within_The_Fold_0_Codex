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

vec2 ripple(vec2 uv, float t) {
    float flow = sin(uv.x * 15.0 + t * 1.5) * 0.15;
    float density = cos(uv.y * 10.0 + t * 2.0) * 0.1;
    return uv + vec2(flow, density);
}

vec3 color_shift(vec2 uv, float t) {
    float n = sin(uv.x * 45.0 + t * 3.0) + cos(uv.y * 45.0 + t * 2.5);
    return vec3(n * 0.6 + 0.2, 0.5 + n * 0.4, 0.1 + sin(uv.x * 70.0 + t * 5.0) * 0.3);
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * cos(t * 0.75);
    float g = 0.5 + 0.5 * sin(t * 0.8);
    float b = 0.5 + 0.5 * cos(t * 0.6);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Base flow and ripple calculation
    vec2 warped_uv = ripple(uv, iTime * 0.7);

    // Apply ripple distortion and time shift
    vec2 final_uv = warped_uv * 1.8;
    final_uv = ripple(final_uv, iTime * 0.5);

    // Introduce chromatic shift based on position and time
    vec3 color_base = color_shift(final_uv, iTime * 1.2);

    // Dynamic scale and panning
    float scale = 1.0 + 0.3 * sin(iTime * 0.3);
    vec2 offset = vec2(sin(iTime * 0.4), cos(iTime * 0.4)) * 0.4;
    final_uv = final_uv * scale + offset;

    // Rotation logic based on UV structure
    float angle = final_uv.x * 6.0 + final_uv.y * 6.0 + iTime * 0.3;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    final_uv = rot * final_uv;

    // Time calculation and palette application
    float t = final_uv.x * final_uv.y * 15.0 + iTime * 0.4;
    vec3 base_color = palette(t);

    // Complex color mixing based on shifted patterns
    float r_mix = sin(t * 3.5) * 0.4 + 0.6;
    float g_mix = cos(t * 4.0) * 0.3 + 0.7;

    // R component: influenced by flow
    base_color.r = mix(0.8, 0.1, r_mix * 0.5) * base_color.r;

    // G component: influenced by shift
    base_color.g = mix(0.2, 0.8, g_mix * 0.5) * base_color.g;

    // B component: based on time wave
    base_color.b = abs(sin(t * 4.5)) * 0.9 + 0.05;

    // Final subtle adjustment based on the rotated UVs
    float final_shift = sin(final_uv.x * 25.0 + iTime * 1.2) * 0.2;
    base_color.r = clamp(base_color.r + final_shift, 0.0, 1.0);
    base_color.g = clamp(base_color.g + final_shift * 0.8, 0.0, 1.0);
    base_color.b = base_color.b * (1.0 + final_shift * 0.5);

    fragColor = vec4(base_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
