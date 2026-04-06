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

vec3 pal(float t)
{
    return 0.5 + 0.5 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
    vec2 center = iResolution.xy * 0.5;

    // Polar coordinates
    float r = length(uv - 0.5);
    float a = atan(uv.y - 0.5, uv.x - 0.5);

    // Calculate inverse distance/depth factor
    float z = 1.0 / (r * 2.0 + 0.5);

    // Introduce strong angular flow modulated by time
    float angle_flow = sin(a * 40.0 + iTime * 5.0);

    // Introduce radial displacement based on depth
    float radial_shift = z * 5.0;

    // Combine phase based on angle flow and radial shift
    float phase_a = 10.0*a + iTime * 2.0 + angle_flow;
    float phase_r = 20.0*r + radial_shift * 0.7 + iTime * 3.0;

    // Introduce a secondary flow based on radial position and depth
    float flow_r = cos(phase_r * 0.8) * sin(a * 10.0);

    // Define structure based on radial position and flow interaction
    float structure = sin(phase_r * 1.5) * cos(phase_a * 2.0) * 2.0;

    // Introduce time-based pulsing shift
    float time_pulse = sin(iTime * 5.0) * 0.5 + 0.5;

    // Base color modulated by the structure
    float color_base = (sin(phase_a * 5.0) + time_pulse) * 0.5 + 0.5;

    // Use flow to create dynamic color shifts
    float color_shift = flow_r * 0.5;

    // Final palette input
    float palette_t = color_base + color_shift;

    vec3 col = pal(palette_t);

    // Apply structure strongly
    col *= 1.0 + structure * 1.5;

    // Introduce chromatic aberration based on angular flow
    col += 0.3 * sin(a * 20.0 + iTime * 8.0);

    // Apply radial falloff emphasizing depth distortion
    col *= exp(-2.0*r * r * 0.4);

    // Introduce a final noise layer based on combined flow and time
    float final_mod = sin(phase_r * 0.5 + iTime * 1.2) * 0.1 + 0.9;
    col *= final_mod;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
