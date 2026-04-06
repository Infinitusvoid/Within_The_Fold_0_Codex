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

vec3 pal(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.08,0.35,0.67)+t));
}

float sdBox(vec2 p, vec2 b){
    vec2 d=abs(p)-b;
    return length(max(d,0.0))+min(max(d.x,d.y),0.0);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.8;
    float w1 = sin(uv.x * 15.0 + t * 1.5) * 0.3;
    float w2 = cos(uv.y * 10.0 + t * 1.2) * 0.3;
    float w3 = sin(length(uv) * 5.0 + t * 2.0) * 0.2;
    return vec2(w1, w2 + w3);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // --- Dynamic Flow and Rotation ---
    float flow_speed = 4.0 + sin(iTime * 0.4) * 1.2;
    uv *= flow_speed;

    uv.x += iTime * 0.5;
    uv.y += iTime * 0.3;

    float angle1 = uv.x * 7.0 + iTime * 0.3;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv *= rotationMatrix;

    float angle2 = iTime * 1.1;
    uv = rotate(uv, angle2);

    // --- Wave Distortion ---
    uv = wave(uv);

    // --- Fractal Layering and Distance Field ---
    // Altering the box offset and scale
    vec2 box_offset = vec2(0.1 + 0.1*sin(iTime * 1.5), 0.1 + 0.1*cos(iTime * 2.0));
    float d = sdBox(uv * 2.5, box_offset * 1.5);

    // Polar coordinates
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // Ring modulation based on distance
    float ring = smoothstep(0.15, 0.0, abs(sin(15.0*r - 4.0*iTime)));

    // Angular/radial modulation
    float z = 1.0/(r * 0.5 + 0.2);
    float f1 = sin(8.0*a + 4.0*z - 1.5*iTime);
    float f2 = cos(12.0*a - 3.5*z + 1.8*iTime);
    float bands = smoothstep(0.2, 0.0, abs(f1 * f2));

    // Color calculation
    vec3 col = pal(0.05*iTime + 0.1*z + 0.2);
    col *= (0.3 + bands + 0.5*ring);
    col *= exp(-1.2*r);

    // Final Intensity and Chromatic Shift
    float intensity = 0.7 - 0.3 * sin(r * 6.0 + iTime * 1.5);
    col *= intensity;

    float final_angle = atan(uv.y, uv.x);
    col.r = sin(final_angle * 8.0 + iTime * 1.2) * 0.5 + 0.5;
    col.g = cos(final_angle * 7.0 + iTime * 0.9) * 0.5 + 0.5;

    // Detail Layer
    float detail = sin(uv.x * 40.0 + iTime * 3.0) * 0.15;
    col += detail * 0.6;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
