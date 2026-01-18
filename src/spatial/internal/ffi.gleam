//// Internal FFI functions for performance-critical operations.
////
//// This module provides optimized implementations of hot-path operations
//// using native code (Erlang/JavaScript) for better performance.

import vec/vec3.{type Vec3}

/// Fast AABB (Box-Box) intersection test.
///
/// Returns True if two axis-aligned bounding boxes intersect.
@external(erlang, "spatial_ffi", "box_intersects")
@external(javascript, "../../spatial_ffi.mjs", "box_intersects")
pub fn box_intersects(
  min_a: Vec3(Float),
  max_a: Vec3(Float),
  min_b: Vec3(Float),
  max_b: Vec3(Float),
) -> Bool

/// Fast box contains point test.
///
/// Returns True if a point is inside an axis-aligned bounding box.
@external(erlang, "spatial_ffi", "box_contains_point")
@external(javascript, "../../spatial_ffi.mjs", "box_contains_point")
pub fn box_contains_point(
  min: Vec3(Float),
  max: Vec3(Float),
  point: Vec3(Float),
) -> Bool

/// Fast sphere-sphere intersection test.
///
/// Returns True if two spheres intersect.
@external(erlang, "spatial_ffi", "sphere_intersects")
@external(javascript, "../../spatial_ffi.mjs", "sphere_intersects")
pub fn sphere_intersects(
  center_a: Vec3(Float),
  radius_a: Float,
  center_b: Vec3(Float),
  radius_b: Float,
) -> Bool

/// Fast distance squared calculation between two points.
///
/// Returns the squared distance (avoids expensive sqrt).
@external(erlang, "spatial_ffi", "distance_squared")
@external(javascript, "../../spatial_ffi.mjs", "distance_squared")
pub fn distance_squared(a: Vec3(Float), b: Vec3(Float)) -> Float

/// Fast point-to-point distance calculation.
@external(erlang, "spatial_ffi", "distance")
@external(javascript, "../../spatial_ffi.mjs", "distance")
pub fn distance(a: Vec3(Float), b: Vec3(Float)) -> Float

/// Compute bounding box from list of positions (min/max).
///
/// Returns #(min, max) tuple.
@external(erlang, "spatial_ffi", "compute_bounds")
@external(javascript, "../../spatial_ffi.mjs", "compute_bounds")
pub fn compute_bounds(
  positions: List(Vec3(Float)),
) -> #(Vec3(Float), Vec3(Float))

/// Merge two bounding boxes into one that contains both.
@external(erlang, "spatial_ffi", "merge_bounds")
@external(javascript, "../../spatial_ffi.mjs", "merge_bounds")
pub fn merge_bounds(
  min_a: Vec3(Float),
  max_a: Vec3(Float),
  min_b: Vec3(Float),
  max_b: Vec3(Float),
) -> #(Vec3(Float), Vec3(Float))
