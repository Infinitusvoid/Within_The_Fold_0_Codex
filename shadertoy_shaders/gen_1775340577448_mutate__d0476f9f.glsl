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

vec2 ripple(vec2 uv)
{
    float t = iTime * 1.5;
    float freq = 8.0 + sin(uv.x * 12.0 + t * 0.8) * 4.0;
    float amplitude = 1.5 + cos(uv.y * 10.0 + t * 1.2) * 0.5;
    float x = uv.x * freq * 1.5 + t * 1.0;
    float y = uv.y * freq * 0.8 + t * 0.6;
    float val = sin(x * 4.0) * amplitude * 0.8 + cos(y * 3.0);
    return uv * 1.8 + vec2(val * 0.3, val * 0.6);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Map coordinates to center and scale them
    uv = uv * 2.0 - 1.0;

    // Apply time-based translation and noise offset
    vec2 offset = uv * 50.0 + iTime * 4.0;

    // Introduce complex flow noise
    float flow_noise = sin(offset.x * 8.0 + offset.y * 5.0 + iTime * 2.0);

    // Apply ripple distortion
    uv = ripple(uv);
    uv += offset * 0.03; 

    // Calculate coordinate-based values using modulated frequencies
    float v = sin(uv.x * 20.0 + iTime * 5.0);
    float u = cos(uv.y * 22.0 + iTime * 6.0);

    // Introduce a complex warping depth effect
    float warp = sin(uv.x * 10.0 + uv.y * 10.0 + iTime * 1.0) * 0.5 + 0.5;

    // Base color calculation emphasizing the flow interaction
    vec3 base_color = vec3(v * 1.5, u * 1.8, 0.05);

    // Apply chromatic shift based on flow noise
    vec3 final_color = base_color;
    final_color.r = mix(final_color.r, 0.9, flow_noise * 0.6);
    final_color.g = mix(final_color.g, 0.15, flow_noise * 0.4);
    final_color.b = mix(final_color.b, 0.5, flow_noise * 0.8);

    // Introduce a volumetric bloom based on the warp
    float bloom = smoothstep(0.3, 1.0, warp * 1.5);

    // Apply a strong internal glow based on noise
    float glow = pow(flow_noise, 4.0) * 2.0;

    // Final color mixing
    final_color *= bloom;
    final_color += vec3(0.1, 0.8, 1.0) * glow;

    fragColor = vec4(final_color,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
