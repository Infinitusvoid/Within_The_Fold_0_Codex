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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.0,0.3,0.6)+t)); }

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 9.0 - iTime * 0.9));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv * 2.5 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 6.0 - iTime * 0.7) * 0.25
    );
}

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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply complex flow warping
    vec2 flow_uv = flow(uv);

    // Apply rotational flow based on complex angle
    float angle = iTime * 0.2 + uv.x * 6.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    flow_uv = rotationMatrix * flow_uv;

    // Apply secondary wave structure
    flow_uv = waveA(flow_uv);

    // Use flow for positional shifting
    flow_uv.x += sin(iTime * 0.5) * 0.1;
    flow_uv.y += cos(iTime * 0.3) * 0.1;

    // Generate dynamic value based on complex interaction
    float t = sin(flow_uv.x * 5.0 + iTime * 1.5) + cos(flow_uv.y * 4.5 + iTime * 0.5);

    // Base color generation using palette (from A)
    vec3 col1 = palette(t * 1.5);

    // Introduce color oscillation based on flow position (from B)
    vec3 c = color_oscillation(flow_uv * 1.2);

    // Introduce ripple based on flow magnitude and time
    float flow_mag = length(flow_uv);
    float ripple = sin(flow_mag * 10.0 + iTime * 5.0) * 0.2;
    c *= (1.0 + ripple);

    // Final color integration based on depth/direction
    float depth_mod = sin(flow_uv.x * 6.0 + iTime * 3.0) * cos(flow_uv.y * 2.0 - iTime * 0.8);
    c.r = mix(c.r, depth_mod * 1.5, 0.5);
    c.g = mix(c.g, depth_mod * 0.8, 0.5);
    c.b = mix(c.b, depth_mod * 0.5, 0.5);

    // Final intensity based on the overall flow magnitude
    float intensity = pow(1.0 - flow_mag * 0.5, 2.0) * 1.5;

    vec3 finalColor = c * intensity;

    // Introduce chromatic aberration based on base UV movement
    float aberration = abs(uv.x - 0.5) * 2.0;
    finalColor.r += aberration * 0.15;
    finalColor.b -= aberration * 0.15;

    // Apply noise and contrast boost
    float noise_factor = sin(flow_uv.x * 15.0 + iTime * 2.0) * cos(flow_uv.y * 10.0 - iTime * 0.8);
    finalColor = mix(finalColor, vec3(0.05, 0.15, 0.02), noise_factor * 0.7);

    // Final intensity adjustment
    finalColor *= 1.7;

    fragColor = vec4(finalColor, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
