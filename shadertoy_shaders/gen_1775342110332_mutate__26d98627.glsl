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
    float t = iTime * 1.2;
    float x = uv.x * 18.0 + t * 6.0;
    float y = uv.y * 16.0 + t * 5.0;
    float flow_x = sin(x * 0.5) * cos(y * 0.4 + t * 0.5);
    float flow_y = cos(x * 0.6 + t * 0.3) * sin(y * 0.3);
    return uv + vec2(flow_x * 2.0, flow_y * 2.0);
}

vec3 color_hue(vec2 uv)
{
    float t = iTime * 2.5;
    float h = atan(uv.y, uv.x) * 6.28;
    float s = 0.5 + 0.5 * sin(h * 2.5 + t * 1.5);
    float l = 0.5 + 0.5 * cos(t * 1.8);
    return h / 6.28 + vec3(s, s, s) * l;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Base coordinates definition, inverted and scaled differently
    vec2 uv_base = (uv * 20.0 - 10.0) * 0.8;

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Color modulation based on flow position and time
    vec3 c = color_hue(f * 1.2);

    // Introduce distance-based ripple distortion
    float dist = length(f);
    float ripple = sin(dist * 12.0 + iTime * 5.0) * 0.18;
    c *= (1.0 + ripple * 0.5);

    // Introduce perspective/shift based on flow direction
    vec2 flow_dir = normalize(f);
    vec2 shifted_uv = uv * 1.0 + flow_dir * 0.2;

    // Final color integration based on phase and flow intensity
    float phase = f.x * 8.0 + f.y * 4.0 + iTime * 1.5;
    vec3 final_c = c * (0.5 + 0.5 * cos(phase * 4.0));

    fragColor = vec4(final_c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
