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
    float t = iTime * 2.0;
    float x_offset = sin(uv.x * 12.0 + t * 1.5);
    float y_offset = cos(uv.y * 10.0 - t * 1.0);
    float flow_x = sin(uv.x * 6.0 + t * 0.9) * cos(uv.y * 4.0 - t * 0.7);
    float flow_y = sin(uv.y * 5.0 + t * 1.1) * cos(uv.x * 3.0 - t * 0.8);
    return uv + vec2(flow_x * 0.5, flow_y * 0.5);
}

vec3 color_shift(vec2 uv)
{
    float time_factor = iTime * 4.0;
    float noise_val = sin(uv.x * 15.0 + time_factor) * cos(uv.y * 12.0 - time_factor * 0.5);

    // Use noise to drive HUE and Saturation
    float hue = 0.5 + 0.5 * noise_val;
    float saturation = 0.5 + 0.5 * noise_val * 0.5;
    float value = 0.5 + noise_val * 0.5;

    vec3 c = (hue + 0.5) * 0.5 + vec3(value, value*0.8, value*0.6);

    return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Base coordinates definition, slightly altered
    vec2 uv_base = uv * vec2(10.0, 7.0) - vec2(1.5, 1.5);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Generate dynamic color shifts based on flow magnitude
    vec3 c = color_shift(f * 1.5);

    // Introduce complex chromatic aberration based on flow direction
    float flow_mag = length(f);
    float distortion = 1.5 * sin(flow_mag * 8.0 + iTime * 5.0);

    // Apply distortion to UVs before sampling or outputting
    vec2 final_uv = uv + vec2(distortion * f.x * 0.1, distortion * f.y * 0.1);

    // Final color manipulation
    c = mix(vec3(0.1, 0.1, 0.3), c, flow_mag * 0.5);

    // Time-based oscillation and contrast
    float time_osc = sin(iTime * 3.0) * 0.05 + 0.95;
    c *= time_osc;

    // Final output
    fragColor = vec4(c, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
