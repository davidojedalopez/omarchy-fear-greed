#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
  float time;
  float strength;
  float heightScale;
} ubuf;

float randomValue(vec2 point)
{
  return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

float valueNoise(vec2 point)
{
  vec2 cell = floor(point);
  vec2 fraction = fract(point);
  fraction = fraction * fraction * (3.0 - 2.0 * fraction);

  float bottomLeft = randomValue(cell);
  float bottomRight = randomValue(cell + vec2(1.0, 0.0));
  float topLeft = randomValue(cell + vec2(0.0, 1.0));
  float topRight = randomValue(cell + vec2(1.0, 1.0));
  return mix(mix(bottomLeft, bottomRight, fraction.x),
             mix(topLeft, topRight, fraction.x), fraction.y);
}

float turbulence(vec2 point)
{
  float result = 0.0;
  float amplitude = 0.5;
  for (int octave = 0; octave < 4; ++octave) {
    result += amplitude * valueNoise(point);
    point = point * 2.03 + vec2(19.1, 7.7);
    amplitude *= 0.5;
  }
  return result / 0.9375;
}

void main()
{
  vec2 uv = qt_TexCoord0;
  float heightFromBase = 1.0 - uv.y;

  // Advect the noise upward and bend it more strongly near the tips. Every
  // visible flame is rebuilt from this moving field; no image is sampled.
  float curl = turbulence(vec2(uv.x * 5.2 + ubuf.time * 0.38,
                               heightFromBase * 3.8 - ubuf.time * 1.25)) - 0.5;
  float quickCurl = turbulence(vec2(uv.x * 13.0 - ubuf.time * 0.74,
                                    heightFromBase * 8.0 - ubuf.time * 2.8)) - 0.5;
  float bentX = uv.x + (curl * 0.115 + quickCurl * 0.025)
                       * pow(heightFromBase, 0.72) * ubuf.strength;

  float broad = turbulence(vec2(bentX * 4.2 + ubuf.time * 0.31,
                                ubuf.time * 0.62));
  float tongues = turbulence(vec2(bentX * 10.5 - ubuf.time * 0.52,
                                  ubuf.time * 1.18));
  float crown = 0.20 + 0.48 * pow(broad, 1.55)
              + 0.20 * (tongues - 0.46);
  crown = clamp(crown * ubuf.heightScale, 0.14, 0.90);

  float boundaryNoise = turbulence(vec2(bentX * 14.0 + ubuf.time * 0.86,
                                        heightFromBase * 5.5 - ubuf.time * 2.35));
  float boundary = crown + (boundaryNoise - 0.5)
                         * (0.07 + 0.13 * heightFromBase) * ubuf.strength;
  float edge = boundary - heightFromBase;
  float flameAlpha = smoothstep(-0.025, 0.035, edge);

  // Break the crown into narrow, changing tips while keeping the ground fire
  // continuous. This prevents a persistent silhouette from forming.
  float tipBreakup = turbulence(vec2(bentX * 21.0 - ubuf.time * 1.35,
                                     heightFromBase * 9.0 - ubuf.time * 3.4));
  float breakupWeight = smoothstep(0.30, 0.76, heightFromBase);
  flameAlpha *= mix(1.0, smoothstep(0.29, 0.63, tipBreakup), breakupWeight);

  float innerNoise = turbulence(vec2(bentX * 16.0 + ubuf.time * 1.7,
                                     heightFromBase * 8.5 - ubuf.time * 3.1));
  float heat = clamp((boundary - heightFromBase) * 2.5
                     + (1.0 - heightFromBase) * 0.92
                     + (innerNoise - 0.5) * 0.34, 0.0, 1.0);

  vec3 deepRed = vec3(0.83, 0.035, 0.0);
  vec3 orange = vec3(1.0, 0.20, 0.0);
  vec3 yellow = vec3(1.0, 0.78, 0.04);
  vec3 whiteHot = vec3(1.0, 0.96, 0.58);
  vec3 flameColor = mix(deepRed, orange, smoothstep(0.0, 0.38, heat));
  flameColor = mix(flameColor, yellow, smoothstep(0.30, 0.72, heat));
  flameColor = mix(flameColor, whiteHot, smoothstep(0.72, 1.0, heat));

  float baseContinuity = 1.0 - smoothstep(0.0, 0.055, heightFromBase);
  flameAlpha = max(flameAlpha, baseContinuity * 0.92);
  flameAlpha *= 0.82 + innerNoise * 0.18;
  flameAlpha *= ubuf.qt_Opacity;
  fragColor = vec4(flameColor * flameAlpha, flameAlpha);
}
