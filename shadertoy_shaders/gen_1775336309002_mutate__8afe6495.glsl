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
    float x = uv.x * 15.0 + t * 4.0;
    float y = uv.y * 10.0 + t * 3.0;
    float flow_x = sin(x * 0.3) * cos(y * 0.4 + t * 0.7);
    float flow_y = cos(x * 0.4 + t * 0.6) * sin(y * 0.3);
    return uv + vec2(flow_x * 1.2, flow_y * 1.0);
}

vec3 color_shift(vec2 uv)
{
    float t = iTime * 1.5;
    float angle = atan(uv.y, uv.x);
    float mag = length(uv);
    float val = sin(angle * 10.0 + t) * cos(mag * 6.0 + t * 0.5);

    // Shift colors based on the oscillation
    vec3 c = vec3(0.5 + 0.5 * sin(val * 3.0 + t * 0.5), 0.2 + 0.4 * sin(val * 2.0 + t), 1.0 - 0.5 * sin(val * 1.5 + t * 0.5));

    return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Base coordinates definition
    vec2 uv_base = uv * vec2(16.0, 10.0) - vec2(1.0, 1.0);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Color modulation
    vec3 c = color_shift(f * 1.1);

    // Introduce dynamic refraction based on flow magnitude and frame
    float flow_mag = length(f);
    float refraction = sin(flow_mag * 8.0 + iTime * 6.0) * 0.3;
    c *= (1.0 + refraction);

    // Shift coordinates based on time and frame
    vec2 shifted_uv = uv + vec2(sin(iTime * 0.4) * 0.05, cos(iTime * 0.2) * 0.05) * (1.0 + iFrame * 0.1);

    // Final visual depth based on flow direction
    float depth_mod = dot(f, vec2(0.5, 0.5)) * 2.0;

    // Apply contrast based on frame number
    float contrast = 1.0 + sin(iFrame * 0.1) * 0.1;

    c *= contrast;

    fragColor = vec4(c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
