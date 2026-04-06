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

    // --- Base coordinate setup ---
    uv *= rot(0.1*iTime);

    // Polar coordinates
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // --- Dynamic Flow and Depth ---
    // Complex flow interaction based on radial and angular velocity
    float flow_r = r * 2.0 + iTime * 0.7;
    float flow_a = 1.5 + sin(a * 4.0 + iTime * 2.0);

    // Apply flow rotation to UVs
    vec2 flow_uv = vec2(cos(a + flow_r * 0.4) * r, sin(a + flow_a * 0.3) * r);
    uv = flow_uv;

    // Calculate inverse distance/depth factor (using r for scale)
    float z = 1.0 / (r * 3.5 + 0.5);

    // Introduce angular flow modulated by depth
    float angle_flow = sin(a * 30.0 + iTime * 2.5) * z * 4.0;

    // Introduce radial displacement based on depth
    float radial_shift = z * 2.5;

    // --- Phase Calculation ---
    // Modify the base time/angle input based on flow and shift
    float phase_a = 12.0*a + iTime * 1.5 + angle_flow;
    float phase_r = 20.0*r + radial_shift * 0.8 + iTime * 1.2;

    // --- Feature Generation ---
    // Calculate density using complex wave interaction, emphasizing flow
    float f1 = sin(phase_a * 0.6) + cos(phase_r * 0.5);
    float f2 = sin(phase_r * 0.4) * flow_a;

    // Create density based on interaction
    float density = abs(f1 * f2 * 2.0);
    float bands = smoothstep(0.45, 0.15, density * 5.0);

    // Dynamic pulsing rings based on radial position and time
    float ring = pow(sin(35.0*r + iTime * 10.0), 4.0);

    // --- Final Color Calculation ---

    // Use a combined time/distance factor for palette input
    float palette_t = 0.02*iTime + f1*0.8 + radial_shift*0.5;

    // Interpolate the palette between A and B, weighted by radial structure
    vec3 col = mix(pal_a(palette_t), pal_b(iTime + r*2.0), (r*r)*0.1);

    // Combine features with emphasis on rings and density
    col *= 0.05 + 5.0*bands + 2.0*ring;

    // Apply inverse distance falloff with non-linear effect
    col *= exp(-3.0*r * r * 0.5);

    // Apply angular shift and chromatic variance
    col += 0.3 * sin(a * 15.0 + iTime * 5.0);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
