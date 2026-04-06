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
    float a = sin(t * 0.4) * 0.5 + 0.5;
    float b = cos(t * 0.6) * 0.5 + 0.5;
    float c = sin(t * 1.0) * 0.5 + 0.5;
    return vec3(a, b, c);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.8;
    float w1 = sin(uv.x * 10.0 + t * 1.5) * 0.5;
    float w2 = cos(uv.y * 8.0 + t * 1.2) * 0.4;
    float w3 = sin(length(uv) * 4.0 + t * 2.0) * 0.3;
    return vec2(w1 * 0.7 + w3 * 0.3, w2 * 0.6 + w3 * 0.4);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // --- Shader A components (Geometric Filtering) ---
    float x_offset = 0.25 * sin(iTime * 1.5);
    float d1 = circle(uv, vec2(-x_offset, 0.0), 0.20);
    float d2 = circle(uv, vec2( x_offset, 0.0), 0.20);
    float d = smin(d1, d2, 0.15);
    float shape_mask = smoothstep(0.01, 0.0, d);

    // --- Shader B components (Flow, Rotation, Distortion) ---

    // 1. Primary spatial scaling and animation
    float flow_speed = 3.0 + sin(iTime * 0.2) * 0.5;
    vec2 distorted_uv = uv * flow_speed;

    // 2. Rotational offset based on screen position
    float angle1 = distorted_uv.x * 8.0 + iTime * 0.4;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    distorted_uv = rotationMatrix * distorted_uv;

    // 3. Apply rotational flow
    float angle2 = iTime * 0.7;
    distorted_uv = rotate(distorted_uv, angle2);

    // 4. Vortex distortion (simplified scaling)
    vec2 center = vec2(0.0);
    float dist = length(distorted_uv);
    distorted_uv = distorted_uv * (1.0 - dist * 0.5);

    // 5. Wave distortion input (remapping UVs slightly)
    distorted_uv = wave(distorted_uv * 1.5);

    // 6. Color mapping based on accumulated distortion
    float t = (distorted_uv.x * 8.0 + distorted_uv.y * 8.0) * 0.4 + iTime * 1.5;
    vec3 col = palette(t);

    // 7. Introduce dynamic chromatic shift based on position
    float angle = atan(distorted_uv.y, distorted_uv.x);
    col.r = sin(angle * 7.0 + iTime * 0.9) * 0.5 + 0.5;
    col.g = cos(angle * 5.5 + iTime * 1.1) * 0.5 + 0.5;
    col.b = sin(angle * 4.5 + iTime * 0.6) * 0.5 + 0.5;

    // 8. Apply geometric shape mask derived from Shader A
    // Interaction with the flow is now more complex
    float mask_base = smin(circle(distorted_uv, vec2(-x_offset, 0.0), 0.20), circle(distorted_uv, vec2( x_offset, 0.0), 0.20), 0.15);
    float final_mask = smoothstep(0.01, 0.0, mask_base);

    // Blend color using a mask-weighted additive effect
    vec3 base_color = vec3(0.8, 0.2, 0.1);
    col = mix(col, base_color, final_mask * 1.5);

    // 9. Final intensity adjustment based on distance variation
    float intensity = 1.0 - exp(-dist * 1.5);
    col *= intensity;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
