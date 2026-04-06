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
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Introduce flow and distortion based on time
    float flow = a * 4.0 + iTime * 2.5;
    float wave = sin(r * 5.0 + iTime * 1.5) * cos(a * 10.0);

    // Calculate depth-based variation
    float z = 1.0 / (r * 1.2 + 0.5);

    // Combine flow and wave into a primary phase
    float phase = flow + wave * 2.0;

    // Density calculation based on angle and distance
    float density = abs(sin(a * 5.0 + iTime * 3.0)) * exp(-r * r * 1.5);

    // Dynamic palette input
    float palette_t = 0.05*iTime + sin(phase * 3.0) * 0.5 + z * 0.3;

    vec3 col = pal(palette_t);

    // Apply strong angular shift and modulation
    float angular_effect = sin(a * 12.0 + iTime * 5.0);
    float radial_emphasis = cos(r * 8.0 + iTime * 3.0) * 0.5;

    // Refine color based on dynamic terms
    col *= 1.5 + 2.5 * density;
    col += angular_effect * 0.4;
    col += radial_emphasis * 0.3;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
