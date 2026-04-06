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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.34,0.68)+t)); }

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 1.5), cos(uv.y * 8.0 - iTime * 1.1));
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
    return uv * 3.5 + vec2(
        sin(uv.x * 7.0 + iTime * 1.0) * 0.15,
        cos(uv.y * 5.5 - iTime * 0.9) * 0.1
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // 1. Geometric foundation from Shader A
    float r = length(uv), a = atan(uv.y,uv.x);
    float petals = cos(6.0*a + 1.5*sin(iTime + 6.0*r));
    float d = r - (0.28 + 0.08*petals);
    float fill = smoothstep(0.02,0.0,d);
    float line = smoothstep(0.03,0.0,abs(d));

    // 2. Wave distortion and rotation from Shader B
    vec2 warped_uv = waveB(uv);

    // Apply rotational flow
    float angle = iTime * 0.3 + uv.x * 5.5;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Apply secondary wave structure
    warped_uv = waveA(warped_uv);

    // Apply spatial flow
    float flow_x = iTime * 0.6 + uv.x * 2.5;
    float flow_y = iTime * 0.4 + uv.y * 3.5;

    // Use flow for positional shifting
    warped_uv.x += sin(flow_x * 1.2) * 0.1;
    warped_uv.y += cos(flow_y * 0.9) * 0.1;

    // 3. Dynamic value generation and color mixing (Hybrid approach)
    // Use the radial field (d) to influence the color time input
    float t_mod = sin(d * 3.0 + iTime * 1.5);

    // Use the wave results for secondary color modulation
    float wave_phase = sin(warped_uv.x * 5.0 + iTime * 3.0) * 0.5;

    // Calculate primary color using the dynamic palette
    vec3 col1 = palette(t_mod * 1.5);

    // Calculate secondary color based on wave complexity
    vec3 col2 = palette(wave_phase * 2.0 + warped_uv.y * 0.5);

    // Blend colors based on geometric fill and wave phase
    vec3 final_color = mix(col1, col2, fill * 0.5 + wave_phase * 0.5);

    // Introduce high-frequency noise and chromatic aberration
    float noise_factor = sin(warped_uv.x * 20.0 + iTime * 3.5) * cos(warped_uv.y * 12.0 - iTime * 1.0);

    // Chromatic aberration based on initial UV position
    float aberration = abs(uv.x - 0.5) * 5.0;
    final_color.r += aberration * 0.1;
    final_color.b -= aberration * 0.1;

    // Final intensity adjustment
    float intensity = 1.0 + 0.5 * sin(iTime * 0.5);
    final_color *= intensity;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
