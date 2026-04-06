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
vec3 pal(float t)
{
    vec3 c = vec3(0.1, 0.15, 0.3);
    c += 0.5 * sin(t * 0.3 + iTime * 0.7);
    c += 0.4 * cos(t * 1.2 + iTime * 0.5);
    return c;
}

vec2 flowB(vec2 uv)
{
    return vec2(sin(uv.x * 7.0 + iTime * 2.0), cos(uv.y * 8.0 + iTime * 3.0));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.5 + iTime * 0.8) * 0.4,
        cos(uv.y * 10.0 + iTime * 1.2) * 0.3
    );
}

vec2 flow(vec2 uv)
{
    float t = iTime * 2.0;

    // Base flow structure
    vec2 p = uv * 10.0;

    // Introduce complex trigonometric flow
    float flow_x = sin(p.x * 1.5 + t * 0.8) * cos(p.y * 0.5 + t * 1.2);
    float flow_y = cos(p.x * 0.7 + t * 1.5) * sin(p.y * 1.1 + t * 0.5);

    // Return the warped coordinates
    return uv + vec2(flow_x * 1.5, flow_y * 1.5);
}

vec3 color_flow(vec2 uv)
{
    float t = iTime * 3.0;
    float angle = atan(uv.y, uv.x) * 6.28;

    // Calculate saturation based on flow magnitude and time
    float flow_mag = length(uv);
    float saturation = 0.5 + 0.5 * sin(angle * 4.0 + t);

    // Calculate value based on position and time modulation
    float value = 0.3 + 0.7 * abs(sin(angle * 2.0 + t * 0.5));

    // Calculate hue based on the angle and a noise component
    float hue = angle + (flow_mag * 1.5) * 3.14159;

    // Apply a time-based shift to the color space
    hue += sin(t * 0.5) * 0.5;

    return vec3(hue / 6.28, saturation, value);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Apply complex flow warping
    uv = flow(uv);
    uv = flowA(uv);

    // Apply Rotation (from Shader A)
    vec2 p = uv * rot(0.5*iTime);

    // Radial/Angular Effects (from Shader A)
    float r = length(p);
    float a = atan(p.y, p.x);

    // Distance/Depth calculation (from Shader A)
    float z = 1.0 / (r * 0.5 + 0.2);

    // Flow-based variations (from Shader A derived concept)
    float f1 = sin(12.0*a + 5.0*z - 3.0*iTime);
    float f2 = cos(15.0*a - 3.5*z + 2.5*iTime);

    // Ring calculation (from Shader A derived concept)
    float ring = smoothstep(0.1, 0.0, abs(sin(15.0*r - 4.0*iTime)));

    // Bands calculation (from Shader A derived concept)
    float bands = smoothstep(0.2, 0.0, abs(f1 * f2 * 1.5));

    // Palette calculation (using Shader A's palette structure)
    float t = 0.1*iTime + 0.3*z + 0.1*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff (mixing effects)
    float glow = 1.0 - smoothstep(0.0, 0.2, r);

    // Apply modulation from B (bands and ring)
    col *= 0.1 + 2.5*bands + 1.0*ring;

    // Apply exponential falloff (from Shader A)
    col *= exp(-1.2*r * 0.8);

    // Apply color flow based on warped coordinates
    vec3 flow_color = color_flow(uv * 0.9);

    // Final color integration based on phase and flow magnitude
    float phase = p.x * 7.0 + p.y * 3.0 + iTime * 1.5;
    vec3 final_c = flow_color * (0.6 + 0.4 * cos(phase * 4.0));

    fragColor = vec4(final_c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
