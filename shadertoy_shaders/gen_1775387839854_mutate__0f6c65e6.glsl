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

vec2 flowA(vec2 uv)
{
    return uv * 1.1 + vec2(
        sin(uv.x * 6.0 + iTime * 1.5) * 0.12,
        cos(uv.y * 5.5 + iTime * 2.0) * 0.08
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 8.0 + iTime * 0.7) * 0.18,
        cos(uv.y * 7.0 + iTime * 1.0) * 0.12
    );
}

vec3 palette(float t)
{
    float c = 0.5 * (1.0 + sin(t * 1.5));
    float g = 0.3 + 0.5 * cos(t * 2.0);
    float b = 0.7 * (1.0 - abs(sin(t * 3.0)));
    return vec3(c, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Polar coordinates centered at (0,0)
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Flow Distortion (Combining flowA and flowB effects)
    vec2 flow_combined = normalize(flowA(uv) + flowB(uv));
    uv += flow_combined * 0.15;

    // Phase shifting based on position and time
    float phase = uv.x * 5.0 + uv.y * 4.0 + iTime * 3.0;
    uv = uv + vec2(
        sin(phase * 0.4) * 0.2,
        cos(phase * 0.5) * 0.1
    );

    // Time-based rotation and warping
    float angle = iTime * 1.8 + uv.x * 2.5 + uv.y * 1.8;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Apply final fine detail movement
    uv = flowA(uv);

    // Palette calculation based on radial distance and angular structure
    float r_mod = r * 8.0;
    float a_mod = a * 12.0;

    // Combine flow and structural elements to determine palette time
    float palette_t = (r_mod + a_mod) * 4.0 + iTime * 1.0;
    vec3 col = palette(palette_t);

    // Complex color adjustments emphasizing high contrast and light leaks
    col += 1.0 * sin(iTime * 0.6 + uv.x * 11.0);
    col += 0.7 * cos(uv.y * 15.0 + iTime * 0.4);
    col += 0.4 * sin(uv.x * 20.0 + uv.y * 8.0 + iTime * 0.2);

    // Introduce an additive element based on flow magnitude
    float flow_mag = length(flowA(uv) - uv);
    col += flow_mag * 0.3;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
