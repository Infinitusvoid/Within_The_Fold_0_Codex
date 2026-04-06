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

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Polar coordinates
    float a = atan(uv.y, uv.x);
    float r = length(uv);

    // Time factors for dynamism
    float time_a = iTime * 0.9;
    float time_r = iTime * 5.0;

    // Complex radial wave modulation based on fractal noise influences
    float radius_warp = sin(r * 25.0 + time_r * 1.2) * 0.12;
    float radial_noise = sin(r * 80.0 + time_r * 3.5) * 0.08;

    // Rotational flow influence with slight offset added by noise
    float flow_effect = sin(a * 55.0 + time_a * 6.0) * 0.6 + 0.4;

    // Inverse radial influence for pulsing effects
    float radial_pulse = cos(r * 18.0 + time_r * 1.8) * 0.1 + 0.9;

    // Introduce angular shift based on flow complexity and noise interaction
    float angle_shift = flow_effect * 0.8 + radial_noise * 0.4;

    // Calculate final modulated coordinates
    float new_r = r * 1.5 + radius_warp;
    float new_a = a + angle_shift;

    // Introduce complex winding/twist via radial interaction
    float twist = sin(new_r * 12.0 + time_r * 2.5);
    new_a += twist * 0.7;

    // Exponential radial scaling for banding and complexity
    float radius_band = mod(new_r * 15.0 + time_r * 4.0, 35.0) * 0.07;

    // Transition to color using strongly modulated polar coordinates, introducing chromatic separation
    vec3 base_color = vec3(
        0.6 + sin(new_a * 15.0 + time_a * 2.0),
        0.5 + cos(new_r * 40.0 + time_r * 3.0),
        0.7 + sin(new_a * 12.0)
    );

    // Apply saturation/contrast based on radial influence
    vec3 final_color = base_color * (0.8 + cos(new_r * 7.0)) + radius_band * 0.5;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
