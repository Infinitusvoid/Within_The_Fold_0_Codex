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
    float z = 1.0 / (r * 2.0 + 0.4);

    // Introduce strong angular flow modulated by time
    float angle_flow = sin(a * 40.0 + iTime * 5.0);

    // Introduce radial displacement based on depth
    float radial_shift = z * 3.0;

    // Combine phase based on angle flow and radial shift
    float phase_a = 18.0*a + iTime * 2.5 + angle_flow * 0.7;
    float phase_r = 25.0*r + radial_shift * 1.0 + iTime * 3.0;

    // Introduce a secondary flow based on radial position and depth
    float flow_r = sin(phase_r * 0.8 + iTime * 1.2);

    float f1 = sin(phase_a * 1.2);
    float f2 = cos(phase_r * 1.4);

    // Create complex density based on the interaction
    float density = abs(f1 * f2 * 1.8);
    float bands = smoothstep(0.4, 0.15, density);

    // Create dynamic, oscillating rings based on angle and radial flow
    float ring = pow(sin(15.0*r + phase_a * 0.6) * flow_r, 7.0) * 2.5;

    // Use the interaction for palette input, emphasizing radial shift and flow
    float palette_t = 0.015*iTime + f1*0.7 + radial_shift*0.55 + flow_r*0.6;

    vec3 col = pal(palette_t);

    // Apply complexity driven by rings and bands
    col *= 0.1 + 6.0*bands + ring * 0.8;

    // Introduce chromatic shift based on flow and radial position
    col += 1.0 * sin(a * 18.0 + iTime * 8.0) * f2;

    // Apply radial falloff emphasizing depth distortion
    col *= exp(-1.8*r * r * 0.6);

    // Introduce a final noise layer based on the combined flow and angle
    float final_mod = sin(phase_a * 0.5 + flow_r * 10.0) * 0.15 + 0.9;
    col *= final_mod;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
