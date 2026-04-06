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
    float t = iTime * 1.2;
    return vec2(sin(uv.x * 8.0 + t), cos(uv.y * 9.0 - t));
}

vec2 waveA(vec2 uv)
{
    return uv * 2.5 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 6.0 - iTime * 0.7) * 0.25
    );
}

vec2 ripple(vec2 uv)
{
    float r = sin(uv.x * 6.0 + iTime * 1.8);
    float g = sin(uv.y * 5.5 + iTime * 2.2);
    return vec2(r * 0.5 + 0.5, g * 0.5 + 0.5);
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial scaling and centering
    uv = uv * vec2(4.0, 3.0) - vec2(0.5, 0.5);

    // --- Wave Distortion ---
    vec2 warped_uv = waveB(uv);
    warped_uv = waveA(warped_uv);

    // Apply ripple distortion
    vec2 d = ripple(warped_uv);
    warped_uv = warped_uv + d * 0.5;

    // --- Geometric Rotation ---
    float flow_t = iTime * 1.2;

    // Calculate rotation based on combined wave state
    float rotation_angle = sin(warped_uv.x * 6.0 + warped_uv.y * 5.0 + flow_t * 1.5);

    mat2 rotationMatrix = mat2(cos(warped_uv.y * 2.5 + flow_t), -sin(warped_uv.x * 3.0 + flow_t), sin(warped_uv.x * 3.0 + flow_t), cos(warped_uv.y * 2.5 + flow_t));
    warped_uv = rotationMatrix * warped_uv;

    // Apply wave again after rotation
    warped_uv = waveB(warped_uv);

    // --- Complex Flow and Modulation ---

    // Distortion based on a separate flow calculation
    vec2 distorted_uv = warped_uv;
    float scale = 3.5;
    distorted_uv *= scale;
    distorted_uv.x += sin(distorted_uv.y * 7.0 + flow_t * 2.0) * 0.3;
    distorted_uv.y += cos(distorted_uv.x * 5.0 + flow_t * 1.8) * 0.25;

    vec2 final_uv = distorted_uv;

    // Retrieve dynamic system feedback
    vec2 w = waveB(final_uv); 
    float flow_mag = abs(sin(w.x * 12.0 + iTime * 3.5));
    float pulse_mag = abs(cos(w.y * 10.0 - iTime * 2.8));

    // Base value modification
    float base_val = final_uv.x * 5.0 + final_uv.y * 4.5;

    // --- Core Color Generation ---

    // Use flow magnitude for overall contrast shift
    float contrast = 1.0 + flow_mag * 2.0;

    vec3 col = vec3(
        0.15 + 0.7 * sin(base_val * 6.0 * contrast + iTime * 2.0), // R channel 
        0.8 - 0.35 * cos(w.y * 3.0 + iTime * 1.1),  // G channel 
        0.6 + 0.3 * abs(sin(w.x * 5.0 + w.y * 4.0 + iTime * 0.7)) // B channel
    );

    // Modulation application using flow/pulse for intensity distribution

    // R modulation based on flow interaction
    float r = smoothstep(0.0, 0.65, base_val * 1.2 + flow_mag * 3.0);

    // G modulation based on pulse interaction
    float g = smoothstep(0.1, 0.85, final_uv.y * 3.0 + pulse_mag * 4.0);

    // Apply flow contrast to R and G
    col.r = r * contrast;
    col.g = g;

    // Final linkage layer emphasizing the B channel and adding complexity
    float complexity = sin(final_uv.x * 40.0 + iTime * 0.6) * 0.2;
    col.b = 0.35 + 0.6 * sin(col.r * 1.2 + col.g * 1.2 + complexity * 1.3);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
