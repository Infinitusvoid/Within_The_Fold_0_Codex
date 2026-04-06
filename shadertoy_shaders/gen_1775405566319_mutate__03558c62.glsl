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

    // --- Flow setup ---

    // Time based flow factors
    float flow_speed = 4.0;
    float flow_density = 20.0;

    // Polar coordinates
    float a = atan(uv.y, uv.x);
    float r = length(uv);

    // Dynamic flow based on angle and time
    float flow_angle = a * flow_speed * 1.5 + iTime * 2.2;
    float flow_radius = r * 45.0 + iTime * 9.0;

    // Radial pulsation (more aggressive)
    float pulse = sin(flow_radius * 15.0) * 0.4;

    // Angular oscillation
    float rotation = a * 10.0 + iTime * 3.5;

    // --- Distortion calculation ---

    // Primary distortion based on radial flow and rotation
    float distortion = sin(flow_radius * 12.0) * 0.4 + cos(rotation * 10.0) * 0.2;

    // Secondary distortion based on angular position and density
    float warp = sin(flow_angle * 10.0) * 0.15 + flow_density * 0.01;

    // Introduce flow-dependent warping on the radial axis, scaled by time
    float radial_shift = flow_radius * 0.03 * sin(iTime * 0.8);

    // Add a secondary distortion based on the angle
    float angular_warp = cos(flow_angle * 5.0) * 0.1;

    // --- Color calculation ---

    // Modulation driven by radial pulse (driving saturation change)
    float color_mod_r = pow(sin(flow_radius * 10.0), 3.0) * 0.5 + 0.5;

    // Modulation driven by angular flow (driving hue change)
    float color_mod_a = sin(flow_angle * 5.0) * 0.5 + 0.5;

    // Depth based color component, influenced by radial shift and angular warp
    float depth_effect = 1.0 - smoothstep(0.0, 0.5, r * 20.0 + radial_shift * 0.5 + angular_warp);

    // Final color calculation using flow and distortion
    vec3 final_color = vec3(
        0.1 + color_mod_a * 0.5, 
        0.3 + color_mod_r * 0.5, 
        0.5 + depth_effect * 0.9 + sin(r * 7.0 + iTime * 4.0) * 0.15
    );

    // Apply distortion multiplicatively, using warp and angular warp to control contrast and hue variance
    final_color *= (1.0 + distortion * 2.0) * (1.0 + warp * 0.7) * (1.0 + angular_warp * 0.5);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
