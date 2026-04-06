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

    // Polar coordinates relative to center
    vec2 center = iResolution.xy * 0.5;
    float r = length(uv - 0.5);
    float a = atan(uv.y - 0.5, uv.x - 0.5);

    // Inverse distance/depth factor, exaggerated
    float z = 1.0 / (r * 1.8 + 0.5);

    // Introduce strong angular flow modulated by time
    float angle_flow = sin(a * 30.0 + iTime * 4.0);

    // Introduce radial displacement based on depth
    float radial_shift = z * 1.5;

    // Modify the base time/angle input based on flow and shift
    float phase_a = 10.0*a + iTime * 2.5 + angle_flow * 2.0;
    float phase_r = 25.0*r + radial_shift * 1.1 + iTime * 3.0;

    float f1 = sin(phase_a * 1.5);
    float f2 = cos(phase_r * 0.9);

    // Create complex density based on the interaction
    float density = abs(f1 * f2 * 3.0);
    float bands = smoothstep(0.7, 0.15, density);

    // Create dynamic, oscillating rings based on angle
    float ring = pow(sin(40.0*r + phase_a * 0.7), 5.0) * 2.5;

    // Use the interaction for palette input, emphasizing radial shift
    float palette_t = 0.01*iTime + f1*0.7 + radial_shift*0.6;

    vec3 col = pal(palette_t);

    // Apply complexity driven by rings and bands
    col *= 0.1 + 6.0*bands + ring * 0.6;

    // Introduce chromatic shift based on flow and radial position
    col += 0.5 * sin(a * 15.0 + iTime * 6.0) * f2;

    // Apply radial falloff emphasizing depth distortion
    col *= exp(-1.2*r * r * 0.4);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
