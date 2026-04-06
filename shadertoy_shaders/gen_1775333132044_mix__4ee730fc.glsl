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
    return uv + vec2(sin(uv.x * 3.0 + iTime * 0.4) * tan(uv.y * 1.5 + iTime * 0.6), cos(uv.y * 2.5 + iTime * 0.7) * sin(uv.x * 1.2 + iTime * 0.5));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // --- Geometric Setup (from B) ---
    uv = uv * vec2(4.0, 3.0) - vec2(0.5, 0.5); // Expanded scale and centered

    // Introduce a dynamic warp based on time (from B)
    float warp_t = iTime * 1.2;
    uv.x += sin(uv.y * 5.0 + warp_t * 1.5) * 0.2;
    uv.y += cos(uv.x * 6.0 + warp_t * 1.0) * 0.15;

    // Apply wave function (from A)
    uv = wave(uv);

    // --- Flow and Modulation (from B) ---
    float flow_t = iTime * 1.5;
    float flow_mag = abs(sin(uv.x * 5.0 + uv.y * 4.0 + flow_t));
    float pulse_mag = abs(cos(uv.x * 3.0 + uv.y * 6.0 - flow_t * 0.5));

    float base_val = uv.x * 7.0 + uv.y * 5.0;

    // Contrast based on flow
    float contrast = 1.0 + flow_mag * 1.8;

    // --- Core Color Generation (Combined Logic) ---

    // R channel modulation (based on A's time/sin structure)
    float r_base = base_val * 3.0;
    float r_mod = sin(r_base * 1.2 + iTime * 2.0) * 0.5;

    // G channel modulation (based on B's pulse)
    float g_base = uv.y * 5.0;
    float g_mod = cos(g_base * contrast + iTime * 0.8 + pulse_mag * 2.0) * 0.3;

    // B channel modulation (based on A's flow interaction)
    float b_mod = sin(uv.x * 8.0 + uv.y * 2.0 + flow_t * 0.8);

    vec3 col = vec3(
        0.05 + 0.7 * sin(r_base * contrast + iTime * 1.5 + r_mod * 3.0), // R channel
        0.8 - 0.3 * cos(g_base * contrast + iTime * 0.8 + g_mod * 2.0),  // G channel
        0.6 + 0.4 * sin(b_mod * contrast + iTime * 2.5) // B channel
    );

    // Final linkage (from B)
    float final_texture = sin(base_val * 10.0 + iTime * 3.0) * 0.25;
    col.r *= (1.0 + final_texture);
    col.g *= (1.0 + final_texture * 0.5);
    col.b *= (1.0 + final_texture * 0.8);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
