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

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Polar coordinates
    float a = atan(uv.y, uv.x);
    float r = length(uv);

    // Time and frequency setup
    float t = iTime * 0.4;
    float freq = 20.0;

    // Spiral and flow modulation based on polar coordinates
    float spiral_base = r * freq + t * 4.0;
    float ring_phase = (r * 50.0 + t * 15.0) * 3.14159;
    float ring_depth = 15.0 * sin(ring_phase * 2.0);

    // Angular flow calculation (using noise influence)
    float angle_flow = a * 40.0 + t * 8.0;
    float swirl = sin(angle_flow * 2.5 + t * 2.0);

    // Density based on distance and time flow
    float density = smoothstep(0.04, 0.6, r * 1.5 + sin(t * 10.0));

    // Radial pulse modulation
    float pulse = sin(r * 100.0 + t * 25.0) * 0.4 + 0.6;

    // Color hue based on angle and time (shifted)
    float hue = mod(a * 10.0 + t * 3.0, 3.14159);

    // Flow intensity
    float flow_intensity = swirl * density * 1.8;

    // --- New Modulation ---
    // Atmospheric depth influence
    float depth = 1.0 - smoothstep(0.0, 1.0, r * 1.2 + t * 5.0);

    // Radial color variations
    float r_pulse = sin(r * 120.0 + t * 5.0) * 0.4;
    float g_pulse = cos(r * 150.0 + t * 8.0) * 0.4;
    float b_shift = sin(ring_phase * 0.5) * 0.2;


    // Final color calculation, focusing on dynamic shifts and depth
    vec3 color = vec3(0.0);

    // R component: influenced by pulse and depth
    float r_val = (pulse * 0.6 + depth * 0.3) * (1.0 + r_pulse);

    // G component: influenced by radial wave and flow subtraction
    float g_val = g_pulse - flow_intensity * 0.5;

    // B component: influenced by ring phase and a base shift
    float b_val = sin(ring_phase * 0.7) * 0.5 + b_shift;

    // Apply flow modulation to overall brightness/contrast
    color.r = r_val * (1.0 + flow_intensity * 0.5);
    color.g = g_val * (1.0 - flow_intensity * 0.3);
    color.b = b_val * (1.0 + depth * 0.5);

    // Add a global cyan bias based on angle
    color += vec3(0.1, 0.2, 0.4) * (1.0 - abs(a / 3.14159));

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
