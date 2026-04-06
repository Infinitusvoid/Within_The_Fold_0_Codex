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
    float freq = 4.0 + iTime * 0.2;
    float x = uv.x * freq + t * 0.5;
    float y = uv.y * freq * 0.8 + t * 0.3;
    float val = sin(x * 3.0) + cos(y * 2.0);
    return uv * 1.8 + vec2(val * 0.15, val * 0.6);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Map coordinates to center and scale them
    uv = uv * 2.0 - 1.0;

    // Apply time-based translation and noise offset
    vec2 offset = uv * 30.0 + iTime * 2.5;

    // Introduce complex noise for distortion
    float noise_val = sin(offset.x * 8.0 + offset.y * 5.0 + iTime * 1.0);

    // Apply ripple distortion
    uv = ripple(uv);
    uv += offset * 0.03; // Subtle movement

    // Calculate coordinate-based values
    float v = sin(uv.x * 10.0 + iTime * 3.0);
    float u = cos(uv.y * 12.0 + iTime * 2.8);
    // Increase depth complexity
    float depth = pow(sin(uv.x * 7.0 + uv.y * 9.0 + iTime * 0.7), 4.0);

    // Base color calculation, emphasizing the depth effect
    vec3 base_color = vec3(v * 1.7, u * 1.3, 0.4);

    // Apply color shifts based on noise (Chromatic effect)
    vec3 final_color = base_color;
    final_color.r = mix(final_color.r, 1.0, noise_val * 0.4);
    final_color.g = mix(final_color.g, 0.5, noise_val * 0.3);
    final_color.b = mix(final_color.b, 0.8, noise_val * 0.6);

    // Introduce a strong radial bloom based on depth
    float bloom = smoothstep(0.5, 1.0, depth * 1.5);

    // Final color mixing and glow application
    final_color *= bloom;

    // Add a strong time-based color shift
    final_color += vec3(sin(iTime * 2.0) * 0.1, cos(iTime * 1.5) * 0.15, sin(iTime * 3.0) * 0.05);

    fragColor = vec4(final_color,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
