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
    float t = iTime * 0.9;
    return vec2(sin(uv.x * 10.0 + t * 1.2), cos(uv.y * 8.0 - t * 0.8));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 4.0 + iTime * 0.7) * 0.1,
        cos(uv.y * 6.0 - iTime * 1.1) * 0.15
    );
}

vec2 ripple(vec2 uv)
{
    float r = sin(uv.x * 6.0 + iTime * 2.5);
    float g = sin(uv.y * 5.0 + iTime * 3.0);
    return vec2(r * 0.5 + 0.5, g * 0.5 + 0.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial scaling and centering
    uv = uv * vec2(4.0, 3.0) - vec2(0.5, 0.5);

    // --- Wave Distortion ---
    uv = waveB(uv);
    uv = waveA(uv);

    // Apply ripple distortion
    vec2 d = ripple(uv);
    uv = uv + d * 0.5;

    // --- Geometric Rotation ---
    float flow_t = iTime * 1.0;

    // Modify flow factor based on internal state
    float flow_factor = sin(uv.x * 6.0 + uv.y * 4.0 + flow_t * 2.0);

    // Rotation matrix based on current position
    mat2 rotationMatrix = mat2(cos(uv.y * 3.0 + flow_t), -sin(uv.x * 3.5 + flow_t), sin(uv.x * 3.5 + flow_t), cos(uv.y * 3.0 + flow_t));
    uv = rotationMatrix * uv;

    // Apply wave again after rotation
    uv = waveB(uv);

    // --- Complex Flow and Modulation ---

    // Distortion based on a separate flow calculation
    vec2 distorted_uv = uv;
    float scale = 1.5; 
    distorted_uv *= scale;
    distorted_uv.x += sin(distorted_uv.y * 10.0 + flow_t * 2.5) * 0.25;
    distorted_uv.y += cos(distorted_uv.x * 5.0 + flow_t * 1.8) * 0.2;

    uv = distorted_uv;

    // Retrieve dynamic system feedback
    vec2 w = waveB(uv); 
    float flow_mag = abs(sin(w.x * 15.0 + iTime * 4.0)); // Increased flow sensitivity
    float pulse_mag = abs(cos(w.y * 10.0 - iTime * 3.0)); // Modified pulse sensitivity

    float base_val = uv.x * 5.0 + uv.y * 2.5;

    // --- Core Color Generation ---

    // Use flow magnitude for overall contrast shift
    float contrast = 1.0 + flow_mag * 2.0;

    vec3 col = vec3(
        0.2 + 0.4 * sin(base_val * 6.0 * contrast + iTime * 3.0), // R channel 
        0.7 + 0.2 * cos(w.y * 3.0 + iTime * 1.5),  // G channel 
        0.5 + 0.5 * abs(sin(w.x * 5.0 + w.y * 4.0 + iTime * 0.5)) // B channel
    );

    // Modulation application using flow/pulse for intensity distribution

    // R modulation depends on the flow and position
    float r = smoothstep(0.0, 0.7, base_val * 2.0 + flow_mag * 3.5);

    // G modulation depends on the pulse
    float g = smoothstep(0.3, 0.9, uv.y * 3.0 + pulse_mag * 5.0);

    // Apply flow contrast to R and G
    col.r = r * contrast;
    col.g = g;

    // Final linkage layer emphasizing the B channel based on texture
    float complexity = sin(uv.x * 45.0 + iTime * 0.2) * 0.3;
    col.b = 0.1 + 0.8 * sin(col.r * 1.3 + col.g * 1.3 + complexity * 1.5);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
