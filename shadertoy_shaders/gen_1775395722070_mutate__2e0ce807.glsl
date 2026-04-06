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

    // Polar coordinates centered at (0,0)
    vec2 center_uv = uv;
    float r = length(center_uv);
    float a = atan(center_uv.y, center_uv.x);

    // Calculate inverse distance/depth factor
    float z = 1.0 / (r * 3.0 + 0.5); // Increased scaling for tighter structure

    // Introduce angular flow modulated by time
    float angle_flow = sin(a * 18.0 + iTime * 5.0); // Faster angular sweep

    // Introduce radial displacement based on depth
    float radial_shift = z * 4.0; // Stronger radial shift

    // Combine phase based on angle flow and radial shift
    float phase_a = 25.0*a + iTime * 2.0 + angle_flow * 2.5; // Enhanced phase mixing
    float phase_r = 30.0*r + radial_shift * 0.6 + iTime * 1.5; // Radial phase

    // Introduce secondary flow based on radial position and depth
    float flow_r = sin(phase_r * 0.8 + iTime * 0.7);

    // Use flow to modulate the primary phase aggressively
    float phase_a_mod = phase_a * (1.0 + flow_r * 0.4);

    float f1 = sin(phase_a_mod * 1.2); // Sharper angular component
    float f2 = cos(phase_r * 1.5); // Radial component

    // Create complex density based on the interaction
    float density = abs(f1 * f2 * 1.5);
    float bands = smoothstep(0.5, 0.1, density); // Inverted contrast for sharper bands

    // Create dynamic, oscillating rings based on angle and radial flow
    float ring = pow(sin(15.0*r + phase_a * 0.5) * flow_r, 8.0) * 3.0; // Higher power for sharper rings

    // Use the flow and radial shift directly for coloring
    float palette_t = 0.01*iTime + f1*0.7 + radial_shift*0.5 + flow_r*0.4;

    vec3 col = pal(palette_t);

    // Apply complexity driven by rings and bands
    col *= 0.05 + 8.0*bands + ring * 1.5; // Increased ring/band influence

    // Introduce chromatic shift based on flow and angle
    col += 0.5 * sin(a * 15.0 + iTime * 9.0) * f2;

    // Apply radial falloff emphasizing depth distortion
    col *= exp(-2.0*r * r * 0.7); // Increased falloff severity

    // Introduce a final noise layer based on the combined flow and angle
    float final_mod = sin(phase_a * 0.2 + flow_r * 10.0) * 0.1 + 0.9;
    col *= final_mod;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
