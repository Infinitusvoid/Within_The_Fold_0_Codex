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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 0.5), cos(uv.y * 10.0 + iTime * 0.3));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.8) * 0.1,
        cos(uv.y * 5.0 + iTime * 0.4) * 0.2
    );
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.4*sin(t + iTime * 0.2), 0.4 + 0.4*cos(t + iTime * 0.1), 0.7 + 0.3*sin(t + iTime * 0.3));
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 flow(vec2 uv) {
    float t = iTime * 0.5;
    // Smooth, coupled flow driven by time coordinate system
    return uv + vec2(sin(uv.x * 5.0 + t), cos(uv.y * 4.0 + t * 2.0)) * 0.5;
}

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.5;
    float scale = 1.8;
    uv *= scale;
    // Noise and time-based coupling for distortion
    uv.x += sin(uv.y * 6.0 + t * 2.0) * 0.15;
    uv.y += cos(uv.x * 5.0 + t) * 0.1;
    return uv;
}

vec2 wave(vec2 uv)
{
    float t = iTime * 0.8;
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}

vec3 colorFromWave(vec2 w)
{
    // Complex coloring structure adapted from Shader B
    float r = 0.5 + 0.5 * sin(w.x * 12.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 10.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // 1. Initial coordinate setup (Normalized and centered)
    uv = uv * 2.0 - 1.0;

    // 2. Apply complex distortion (From B)
    uv = distort(uv);

    // 3. Apply flowing movement based deformation (Tying B)
    vec2 flowed_uv = flow(uv);

    // 4. Global Rotation (Incorporate B's dynamic angularity)
    float angle = iTime * 0.7 + sin(uv.x * 5.0 + uv.y * 3.5) * 0.4;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 transformed_uv = rot * flowed_uv;

    // 5. Wave Pattern Calculation (Using the merged wave structure)
    // Use wave as the primary pattern driver
    vec2 w = wave(transformed_uv);

    // 6. Extract Base Color using the complex structure from B
    vec3 base_color = colorFromWave(w);

    // 7. Pulse and Intensity Layering
    float flow = sin(transformed_uv.x * 20.0 + iTime * 1.2) * 0.2;
    float pulse = sin(transformed_uv.y * 15.0 + iTime * 0.9);

    float intensity_mask = 0.5 + 0.5 * sin(transformed_uv.x * 8.0 + iTime * 0.3);

    // 8. Blending Colors and Applying Smoothstep Modulations

    // R Channel control
    base_color.r = smoothstep(0.3, 0.6, transformed_uv.x * 2.5 + flow * 6.0);
    // G Channel control
    base_color.g = smoothstep(0.2, 0.5, transformed_uv.y * 3.5 + pulse * 5.0);
    // B Channel Modulation derived from intermediate results
    base_color.b = 0.1 + 0.4 * sin(base_color.r * 1.8 + base_color.g * 1.8 + iTime * 0.5);

    // Apply flow and pulse shifts
    base_color.r += flow * 0.8;
    base_color.g += pulse * 0.7;
    base_color.b += 0.25 * sin(transformed_uv.x * 10.0 + iTime * 0.4);

    // 9. Final Highly Integrated Transformation (Psychedelic output)
    base_color.r = cos(base_color.g * 10.0 + iTime * 0.5) * 0.5 + 0.5;
    base_color.g = sin(base_color.r * 8.0 - transformed_uv.y * 6.0 + iTime * 0.4) * 0.5 + 0.5;
    base_color.b = 0.5 + 0.5 * sin(transformed_uv.x * 7.0 + transformed_uv.y * 7.0 + iTime * 0.7);

    fragColor = vec4(base_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
