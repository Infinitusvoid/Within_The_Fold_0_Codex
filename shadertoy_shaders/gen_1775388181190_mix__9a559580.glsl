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

mat2 rot(float a){ float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }
vec3 pal_a(float t)
{
    return 0.5 + 0.5 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}
vec3 pal_b(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.0,0.33,0.67)+t));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // --- Base coordinate setup (from B) ---
    uv *= rot(0.1*iTime);

    // Polar coordinates
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // --- Combined Flow and Depth (from A) ---
    // Calculate flow based on polar coordinates and time
    float flow = r * 2.0 + iTime * 0.5;

    // Apply flow rotation to UVs (from B)
    vec2 flow_uv = vec2(cos(a + flow * 0.5) * r, sin(a + flow) * r);
    uv = flow_uv;

    // Calculate inverse distance/depth factor (from A)
    float z = 1.0 / (r * 3.0 + 0.5);

    // Introduce angular flow modulated by time and depth (from A)
    float angle_flow = sin(a * 15.0 + iTime * 2.0);

    // Introduce radial displacement based on depth (from A)
    float radial_shift = z * 2.0;

    // --- Phase Calculation ---
    // Modify the base time/angle input based on flow and shift
    float phase_a = 10.0*a + iTime * 1.2 + angle_flow * 1.5;
    float phase_r = 18.0*r + radial_shift * 0.8 + iTime * 0.9;

    // --- Feature Generation (from A) ---
    // Calculate density using fractal noise integration
    float f1 = sin(phase_a * 0.5);
    float f2 = cos(phase_r * 0.4);

    // Create density
    float density = abs(f1 * f2 * 2.0);
    float bands = smoothstep(0.35, 0.1, density * 3.0);

    // Dynamic pulsing rings
    float ring = pow(sin(18.0*r + iTime * 6.0), 4.0);

    // --- Final Color Calculation (Mixing Palettes and Modulators) ---

    // Use a combined time/distance factor for palette input
    float palette_t = 0.05*iTime + f1*0.6 + radial_shift*0.5;

    // Interpolate the palette between A and B, weighted by radial structure
    vec3 col = mix(pal_a(palette_t), pal_b(iTime + r), (r*r)*0.1);

    // Combine features with emphasis on rings and density (from A)
    col *= 0.08 + 3.5*bands + 1.2*ring;

    // Apply radial falloff (from A)
    col *= exp(-1.0*r * r * 0.7);

    // Apply angular shift, introducing chromatic variance (from A)
    col += 0.15 * sin(a * 15.0 + iTime * 3.0);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
