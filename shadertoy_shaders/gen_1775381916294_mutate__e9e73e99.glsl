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
    return 0.02 + 0.95 * sin(12.0 * t * 3.0 + 2.5 * vec3(0.1, 0.4, 0.7));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Polar coordinates centered at (0,0)
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Radial flow scaled by time and distance
    float flow_r = r * 15.0 + iTime * 5.0;
    float flow_a = a * 18.0 + iTime * 6.0;

    // Complex radial wave modulation, higher frequency interaction
    float wave = sin(r * 8.0 + flow_a * 0.4) * cos(a * 10.0 + iTime * 3.5);

    // Depth modulation based on angle and time distortion
    float z = 1.0 / (r * 5.0 + 1.0 + 0.7 * sin(a * 22.0 + iTime * 10.0));

    // Combined phase calculation, emphasizing the flow and wave interaction
    float phase = flow_r * 0.4 + wave * 0.6 * (1.0 - r * 0.6);

    // Density calculation, focusing density near the center but modulated by angular rotation
    float density = sin(a * 50.0 + iTime * 8.0) * exp(-r * r * 4.0);

    // Dynamic palette input modulated by depth and density contrast
    float palette_t = 0.05 * iTime + sin(phase * 20.0) * 0.8 + z * 0.4;

    vec3 col = pal(palette_t);

    // Introduce angular velocity warping based on flow
    float angular_warp = a * 70.0 + iTime * 25.0;

    // Radial emphasis based on inverse distance and density
    float radial_emphasis = exp(-r * r * 5.0) * (1.0 + density * 5.0);

    // Refine color by applying angular rotation and density influence
    col *= 1.8 + 5.0 * density;
    col += sin(angular_warp * 2.0) * 1.0;
    col *= radial_emphasis * 0.8;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
