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
    return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.34,0.68)+t));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Use coordinate system centered around 0.5 for better radial effects (Shader B style)
    vec2 centered_uv = uv - 0.5;
    float r = length(centered_uv);
    float a = atan(centered_uv.y, centered_uv.x);

    // 1. Depth and Radial Structure (from B)
    // Map r into a depth factor, emphasizing closer/further
    float z = 1.0 / (r * 1.5 + 0.1);

    // 2. Arch/Ring Structure (from A and B combined)
    // Arch definition (A)
    float arch1 = abs(r - (0.22 + 0.08*cos(4.0*a + 1.3*iTime)));
    float arch2 = abs(r - (0.38 + 0.07*cos(6.0*a - 1.1*iTime)));
    float arch3 = abs(r - (0.58 + 0.05*cos(8.0*a + 0.7*iTime)));

    // Ring definition (B)
    float ring = smoothstep(0.15, 0.0, abs(sin(12.0*r + iTime * 2.0)));

    // 3. Banding Structure (from B)
    float f1 = sin(10.0*a + 3.0*z - 2.0*iTime);
    float f2 = cos(16.0*a - 4.0*z + 1.7*iTime);
    float bands = smoothstep(0.25, 0.05, abs(f1*f2));

    // Combine structure factors (A's modulation style mixed with B's bands/ring)
    float structure_mod = 1.0 + 1.5*bands + 0.7*ring;

    // 4. Palette Input Calculation (B's complexity)
    float palette_t = 0.08*iTime + 0.1*z + 0.5*f1;

    vec3 col = pal(palette_t);

    // Apply spatial distortion based on arches and time wave (A's sweep style)
    float sweep = pow(max(0.0,cos(a - 0.8*iTime)),10.0);

    // Final modulation
    col *= structure_mod * 0.2 + 1.4*arch1 + 1.0*arch2 + 0.8*arch3 + 0.8*sweep;

    // Apply radial falloff and color shift (A's radial falloff mixed with B's depth influence)
    col *= exp(-1.5*r * r * 0.5);
    col += 0.1 * sin(a * 5.0 + iTime * 0.5);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
