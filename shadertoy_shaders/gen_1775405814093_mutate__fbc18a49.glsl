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

vec3 pal(float t){ return 0.5 + 0.5*sin(6.0*(vec3(0.1, 0.8, 1.5)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Calculate radial distance and scale modulation
    vec2 center = vec2(0.5);
    float dist = length(uv - center);
    float scale = 1.0 + 10.0 * dist;

    // Calculate time-based flow field
    vec2 flow_uv = uv * scale;

    // Introduce swirling flow based on time and position using complex angle variation
    float angle = atan(flow_uv.y, flow_uv.x) + iTime * 0.8;
    float radius = length(flow_uv);

    // Flow components, modified by a periodic effect
    vec2 flow = flow_uv * (1.0 + sin(angle * 5.0) * 0.5);

    // Depth factor based on perspective
    // Introduce curvature based on distance
    float depth = 1.0 / (uv.y * 3.0 + 1.0) * (1.0 + dist * 0.5);

    // Calculate warped coordinates based on flow and depth
    vec2 p = flow;
    float x = p.x * depth;
    float y = p.y * depth * 1.5; // Increased vertical stretch
    float z = depth * 2.0 - iTime * 0.5;

    // Complex phase manipulation for color variation, introducing wave distortion
    float phase_x = sin(x * 7.0 + iTime * 2.0) + cos(y * 3.0);

    // Use smoothstep on the fractional part for contrast and banding
    float l_factor = smoothstep(0.35, 0.15, abs(fract(phase_x) - 0.5));
    float r_factor = smoothstep(0.35, 0.15, abs(fract(x * 4.0) - 0.5));

    // Blend factors
    float glow = l_factor * 0.8 + r_factor * 0.7;

    // Color calculation using the palette function
    vec3 col = pal(x * 3.0 + z) * glow * 2.0;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
