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
    float t = iTime * 0.7;
    float x = uv.x * 10.0 + t * 3.0;
    float y = uv.y * 10.0 + t * 4.0;
    float flow_x = sin(x * 0.5) * cos(y * 0.5 + t * 0.5);
    float flow_y = cos(x * 0.5 + t * 0.5) * sin(y * 0.5);
    return uv + vec2(flow_x * 1.5, flow_y * 1.5);
}

vec3 color_oscillation(vec2 uv)
{
    float t = iTime * 2.0;
    float mag = length(uv);
    float angle = atan(uv.y, uv.x);
    float val = sin(angle * 8.0 + t) * cos(mag * 5.0 + t * 1.5);
    return vec3(val * 0.5 + 0.5, 0.5, 1.0 - val * 0.5);
}

vec3 ripple(vec2 uv)
{
    float time_factor = iTime * 1.8;
    float val = sin(uv.x * 12.0 + time_factor) * cos(uv.y * 8.0 - time_factor * 0.5);
    return vec3(val, 1.0 - val, 0.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Base coordinates definition
    vec2 uv_base = uv * vec2(12.0, 8.0) - vec2(1.0, 1.0);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Color modulation based on flow position
    vec3 c = color_oscillation(f * 1.2);

    // Apply Ripple distortion
    vec3 r = ripple(f * 1.5);

    // Introduce ripple magnitude influence
    float flow_mag = length(f);
    float ripple_influence = sin(flow_mag * 10.0 + iTime * 5.0) * 0.2;
    c *= (1.0 + ripple_influence);

    // Introduce a secondary layer based on flow characteristics
    float depth_mod = sin(f.x * 15.0 + iTime) * cos(f.y * 7.0 - iTime * 0.5);

    // Mix colors using flow-based depth
    c.r = mix(c.r, depth_mod * 1.5, 0.5);
    c.g = mix(c.g, depth_mod * 0.8, 0.5);
    c.b = mix(c.b, depth_mod * 0.5, 0.5);

    // Final intensity based on flow magnitude and time
    float intensity = pow(1.0 - flow_mag * 0.5, 2.0) * 1.5;

    vec3 finalColor = c * (1.0 + ripple_influence);

    // Final exposure based on time effects
    finalColor *= (1.0 + sin(iTime * 0.5) * 0.2);
    finalColor *= (1.0 + cos(iTime * 0.3) * 0.1);

    fragColor = vec4(finalColor, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
