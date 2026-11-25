#version 460 core
#include <flutter/runtime_effect.glsl>

// The engine supplies the filter input extent and texture. The remaining
// uniforms are local geometry/material parameters, never a CPU screenshot.
uniform vec2 u_inputSize;
uniform sampler2D u_scene;
uniform vec2 u_extent;
uniform float u_pixelRatio;
uniform vec2 u_inputOrigin;
uniform mat3 u_localToScreen;
uniform mat3 u_screenToLocal;
uniform vec4 u_radii;
uniform float u_refraction;
uniform float u_thickness;
uniform float u_pressure;
uniform float u_intensity;
uniform float u_blur;
uniform float u_lighting;
#ifdef IMPELLER_TARGET_OPENGLES
uniform float u_directBackdrop;
#endif
out vec4 fragColor;

vec4 roundedGeometry(vec2 p) {
  vec2 halfExtent = u_extent * 0.5;
  vec2 q = p - halfExtent;
  float radius = q.x > 0.0
    ? (q.y > 0.0 ? u_radii.z : u_radii.y)
    : (q.y > 0.0 ? u_radii.w : u_radii.x);
  radius = min(radius, min(halfExtent.x, halfExtent.y));
  vec2 d = abs(q) - halfExtent + radius;
  vec2 outside = max(d, 0.0);
  float lengthOutside = length(outside);
  vec2 normal = lengthOutside > 0.0001
    ? outside / lengthOutside
    : (d.x > d.y ? vec2(1.0, 0.0) : vec2(0.0, 1.0));
  // Curvature grows smoothly after the straight edge meets the corner arc.
  float curvature = smoothstep(0.0, 0.25,
      min(outside.x, outside.y) / max(radius, 1.0));
  curvature *= clamp(u_thickness / max(radius, 1.0), 0.0, 1.0);
  return vec4(lengthOutside + min(max(d.x, d.y), 0.0) - radius,
              normal * sign(q), curvature);
}

vec4 sampleScene(vec2 uv) {
  // Fragment and sampler coordinates already use the same texture space.
  vec2 halfTexel = vec2(0.5) / u_inputSize;
  vec4 source = texture(u_scene, clamp(uv, halfTexel, vec2(1.0) - halfTexel));
#ifdef IMPELLER_TARGET_OPENGLES
  // The identity copy normalizes premultiplied color before the optical pass.
  if (u_directBackdrop > 0.0) source.rgb = clamp(source.rgb, 0.0, source.a);
#endif
  return source;
}

vec4 opticalColor(vec2 uv, vec2 screen, vec2 p, vec4 geometry) {
  float distance = geometry.x;
  vec2 normal = geometry.yz;
  // A convex edge steepens toward the lip. Keep the center optically flat;
  // concentrating the displacement here reveals thickness without zooming
  // the whole backdrop or blurring away its detail.
  float edgeWidth = max(u_thickness * (1.0 - geometry.w * 0.2), 0.1);
  float rim = clamp(1.0 + distance / edgeWidth, 0.0, 1.0);
  bool hasDisplacement = (rim > 0.0 && u_refraction != 0.0) || u_pressure != 0.0;
  // The specular shoulder is below 8-bit precision beyond this narrow lip.
  // Interior pixels need neither its direction normalization nor exponentials.
  bool hasLighting = u_lighting > 0.0 && distance > -7.0;
  vec4 color;
  if (!hasDisplacement && u_blur <= 0.01 && !hasLighting) {
    vec4 s = sampleScene(uv);
    vec4 optical = vec4(clamp(s.rgb, 0.0, s.a), s.a);
    color = u_intensity >= 0.9999 ? optical : mix(s, optical, u_intensity);
  } else {
    vec2 sampleUV = uv;
    if (hasDisplacement) {
      float curve = rim * 0.4472136 / sqrt(1.0 - 0.8 * rim * rim);
      vec2 shift = -normal * u_refraction * curve * (1.0 + geometry.w * 0.15)
          * (1.0 + u_pressure * 0.18);
      shift += (p - u_extent * 0.5) * (u_pressure * 0.006);
      vec3 projected = u_localToScreen * vec3(p + shift * u_intensity, 1.0);
      sampleUV = uv + (projected.xy / projected.z - screen) * u_pixelRatio / u_inputSize;
    }
    vec4 scene = sampleScene(sampleUV);
    if (u_blur > 0.01) {
      vec2 step = vec2(u_blur * u_pixelRatio) / u_inputSize;
      scene *= 0.4;
      scene += sampleScene(sampleUV + vec2(step.x, 0.0)) * 0.15;
      scene += sampleScene(sampleUV - vec2(step.x, 0.0)) * 0.15;
      scene += sampleScene(sampleUV + vec2(0.0, step.y)) * 0.15;
      scene += sampleScene(sampleUV - vec2(0.0, step.y)) * 0.15;
    }
    // The system desktop is composited after Flutter renders this texture.
    // Preserve premultiplied transparency instead of replacing it with a tint.
    vec3 result = scene.rgb;
    float alpha = scene.a;
    if (hasLighting) {
      // A fixed upper-left key light gives every surface the same quiet rim.
      // Direction is local to the material; pointer/window positions play no part.
      const vec2 lightDirection = vec2(-0.70710678, -0.70710678);
      float facing = dot(normal, lightDirection);
      float positive = max(facing, 0.0);
      float squared = positive * positive;
      float glint = squared * squared;
      float edgeDistance = (distance + 0.85) / 0.7;
      float shoulderDistance = (distance + 2.6) / 1.25;
      float edge = exp(-edgeDistance * edgeDistance);
      float shoulder = exp(-shoulderDistance * shoulderDistance);
      // A soft key highlight and weaker opposite reflection define the edge.
      float opposite = max(-facing, 0.0);
      float kick = opposite * opposite * opposite;
      float highlight = (edge * (glint * 0.36 + kick * 0.08)
          + shoulder * glint * 0.08) * u_lighting;
      result = mix(result, vec3(1.0), highlight);
      alpha = mix(alpha, 1.0, highlight);
    }
    vec4 optical = vec4(clamp(result, 0.0, alpha), alpha);
    // Replace the sampled backdrop, rather than drawing a second copy over it.
    // A fading material must restore the original scene, including its alpha.
    color = u_intensity >= 0.9999 ? optical : mix(sampleScene(uv), optical, u_intensity);
  }
  return color;
}

void main() {
  // Keep a single exit when sampling textures for the Windows ANGLE compiler.
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / u_inputSize;
  if (u_intensity <= 0.0001) {
    fragColor = sampleScene(uv);
  } else {
    // The input pass crops the texture to the ancestor clips. Its origin is
    // pixel-aligned and can differ from the scrolled-out material origin.
    vec2 screen = fragCoord / u_pixelRatio + u_inputOrigin;
    vec3 local = u_screenToLocal * vec3(screen, 1.0);
    vec2 p = local.xy / local.z;
    // The engine can supply more than the material's bounds. Copy pixels
    // outside the shape so the filtered backdrop can replace its input.
    if (any(lessThan(p, vec2(0.0))) || any(greaterThan(p, u_extent))) {
      fragColor = sampleScene(uv);
    } else {
      vec4 geometry = roundedGeometry(p);
      fragColor = geometry.x > 0.0
          ? sampleScene(uv)
          : opticalColor(uv, screen, p, geometry);
    }
  }
}
