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

vec2 flow(vec2 uv)
{
    float t = iTime * 0.8;
    float x = uv.x * 15.0 + t * 5.0;
    float y = uv.y * 12.0 + t * 4.0;
    float flow_x = sin(x * 0.6) * cos(y * 0.6 + t * 0.3);
    float flow_y = cos(x * 0.7 + t * 0.2) * sin(y * 0.4);
    return uv + vec2(flow_x * 2.5, flow_y * 2.5);
}

vec3 color_hue(vec2 uv)
{
    float t = iTime * 1.5;
    float h = atan(uv.y, uv.x) * 6.28;
    float s = 0.5 + 0.5 * cos(h * 3.0 + t * 1.2);
    float l = 0.5 + 0.5 * sin(t * 2.0);
    return h / 6.28 + vec3(s, s, s);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Base coordinates definition
    vec2 uv_base = uv * vec2(10.0, 10.0) - vec2(5.0, 5.0);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Color modulation based on flow position
    vec3 c = color_hue(f * 1.5);

    // Introduce distance-based wave distortion
    float dist = length(f);
    float wave = sin(dist * 8.0 + iTime * 4.0) * 0.15;
    c *= (1.0 + wave);

    // Shift coordinates based on time and flow direction
    vec2 shifted_uv = uv * 1.1 + vec2(sin(iTime * 0.5) * 0.05, cos(iTime) * 0.05);

    // Final color integration based on phase
    float phase = f.x * 10.0 + f.y * 5.0 + iTime * 2.0;
    vec3 final_c = c * (0.5 + 0.5 * cos(phase * 3.0));

    fragColor = vec4(final_c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
