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

    // Calculate polar coordinates
    float a = atan(uv.y, uv.x);
    float r = length(uv);

    // Introduce motion and angular field
    float t = iTime * 1.2;
    float angle_vel = 0.6;
    float radius_vel = 0.2;

    // Spin the coordinates based on time
    float phase_a = a + t * angle_vel;
    float phase_r = r * 6.0 + t * radius_vel * 0.5;

    // Create complex radial flow
    // Flow based on angular movement scaled by radius
    float flow_a = sin(phase_a * 6.0) * r * 1.5;
    // Flow based on radial movement scaled by angle and a depth factor
    float flow_r = cos(phase_r) * 2.0 * (1.0 + abs(sin(a * 5.0)));

    // Define base intensity modulation using distance and phase
    float intensity = sin(phase_r * 5.0 + t * 2.5);

    // Modulate the color based on the calculated flow fields
    // Mixing flow_a and flow_r creates swirling contrast
    float color_mix = flow_a * flow_r * 2.5;

    // Define a secondary modulation based on the angular position
    float angle_warp = sin(phase_a * 3.0);

    // Color calculation using intensity and flow
    vec3 col = vec3(intensity * 0.5 + 0.1, intensity * 0.7 + 0.3, intensity * 1.3 + 0.5);

    // Apply flow modulation to the color channels differently
    col.r += color_mix * 0.5;
    col.g += color_mix * 0.8;
    col.b += color_mix * 1.0;

    // Add a depth effect based on radial distance, introducing contrast
    float depth = exp(-(r * r) * 0.15);

    // Introduce a subtle chromatic shift based on the angular warp
    col += angle_warp * 0.15;

    col *= depth;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
