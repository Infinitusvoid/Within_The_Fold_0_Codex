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

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 5.0 + t * 1.5),
        cos(uv.y * 4.0 + t * 0.8)
    );
}

float palette(float t) {
    t = fract(t * 3.14159);
    return 0.5 + 0.5 * sin(t * 12.0);
}

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec2 wave_B(vec2 uv) {
    float t = iTime * 0.8;
    // Combine timing shifts from B
    return vec2(sin(uv.x * 9.0 + t * 1.5), cos(uv.y * 7.0 - t * 0.9));
}

vec3 colorFromWave(vec2 w)
{
    // Mix modulation styles from B
    float r = 0.1 + 0.6 * sin(w.x * 25.0 + iTime * 0.5);
    float g = 0.4 + 0.5 * cos(w.y * 10.0 - iTime * 0.7);
    float b = 0.3 + 0.3 * sin(w.x * 8.0 + w.y * 4.0 + iTime * 0.2);
    return vec3(r, g, b);
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

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Calculate base wave structure
    vec2 w = wave_B(uv);
    vec3 base_color = colorFromWave(w);

    // 2. Distortion and rotational base
    uv = distort(uv);

    // 3. Global flow and rotational field
    float t = iTime * 2.5; // Increased time speed
    // Introduce stronger, spatially dependent flow
    float flow_field = sin(uv.x * 45.0 + uv.y * 25.0 + t * 3.5) * 0.8; // Increased flow complexity
    // Dramatic rotation based on complex wave interaction
    float rot_angle = t * 1.5 + sin(uv.x * 12.0) * 2.5 + cos(uv.y * 10.0) * 1.2; // Increased rotation dynamism
    mat2 rot = rotate(rot_angle);
    uv = rot * uv;

    // 4. Layered modulation and depth calculation
    // Depth derived from wave magnitude and flow
    float depth = w.y * 6.0 + flow_field * 12.0; // Increased depth sensitivity

    // Intensity modulation using noise interaction and depth
    float noise_effect = noise(uv * 30.0 + iTime * 0.5).x; // Increased noise scale
    float intensity = 0.3 + 0.7 * sin(w.x * 15.0 + depth * 1.5 + noise_effect * 2.0); // New intensity formula

    // Calculate refracted colors and applying flow complexity
    vec3 refracted_color = base_color * (0.4 + 0.6 * flow_field); // Adjusted base refraction

    // Subtle depth visualization offset
    float shift = sin(depth * 10.0) * 0.5; // Increased shift effect
    refracted_color.r += shift * 1.2;
    refracted_color.g -= shift * 1.8;
    refracted_color.b += 0.5 * sin(uv.x * 20.0); // Adjusted blue component

    // 5. Final color mixing and enhancement
    vec3 final_col = refracted_color;

    // Final trigonometric mapping based on flow and wave interaction
    final_col.r = sin(final_col.g * 2.2 + iTime * 1.2);
    final_col.g = cos(final_col.r * 2.5 + uv.y * 10.0 + t * 0.7);
    final_col.b = 0.1 + 0.8 * sin(w.x * 2.5 + depth / 8.0 + iTime * 0.4);

    // Apply dynamic layering scale
    final_col = final_col * intensity;

    fragColor = vec4(final_col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
