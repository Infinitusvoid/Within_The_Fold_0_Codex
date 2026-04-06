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
    float x = uv.x * 25.0 + t * 1.8;
    float y = uv.y * 25.0 + t * 2.2;
    float flow_x = sin(x * 0.4) * cos(y * 0.3 + t * 0.6);
    float flow_y = cos(x * 0.3 + t * 0.5) * sin(y * 0.4);
    return uv + vec2(flow_x * 1.3, flow_y * 1.5);
}

vec3 hue_shift(vec2 uv)
{
    float t = iTime * 1.5;
    float noise_val = sin(uv.x * 20.0 + t * 1.5) * cos(uv.y * 20.0 - t * 0.8);
    float hue = (noise_val * 0.4 + 0.6) * 180.0;
    float saturation = 0.2 + noise_val * 0.7;
    float lightness = 0.4 + noise_val * 0.5;
    return vec3(hue, saturation, lightness);
}

vec3 displacement(vec2 uv)
{
    float t = iTime * 4.0;
    float wave_x = sin(uv.x * 10.0 + t * 1.0);
    float wave_y = cos(uv.y * 15.0 + t * 0.5);
    float offset = (wave_x * wave_y) * 0.2;
    return vec3(offset, 0.5 + wave_x * 0.3, 0.2 + wave_y * 0.2);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Base coordinates definition, introducing asymmetry
    vec2 uv_base = uv * vec2(20.0, 10.0) - vec2(1.0, 0.5);

    // Apply Flow warping
    vec2 f = flow(uv_base);

    // Apply Hue modulation based on flow magnitude
    vec3 c = hue_shift(f * 1.2);

    // Apply Displacement
    vec3 d = displacement(f * 1.1);

    // Introduce contrast based on flow divergence
    float flow_mag = length(f);

    // Color mixing based on displacement magnitude
    c = mix(c, d, flow_mag * 0.6);

    // Enhance dynamic effect based on time using different modulation
    float time_factor = iTime * 5.0;
    c.r = mix(c.r, 0.4, sin(time_factor * 0.8) * 0.6);
    c.g = mix(c.g, 0.75, cos(time_factor * 0.5) * 0.4);
    c.b = mix(c.b, 0.95, sin(time_factor * 0.3) * 0.15);

    // Final intensity modulation based on flow divergence
    float divergence = length(f) * 2.0;
    float intensity = pow(1.0 - divergence * 0.10, 2.0);

    vec3 finalColor = c * intensity;

    fragColor = vec4(finalColor, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
