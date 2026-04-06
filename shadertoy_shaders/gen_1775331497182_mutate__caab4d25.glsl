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
    float a = iTime * 0.5;
    float b = iTime * 0.3;
    float flow_x = sin(uv.x * 5.0 + a) * cos(uv.y * 3.0 + b);
    float flow_y = cos(uv.y * 4.0 + a) * sin(uv.x * 2.0 + b);
    return uv + vec2(flow_x * 0.5, flow_y * 0.5);
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
    vec2 uv_base = uv * vec2(5.0, 3.0) - vec2(1.0, 1.5);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Ripple distortion
    vec3 r = ripple(f * 1.5);

    // Generate dynamic color gradients based on the flow
    float intensity = abs(f.x + f.y);
    float warp_factor = sin(f.x * 5.0 + iTime * 2.0);

    vec3 finalColor = r * (0.5 + 0.5 * warp_factor);

    // Introduce a secondary layer using sine/cosine based on depth
    float depth_mod = sin(f.x * 10.0 + iTime * 0.8) * cos(f.y * 5.0 + iTime * 1.2);
    finalColor.r += depth_mod * 0.5;
    finalColor.g -= depth_mod * 0.2;
    finalColor.b += depth_mod * 0.3;

    // Final exposure based on frame and time
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
