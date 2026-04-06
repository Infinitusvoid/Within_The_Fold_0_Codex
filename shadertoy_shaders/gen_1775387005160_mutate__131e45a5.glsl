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
    return 0.05 + 0.9 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Polar coordinates centered at (0,0)
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // New flow based on exponential and rotational mixing
    float flow = r * 3.0 + a * 5.0 + iTime * 3.5;
    float wave = sin(r * 4.0 + iTime * 1.5) * cos(a * 5.0);

    // Calculate depth/distance modulation using a hyperbolic inverse relationship
    float z = 1.0 / (r * 1.5 + 0.8 + 0.2 * sin(a * 8.0));

    // Combine flow and wave into a primary phase, modulated by radial distance
    float phase = flow * 0.5 + wave * 0.5 * (1.0 - r * 0.4);

    // Density calculation based on angular variation and inverse radial falloff
    float density = sin(a * 15.0 + iTime * 4.0) * exp(-r * r * 2.5);

    // Dynamic palette input modulated by depth and time
    float palette_t = 0.2 * iTime + sin(phase * 8.0) * 0.4 + z * 0.25;

    vec3 col = pal(palette_t);

    // Apply strong angular and radial modulation using fractal noise mixing
    float angular_effect = sin(a * 22.0 + iTime * 10.0) * 0.5 + 0.5;
    float radial_emphasis = pow(cos(r * 10.0 + iTime * 5.0), 1.5) * 0.7;

    // Refine color based on density and spatial flow
    col *= 1.2 + 4.0 * density;
    col += angular_effect * 0.5;
    col += radial_emphasis * 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
