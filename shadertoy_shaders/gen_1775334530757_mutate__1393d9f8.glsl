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
    float a = iTime * 0.6;
    float b = iTime * 0.4;
    float flow_x = sin(uv.x * 6.0 + a * 2.0) * cos(uv.y * 4.0 - b * 1.5);
    float flow_y = cos(uv.y * 5.0 + a * 3.0) * sin(uv.x * 3.0 + b * 2.5);
    return uv + vec2(flow_x * 0.8, flow_y * 0.6);
}

vec3 wave_color(vec2 uv)
{
    float t = iTime * 3.0;
    float val = sin(uv.x * 15.0 + t) * cos(uv.y * 10.0 - t * 0.8);
    return vec3(val * 1.5, 1.0 - val * 0.5, val * 0.8);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Base coordinates definition
    vec2 uv_base = uv * vec2(8.0, 6.0) - vec2(1.0, 1.0);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Wave color modulation
    vec3 c = wave_color(f * 2.0);

    // Introduce radial flow based on distance from center
    float dist = length(f);
    float radial_shift = 1.0 - smoothstep(0.0, 1.0, 1.0 - dist * 2.0);
    c *= (1.0 + radial_shift * 0.3);

    // Add secondary layer based on flow direction
    float depth_mod = sin(f.x * 12.0 + iTime * 1.5) * cos(f.y * 8.0 - iTime * 0.9);
    c.r += depth_mod * 0.4;
    c.g -= depth_mod * 0.3;
    c.b += depth_mod * 0.2;

    // Final intensity scaling using a complex time modulation
    float overall_intensity = sin(iTime * 1.2) * 0.5 + cos(iTime * 0.7) * 0.5;

    vec3 finalColor = c * overall_intensity;

    fragColor = vec4(finalColor, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
