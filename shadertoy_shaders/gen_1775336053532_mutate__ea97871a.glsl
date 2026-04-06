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
    float t = iTime * 2.0;
    float freq = 6.0 + iTime * 0.3;
    float x = uv.x * freq + t * 0.7;
    float y = uv.y * freq * 1.1 + t * 0.5;
    float val = sin(x * 5.0) + cos(y * 3.0) + sin(x * 1.5);
    return uv * 1.5 + vec2(val * 0.2, val * 0.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Map coordinates to center and scale them
    uv = uv * 2.0 - 1.0;

    // Apply time-based translation and noise offset
    vec2 offset = uv * 35.0 + iTime * 3.0;

    // Introduce complex layered noise for distortion
    float noise_val = sin(offset.x * 15.0 + offset.y * 10.0 + iTime * 1.2) * 0.5 + 0.5;

    // Apply ripple distortion
    uv = ripple(uv);
    uv += offset * 0.04; // Stronger movement

    // Calculate coordinate-based values (Focusing on chromatic gradient)
    float v = sin(uv.x * 12.0 + iTime * 4.0);
    float u = cos(uv.y * 15.0 + iTime * 3.5);
    // Calculate depth using a complex periodic function
    float depth = pow(sin(uv.x * 8.0 + uv.y * 6.0 + iTime * 0.8), 3.5);

    // Base color calculation, emphasizing the contrast between V and U
    vec3 base_color = vec3(v * 1.5, u * 1.8, 0.5);

    // Apply noise as an atmospheric shift (shifting based on high contrast areas)
    vec3 final_color = base_color;
    final_color.r = mix(final_color.r, 1.0, noise_val * 0.5);
    final_color.g = mix(final_color.g, 0.3, noise_val * 0.4);
    final_color.b = mix(final_color.b, 0.7, noise_val * 0.6);

    // Introduce a strong screen-space glow based on depth
    float bloom = smoothstep(0.4, 1.0, depth * 2.0);

    // Final color mixing and glow application
    final_color *= bloom;

    // Add dynamic color shift based on time
    final_color += vec3(sin(iTime * 1.5) * 0.15, cos(iTime * 2.0) * 0.1, sin(iTime * 2.5) * 0.05);

    fragColor = vec4(final_color,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
