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
    float t = iTime * 0.8;
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.6) * 0.08,
        cos(uv.y * 2.5 - iTime * 0.4) * 0.12
    );
}

vec2 ripple(vec2 uv)
{
    float r = sin(uv.x * 5.0 + iTime * 1.5);
    float g = cos(uv.y * 6.0 + iTime * 2.0);
    return vec2(r * 0.5 + 0.5, g * 0.5 + 0.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial scaling and centering
    uv = uv * vec2(3.0, 2.0) - vec2(0.5, 0.5);

    // --- Wave Distortion ---
    uv = waveB(uv);
    uv = waveA(uv);

    // Apply ripple distortion
    vec2 d = ripple(uv);
    uv = uv + d * 0.7;

    // --- Geometric Rotation ---
    float flow_t = iTime * 0.6;
    // Modified flow factor
    float flow_factor = sin(uv.x * 5.0 + uv.y * 4.0 + flow_t * 3.0);

    mat2 rotationMatrix = mat2(cos(uv.y * 2.0 + flow_t), -sin(uv.x * 2.5 + flow_t), sin(uv.x * 2.5 + flow_t), cos(uv.y * 2.0 + flow_t));
    uv = rotationMatrix * uv;

    // Apply wave again after rotation
    uv = waveB(uv);

    // --- Complex Flow and Modulation ---

    // Distortion based on a separate flow calculation
    vec2 distorted_uv = uv;
    float scale = 2.0; // Reduced scale for tighter movement
    distorted_uv *= scale;
    distorted_uv.x += sin(distorted_uv.y * 8.0 + flow_t * 2.0) * 0.3;
    distorted_uv.y += cos(distorted_uv.x * 4.0 + flow_t * 1.5) * 0.25;

    uv = distorted_uv;

    // Retrieve dynamic system feedback
    vec2 w = waveB(uv); 
    float flow_mag = abs(sin(w.x * 12.0 + iTime * 3.5)); // Increased flow sensitivity
    float pulse_mag = abs(cos(w.y * 8.0 - iTime * 2.8)); // Modified pulse sensitivity

    float base_val = uv.x * 6.0 + uv.y * 3.0;

    // --- Core Color Generation ---

    // Use flow magnitude for overall contrast shift
    float contrast = 1.0 + flow_mag * 1.8;

    vec3 col = vec3(
        0.15 + 0.5 * sin(base_val * 5.0 * contrast + iTime * 2.0), // R channel 
        0.85 - 0.35 * cos(w.y * 2.2 + iTime * 1.0),  // G channel 
        0.6 + 0.3 * abs(sin(w.x * 4.5 + w.y * 3.5 + iTime * 0.7)) // B channel
    );

    // Modulation application using flow/pulse for intensity distribution

    // R modulation depends on the flow
    float r = smoothstep(0.0, 0.8, base_val * 1.5 + flow_mag * 3.0);

    // G modulation depends on pulse
    float g = smoothstep(0.2, 0.9, uv.y * 2.5 + pulse_mag * 4.0);

    // Apply flow contrast to R and G
    col.r = r * contrast;
    col.g = g;

    // Final linkage layer emphasizing the B channel
    float complexity = sin(uv.x * 30.0 + iTime * 0.3) * 0.2;
    col.b = 0.2 + 0.7 * sin(col.r * 1.4 + col.g * 1.4 + complexity * 1.2);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
