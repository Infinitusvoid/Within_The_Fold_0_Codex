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
    float t = iTime * 1.2;
    return vec2(sin(uv.x * 8.0 + t * 1.8), cos(uv.y * 6.0 - t * 1.2));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // --- Geometric Processing ---
    uv = uv * vec2(1.5, 1.0) - vec2(0.5, 0.0); // Center and Scale adjustment

    float angle = iTime * 0.5 + sin(uv.x * 4.0 + uv.y * 2.5) * 0.4 + uv.x * uv.y * 0.6;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = rotationMatrix * uv;

    uv = wave(uv);

    // --- Complex Flow and Modulation ---

    // Introduce distortion effect
    float distortion_t = iTime * 0.7;
    vec2 distorted_uv = uv;
    float scale = 2.2;
    distorted_uv *= scale;
    distorted_uv.x += sin(distorted_uv.y * 5.0 + distortion_t * 3.0) * 0.2;
    distorted_uv.y += cos(distorted_uv.x * 4.0 + distortion_t * 1.5) * 0.15;

    uv = distorted_uv;

    // Retrieve dynamic system feedback
    vec2 w = wave(uv);
    float flow_mag = sin(w.x * 20.0 + iTime * 4.0);
    float pulse_mag = abs(sin(w.y * 12.0 - iTime * 3.0));

    float base_val = uv.x * 6.0 + uv.y * 5.0;

    // --- Core Color Generation ---

    vec3 col = vec3(
        0.5 + 0.5 * sin(base_val * 6.0 + iTime * 2.0), // R channel base
        0.5 + 0.5 * cos(w.y * 3.0 + iTime * 0.8),  // G channel variation
        0.4 + 0.3 * abs(sin(w.x * 4.0 + w.y * 3.0 + iTime * 1.0)) // B channel primary mood offset
    );

    // Modulation application

    // R modulation dependent on geometric spread and flow magnitude
    float r = smoothstep(0.0, 0.9, base_val * 1.5 + flow_mag * 5.0);

    // G modulation dependent on temporal flow/pulse
    float g = smoothstep(0.2, 0.8, uv.y * 1.8 + pulse_mag * 4.0);

    // Use resulting flow/pulse for intensity shift along channel boundaries
    col.r = r;
    col.g = g;

    // Complex final linkage layer
    float freq_shift = sin(uv.x * 25.0 + iTime * 0.6) * 0.15;
    col.b = 0.6 + 0.4 * sin(col.r * 1.8 + col.g * 1.8 + freq_shift * 1.3);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
