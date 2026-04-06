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
    return 0.1 + 0.9 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Polar coordinates setup from A
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Depth/Distance calculation (blending A's inverse relationship with B's distance falloff)
    float z = 1.0 / (r * 1.5 + 0.2) + iTime * 1.5;

    // Flow and Wave calculation from A
    float flow = r * 2.0 + a * 3.0 + iTime * 1.5;
    float wave = sin(r * 8.0 + iTime * 2.0) * cos(a * 5.0);

    // Density calculation from A
    float density = sin(a * 7.0 + iTime * 2.5) * exp(-r * r * 2.0);

    // Dynamic palette input derived from A
    float phase = flow * 0.5 + wave * 0.5;
    float palette_t = 0.05*iTime + sin(phase * 4.0) * 0.4 + z * 0.2;

    vec3 col = pal(palette_t);

    // Apply radial and angular modulation from A
    float angular_effect = cos(a * 15.0 + iTime * 6.0);
    float radial_emphasis = sin(r * 6.0 + iTime * 3.0) * 0.5;

    // Apply vertical masking effect from B, using r for falloff
    float y1 = 0.22*sin(3.0*z + iTime);
    float y2 = 0.22*sin(3.0*z + iTime + 3.14159);
    float l1 = smoothstep(0.05,0.0,abs(uv.y-y1));
    float l2 = smoothstep(0.05,0.0,abs(uv.y-y2));

    col *= l1 + l2; // Combine vertical masking effects

    // Apply radial falloff from B
    col *= 0.7 / (1.0 + 2.0 * r);

    // Final adjustments
    col += angular_effect * 0.5;
    col += radial_emphasis * 0.3;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
