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

    float r = length(uv - 0.5);
    float a = atan(uv.y - 0.5, uv.x - 0.5);

    // Calculate inverse distance/depth factor
    float z = 1.0 / (r * 2.0 + 0.5);

    // Introduce strong angular flow modulated by time
    float angle_flow = sin(a * 10.0 + iTime * 1.5);

    // Introduce radial displacement based on depth
    float radial_shift = z * 1.5;

    // Modify the base time/angle input based on flow and shift
    float phase_a = 10.0*a + iTime * 0.8 + angle_flow;
    float phase_r = 16.0*r + radial_shift + iTime * 1.0;

    float f1 = sin(phase_a);
    float f2 = cos(phase_r);

    // Create complexity using the interaction of sine and cosine components
    float density = abs(f1 * f2);
    float bands = smoothstep(0.4, 0.1, density * 2.0);

    // Create dynamic pulsing rings based on time and radius
    float ring = pow(sin(12.0*r + iTime * 5.0), 3.0);

    // Use the combined complexity for the palette input
    float palette_t = 0.08*iTime + f1*0.5 + radial_shift*0.3;

    vec3 col = pal(palette_t);

    // Combine features with a strong emphasis on the ring and density
    col *= 0.05 + 3.0*bands + 1.5*ring;

    // Apply radial falloff, emphasizing the depth distortion
    col *= exp(-1.5*r * r * 0.6);

    // Apply angular shift, introducing chromatic variance
    col += 0.2 * sin(a * 12.0 + iTime * 2.0);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
