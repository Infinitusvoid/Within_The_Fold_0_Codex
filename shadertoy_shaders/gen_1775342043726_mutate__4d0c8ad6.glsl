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
    float t = iTime * 1.5;
    float x = uv.x * 8.0 + t * 2.5;
    float y = uv.y * 10.0 + t * 3.5;
    float flow_x = sin(x * 0.8) * cos(y * 0.5 + t * 0.4);
    float flow_y = cos(x * 0.4 + t * 0.2) * sin(y * 0.7);
    return uv + vec2(flow_x * 1.8, flow_y * 1.8);
}

vec3 color_oscillation(vec2 uv)
{
    float t = iTime * 3.0;
    float mag = length(uv);
    float angle = atan(uv.y, uv.x);
    float val = sin(angle * 12.0 + t * 0.5) * cos(mag * 6.0 + t * 1.0);
    vec3 c = vec3(0.5 + 0.5 * sin(val * 3.0), 0.2 + 0.8 * cos(val * 4.0), 1.0 - 0.5 * sin(val * 2.5));
    return c;
}

vec3 ripple(vec2 uv)
{
    float time_factor = iTime * 2.5;
    float val = sin(uv.x * 15.0 + time_factor) * cos(uv.y * 10.0 - time_factor * 0.7);
    vec3 r = vec3(val * 0.7, 0.1, 0.7 - val * 0.3);
    return r;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Base coordinates definition
    vec2 uv_base = uv * vec2(15.0, 10.0) - vec2(1.5, 0.5);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Color modulation based on flow position
    vec3 c = color_oscillation(f * 1.5);

    // Apply Ripple distortion
    vec3 r = ripple(f * 2.0);

    // Introduce ripple magnitude influence
    float flow_mag = length(f);
    float ripple_influence = sin(flow_mag * 8.0 + iTime * 4.0) * 0.3;
    c *= (1.0 + ripple_influence * 1.5);

    // Introduce a secondary layer based on flow characteristics
    float depth_mod = sin(f.x * 20.0 + iTime * 1.2) * cos(f.y * 9.0 - iTime * 0.6);

    // Mix colors using flow-based depth
    c.r = mix(c.r, depth_mod * 1.2, 0.6);
    c.g = mix(c.g, depth_mod * 0.8, 0.4);
    c.b = mix(c.b, depth_mod * 0.5, 0.5);

    // Final intensity based on flow magnitude and time
    float intensity = pow(1.0 - flow_mag * 0.4, 1.5) * 1.8;

    vec3 finalColor = c * (1.0 + ripple_influence);

    // Final exposure based on time effects
    finalColor *= (1.0 + sin(iTime * 0.6) * 0.25);
    finalColor *= (1.0 + cos(iTime * 0.4) * 0.15);

    fragColor = vec4(finalColor, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
