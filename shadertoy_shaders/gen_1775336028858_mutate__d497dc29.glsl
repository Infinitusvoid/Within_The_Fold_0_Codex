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
    uv = uv * vec2(4.0, 3.0) - vec2(0.5, 0.5);

    // --- Primary Wave Distortion ---
    uv = waveB(uv) * 0.8 + uv * 0.2;

    // Apply ripple distortion
    vec2 d = ripple(uv);
    uv = uv + d * 0.3;

    // --- Geometric Flow and Rotation ---
    float flow_t = iTime * 0.5;

    // Flow based on modulated waves
    float flow_x = sin(uv.x * 4.0 + flow_t * 1.2);
    float flow_y = cos(uv.y * 3.0 + flow_t * 0.8);

    // Dynamic rotation
    float angle = flow_x * 2.0 + flow_y * 1.5;
    float flow_factor = sin(uv.x * 6.0 + flow_t) * 0.5;

    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = rotationMatrix * uv;

    // Apply secondary wave distortion
    uv = waveA(uv);

    // --- Chromatic Flow Modulation ---

    // Calculate chromatic flow based on the rotated coordinates
    vec2 flow_uv = uv * 1.5;
    flow_uv.x += flow_factor * 0.5;
    flow_uv.y += sin(flow_uv.x * 2.0) * 0.1;

    uv = flow_uv;

    // Retrieve dynamic system feedback
    vec2 w = waveB(uv * 1.5);
    float flow_mag = abs(sin(w.x * 8.0 + iTime * 4.0));
    float pulse_mag = abs(cos(w.y * 5.0 - iTime * 3.5));

    // --- Core Color Generation ---

    // Base mapping
    float base_val = uv.x * 7.0 + uv.y * 5.0;

    // R channel calculation using flow magnitude
    float r_base = sin(base_val * 5.0 + iTime * 1.7);

    // G channel calculation using pulse
    float g_base = cos(uv.y * 4.0 + iTime * 2.2);

    // B channel calculation using interaction
    float b_base = sin(uv.x * 10.0 + uv.y * 5.0 + iTime * 0.9);

    // Apply modulation using flow and pulse
    float contrast = 1.0 + flow_mag * 1.8;

    vec3 col = vec3(
        r_base * contrast, // R channel driven by flow
        g_base * (1.0 - flow_mag * 0.5), // G channel controlled by flow opposition
        b_base * 0.8 + pulse_mag * 0.2 // B channel controlled by pulse
    );

    // Final linkage layer emphasizing the spectral shift
    float complexity = sin(uv.x * 50.0 + iTime * 1.0) * 0.18;

    // Mix colors using channel interaction
    col.r = smoothstep(0.0, 1.0, col.r + complexity * 0.5);
    col.g = smoothstep(0.0, 1.0, col.g + flow_mag * 0.4);
    col.b = 0.5 + col.r * 0.5 + col.g * 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
