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

vec2 wave(vec2 uv)
{
    float t = iTime * 0.8;
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // --- Geometric Processing ---
    uv = uv * vec2(3.0, 2.0) - vec2(0.5, 0.5); // Expanded scale and centered

    // Introduce a different flow calculation
    float flow_t = iTime * 0.6;
    float flow_factor = sin(uv.x * 5.0 + uv.y * 4.0 + flow_t * 2.0);

    mat2 rotationMatrix = mat2(cos(uv.y * 2.0 + flow_t), -sin(uv.x * 2.5 + flow_t), sin(uv.x * 2.5 + flow_t), cos(uv.y * 2.0 + flow_t));
    uv = rotationMatrix * uv;

    uv = wave(uv);

    // --- Complex Flow and Modulation ---

    // Distortion based on a separate flow calculation
    vec2 distorted_uv = uv;
    float scale = 2.5;
    distorted_uv *= scale;
    distorted_uv.x += sin(distorted_uv.y * 8.0 + flow_t * 1.5) * 0.2;
    distorted_uv.y += cos(distorted_uv.x * 4.0 + flow_t) * 0.15;

    uv = distorted_uv;

    // Retrieve dynamic system feedback
    vec2 w = wave(uv);
    float flow_mag = abs(sin(w.x * 10.0 + iTime * 3.0));
    float pulse_mag = abs(cos(w.y * 8.0 - iTime * 2.5));

    float base_val = uv.x * 6.0 + uv.y * 3.0;

    // --- Core Color Generation ---

    // Use flow magnitude for overall contrast shift
    float contrast = 1.0 + flow_mag * 1.5;

    vec3 col = vec3(
        0.1 + 0.6 * sin(base_val * 5.0 * contrast + iTime * 1.8), // R channel (Darker base)
        0.9 - 0.3 * cos(w.y * 2.0 + iTime * 0.9),  // G channel (Lighter base)
        0.7 + 0.2 * abs(sin(w.x * 4.0 + w.y * 3.0 + iTime * 0.5)) // B channel (Stronger offset)
    );

    // Modulation application using flow/pulse for intensity distribution

    // R modulation depends on the flow
    float r = smoothstep(0.0, 0.7, base_val * 1.5 + flow_mag * 2.5);

    // G modulation depends on pulse
    float g = smoothstep(0.2, 0.9, uv.y * 2.0 + pulse_mag * 3.5);

    // Apply flow contrast to R and G, adjusting B based on complexity
    col.r = r * contrast;
    col.g = g;

    // Final linkage layer emphasizing the B channel
    float complexity = sin(uv.x * 30.0 + iTime * 0.5) * 0.15;
    col.b = 0.3 + 0.7 * sin(col.r * 1.3 + col.g * 1.3 + complexity * 1.1);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
