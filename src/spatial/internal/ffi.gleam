//// Internal FFI functions for performance-critical operations.
////
//// This module provides optimized implementations of hot-path operations.
//// Erlang target uses native code for better performance.
//// JavaScript target uses pure Gleam implementations that compile efficiently.

import vec/vec3.{type Vec3}

@target(javascript)
import gleam/float

@target(javascript)
import gleam/list

@target(javascript)
import gleam/result

@target(erlang)
/// Fast AABB (Box-Box) intersection test.
///
/// Returns True if two axis-aligned bounding boxes intersect.
@external(erlang, "spatial_ffi", "box_intersects")
pub fn box_intersects(
  min_a: Vec3(Float),
  max_a: Vec3(Float),
  min_b: Vec3(Float),
  max_b: Vec3(Float),
) -> Bool

@target(javascript)
pub fn box_intersects(
  min_a: Vec3(Float),
  max_a: Vec3(Float),
  min_b: Vec3(Float),
  max_b: Vec3(Float),
) -> Bool {
  min_a.x <=. max_b.x
  && max_a.x >=. min_b.x
  && min_a.y <=. max_b.y
  && max_a.y >=. min_b.y
  && min_a.z <=. max_b.z
  && max_a.z >=. min_b.z
}

@target(erlang)
/// Fast box contains point test.
///
/// Returns True if a point is inside an axis-aligned bounding box.
@external(erlang, "spatial_ffi", "box_contains_point")
pub fn box_contains_point(
  min: Vec3(Float),
  max: Vec3(Float),
  point: Vec3(Float),
) -> Bool

@target(javascript)
pub fn box_contains_point(
  min: Vec3(Float),
  max: Vec3(Float),
  point: Vec3(Float),
) -> Bool {
  point.x >=. min.x
  && point.x <=. max.x
  && point.y >=. min.y
  && point.y <=. max.y
  && point.z >=. min.z
  && point.z <=. max.z
}

@target(erlang)
/// Fast sphere-sphere intersection test.
///
/// Returns True if two spheres intersect.
@external(erlang, "spatial_ffi", "sphere_intersects")
pub fn sphere_intersects(
  center_a: Vec3(Float),
  radius_a: Float,
  center_b: Vec3(Float),
  radius_b: Float,
) -> Bool

@target(javascript)
pub fn sphere_intersects(
  center_a: Vec3(Float),
  radius_a: Float,
  center_b: Vec3(Float),
  radius_b: Float,
) -> Bool {
  let dx = center_a.x -. center_b.x
  let dy = center_a.y -. center_b.y
  let dz = center_a.z -. center_b.z
  let dist_sq = dx *. dx +. dy *. dy +. dz *. dz
  let radius_sum = radius_a +. radius_b
  dist_sq <=. radius_sum *. radius_sum
}

@target(erlang)
/// Fast distance squared calculation between two points.
///
/// Returns the squared distance (avoids expensive sqrt).
@external(erlang, "spatial_ffi", "distance_squared")
pub fn distance_squared(a: Vec3(Float), b: Vec3(Float)) -> Float

@target(javascript)
pub fn distance_squared(a: Vec3(Float), b: Vec3(Float)) -> Float {
  let dx = a.x -. b.x
  let dy = a.y -. b.y
  let dz = a.z -. b.z
  dx *. dx +. dy *. dy +. dz *. dz
}

@target(erlang)
/// Fast point-to-point distance calculation.
@external(erlang, "spatial_ffi", "distance")
pub fn distance(a: Vec3(Float), b: Vec3(Float)) -> Float

@target(javascript)
pub fn distance(a: Vec3(Float), b: Vec3(Float)) -> Float {
  let dx = a.x -. b.x
  let dy = a.y -. b.y
  let dz = a.z -. b.z
  float.square_root(dx *. dx +. dy *. dy +. dz *. dz)
  |> result.unwrap(0.0)
}

@target(erlang)
/// Compute bounding box from list of positions (min/max).
///
/// Returns #(min, max) tuple.
@external(erlang, "spatial_ffi", "compute_bounds")
pub fn compute_bounds(
  positions: List(Vec3(Float)),
) -> #(Vec3(Float), Vec3(Float))

@target(javascript)
pub fn compute_bounds(
  positions: List(Vec3(Float)),
) -> #(Vec3(Float), Vec3(Float)) {
  let init_min = vec3.Vec3(1.0e10, 1.0e10, 1.0e10)
  let init_max = vec3.Vec3(-1.0e10, -1.0e10, -1.0e10)

  list.fold(positions, #(init_min, init_max), fn(acc, pos) {
    let #(current_min, current_max) = acc
    #(
      vec3.Vec3(
        float.min(current_min.x, pos.x),
        float.min(current_min.y, pos.y),
        float.min(current_min.z, pos.z),
      ),
      vec3.Vec3(
        float.max(current_max.x, pos.x),
        float.max(current_max.y, pos.y),
        float.max(current_max.z, pos.z),
      ),
    )
  })
}

@target(erlang)
/// Merge two bounding boxes into one that contains both.
@external(erlang, "spatial_ffi", "merge_bounds")
pub fn merge_bounds(
  min_a: Vec3(Float),
  max_a: Vec3(Float),
  min_b: Vec3(Float),
  max_b: Vec3(Float),
) -> #(Vec3(Float), Vec3(Float))

@target(javascript)
pub fn merge_bounds(
  min_a: Vec3(Float),
  max_a: Vec3(Float),
  min_b: Vec3(Float),
  max_b: Vec3(Float),
) -> #(Vec3(Float), Vec3(Float)) {
  #(
    vec3.Vec3(
      float.min(min_a.x, min_b.x),
      float.min(min_a.y, min_b.y),
      float.min(min_a.z, min_b.z),
    ),
    vec3.Vec3(
      float.max(max_a.x, max_b.x),
      float.max(max_a.y, max_b.y),
      float.max(max_a.z, max_b.z),
    ),
  )
}
