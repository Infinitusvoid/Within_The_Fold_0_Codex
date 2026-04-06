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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 7.0 + iTime * 1.5), cos(uv.y * 8.5 - iTime * 1.3));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.6);
    float g = 0.2 + 0.6 * sin(t * 1.2 + iTime * 0.4);
    float b = 0.1 + 0.7 * cos(t * 1.6 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv * 3.0 + vec2(
        sin(uv.x * 5.5 + iTime * 1.0) * 0.25,
        cos(uv.y * 6.5 - iTime * 0.9) * 0.3
    );
}

float sdBox(vec2 p, vec2 b){ vec2 d=abs(p)-b; return length(max(d,0.0))+min(max(d.x,d.y),0.0); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // --- Geometric structure ---
    vec2 p = uv;
    // Time-dependent box dimensions
    vec2 b = vec2(0.2 + 0.09*sin(iTime * 0.5), 0.2 + 0.07*cos(1.4*iTime));
    float d = sdBox(p, b);
    float fill = smoothstep(0.01,0.0,d);
    float glow = 0.04/(abs(d)+0.04);

    // --- Wave distortion ---
    // Initial wave structure
    vec2 warped_uv = waveB(uv);

    // Apply rotational flow
    float angle = iTime * 0.3 + uv.x * 7.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Apply secondary wave structure
    warped_uv = waveA(warped_uv);

    // Apply spatial flow
    float flow_x = iTime * 0.6 + uv.x * 4.5;
    float flow_y = iTime * 0.4 + uv.y * 5.0;

    // Use flow for positional shifting
    warped_uv.x += sin(flow_x * 0.5) * 0.1;
    warped_uv.y += cos(flow_y * 0.5) * 0.1;

    // --- Coloring and Interaction ---

    // Generate dynamic value based on complex interaction
    float t = sin(warped_uv.x * 5.0 + iTime * 2.0) + cos(warped_uv.y * 4.0 + iTime * 1.0);

    // Color based on the primary wave interaction
    vec3 col1 = palette(t * 1.8);

    // Introduce depth modulation using the SDF result and flow
    float phase_shift = sin(warped_uv.x * 7.0 + iTime * 4.0) * 0.6;

    // Blend colors based on phase and flow interaction
    vec3 col2 = palette(phase_shift * 1.2 + warped_uv.y * 0.4);
    vec3 final_color = mix(col1, col2, phase_shift * 0.7 + flow_x * 0.15);

    // Introduce geometric glow/fill modulation
    float color_factor = 0.1 + fill * 1.5 + 0.7*glow;
    final_color *= color_factor;

    // Fractal noise based on high frequency interaction
    float noise_factor = sin(warped_uv.x * 20.0 + iTime * 2.5) * cos(warped_uv.y * 11.0 - iTime * 1.0);

    // Introduce chromatic aberration effect based on flow
    float aberration = abs(uv.x - 0.5) * 3.0;
    final_color.r += aberration * 0.15;
    final_color.b -= aberration * 0.15;

    // Apply noise and contrast boost
    final_color = mix(final_color, vec3(0.03, 0.1, 0.01), noise_factor * 0.7);

    // Final intensity adjustment
    final_color *= 1.8;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
