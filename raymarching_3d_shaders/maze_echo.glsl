#version 330 core
in vec2 TexCoord;
in vec3 WorldPos;
in vec3 LocalPos;

out vec4 FragColor;

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

uniform vec3 uColor;
uniform float time;
uniform float iTime;
uniform vec3 uCamPos;
uniform vec3 uCubePos;
uniform vec3 iPlayerPos;
uniform vec3 iResolution;
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

mat2 rot2(float a)
{
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float mapScene(vec3 p)
{
    vec3 cubeCenter = model[3].xyz + vec3(0.5);
    vec3 q = p - cubeCenter;

    vec3 cameraForward = normalize(vec3(-view[0][2], -view[1][2], -view[2][2]));
    q.xz *= rot2(iTime * 0.35 + dot(cameraForward.xz, vec2(1.0, -1.0)));
    q.yz *= rot2(iTime * 0.55 + uCubePos.y * 0.7);

    float torus = sdTorus(q, vec2(0.22 + 0.04 * sin(iTime + uCubePos.x), 0.06));
    float prism = sdBox(q, vec3(0.18, 0.34, 0.18));
    float cage = sdBox(q, vec3(0.40)) - 0.02;

    return min(min(torus, prism), max(cage, -sdBox(q, vec3(0.32))));
}

vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        mapScene(p + e.xyy) - mapScene(p - e.xyy),
        mapScene(p + e.yxy) - mapScene(p - e.yxy),
        mapScene(p + e.yyx) - mapScene(p - e.yyx)
    ));
}

void main()
{
    vec3 ro = uCamPos;
    vec3 rd = normalize(WorldPos - ro);

    float t = 0.0;
    bool hit = false;
    for (int i = 0; i < 90; ++i)
    {
        vec3 p = ro + rd * t;
        float d = mapScene(p);
        if (d < 0.001)
        {
            hit = true;
            break;
        }

        t += d * 0.9;
        if (t > 10.0)
        {
            break;
        }
    }

    vec3 color = vec3(0.01, 0.015, 0.03);

    if (hit)
    {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);
        vec3 lightDir = normalize(iPlayerPos - p + vec3(0.0, 1.2, 0.2));
        float diffuse = max(dot(n, lightDir), 0.0);
        float fresnel = pow(1.0 - max(dot(-rd, n), 0.0), 4.0);

        vec3 uvw = p - (uCubePos + 0.5);
        vec3 waveA = texture(iChannel0, uvw.xz * 1.5 + iTime * 0.05).rgb;
        vec3 waveB = texture(iChannel1, uvw.yx * 1.1 - iTime * 0.03).rgb;

        vec3 tint = mix(waveA, waveB, 0.5 + 0.5 * sin(iTime + uvw.y * 8.0));
        tint *= mix(vec3(0.2, 0.5, 1.0), max(uColor, vec3(0.18)), 0.4);

        float pulse = 0.45 + 0.55 * sin(iTime * 1.7 + length(uvw) * 18.0);
        color = tint * (0.25 + diffuse * 0.9);
        color += fresnel * mix(vec3(0.4, 0.7, 1.0), tint, pulse);
    }
    else
    {
        vec2 uv = gl_FragCoord.xy / max(iResolution.xy, vec2(1.0));
        float beam = abs(sin((uv.x + uv.y) * 12.0 + iTime * 0.8));
        color += vec3(0.03, 0.08, 0.14) * beam * clamp(projection[1][1] * 0.2, 0.0, 1.0);
    }

    FragColor = vec4(sqrt(max(color, vec3(0.0))), 1.0);
}
