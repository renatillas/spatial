//// Collision volumes for spatial queries and collision detection.
////
//// Provides Box, Sphere, Capsule, and Cylinder colliders with intersection tests
//// and rotation-aware collision volume computation.

import gleam/float
import gleam/list
import quaternion
import vec/vec3.{type Vec3}
import vec/vec3f

/// Collision volume for spatial queries and collision detection.
@internal
pub type InternalCollider {
  /// Axis-aligned bounding box
  Box(min: Vec3(Float), max: Vec3(Float))
  /// Bounding sphere
  Sphere(center: Vec3(Float), radius: Float)
  /// Capsule (line segment with radius)
  Capsule(start: Vec3(Float), end: Vec3(Float), radius: Float)
  /// Cylinder (aligned along local Y axis)
  Cylinder(center: Vec3(Float), radius: Float, height: Float)
}

pub type Collider =
  InternalCollider

/// Create a box collider from min and max points.
///
/// ## Example
/// ```gleam
/// let bounds = collider.box(
///   min: vec3.Vec3(-1.0, -1.0, -1.0),
///   max: vec3.Vec3(1.0, 1.0, 1.0),
/// )
/// ```
pub fn box(min min: Vec3(Float), max max: Vec3(Float)) -> Collider {
  Box(min: min, max: max)
}

/// Create a box collider from center and half-extents.
///
/// ## Example
/// ```gleam
/// let bounds = collider.box_from_center(
///   center: vec3.Vec3(0.0, 5.0, 0.0),
///   half_extents: vec3.Vec3(2.0, 1.0, 2.0),
/// )
/// ```
pub fn box_from_center(
  center center: Vec3(Float),
  half_extents half_extents: Vec3(Float),
) -> Collider {
  Box(
    min: vec3f.subtract(center, half_extents),
    max: vec3f.add(center, half_extents),
  )
}

/// Create a sphere collider from center and radius.
///
/// ## Example
/// ```gleam
/// let bounds = collider.sphere(
///   center: vec3.Vec3(0.0, 0.0, 0.0),
///   radius: 2.5,
/// )
/// ```
pub fn sphere(center center: Vec3(Float), radius radius: Float) -> Collider {
  Sphere(center: center, radius: radius)
}

/// Create a capsule collider from start point, end point, and radius.
///
/// A capsule is a line segment with a radius - perfect for character controllers.
///
/// ## Example
/// ```gleam
/// let character = collider.capsule(
///   start: vec3.Vec3(0.0, 0.0, 0.0),
///   end: vec3.Vec3(0.0, 2.0, 0.0),
///   radius: 0.5,
/// )
/// ```
pub fn capsule(
  start start: Vec3(Float),
  end end: Vec3(Float),
  radius radius: Float,
) -> Collider {
  Capsule(start: start, end: end, radius: radius)
}

/// Create a cylinder collider from center, radius, and height.
///
/// The cylinder is aligned along the Y axis in local space.
///
/// ## Example
/// ```gleam
/// let pillar = collider.cylinder(
///   center: vec3.Vec3(0.0, 5.0, 0.0),
///   radius: 1.0,
///   height: 10.0,
/// )
/// ```
pub fn cylinder(
  center center: Vec3(Float),
  radius radius: Float,
  height height: Float,
) -> Collider {
  Cylinder(center: center, radius: radius, height: height)
}

/// Check if a point is inside a collider.
///
/// Works for Box, Sphere, Capsule, and Cylinder colliders.
///
/// **Time Complexity**: O(1) - constant time geometric calculation.
pub fn contains_point(collider: Collider, point: Vec3(Float)) -> Bool {
  case collider {
    Box(min, max) ->
      point.x >=. min.x
      && point.x <=. max.x
      && point.y >=. min.y
      && point.y <=. max.y
      && point.z >=. min.z
      && point.z <=. max.z

    Sphere(center, radius) -> vec3f.distance(center, point) <=. radius

    Capsule(start, end, radius) -> {
      let distance = point_to_line_segment_distance(point, start, end)
      distance <=. radius
    }

    Cylinder(center, radius, height) -> {
      let half_height = height /. 2.0
      let dx = point.x -. center.x
      let dz = point.z -. center.z
      let radial_dist_sq = dx *. dx +. dz *. dz
      let y_in_range =
        point.y >=. center.y -. half_height
        && point.y <=. center.y +. half_height
      radial_dist_sq <=. radius *. radius && y_in_range
    }
  }
}

/// Check if two colliders intersect.
///
/// Handles all collider type combinations.
///
/// **Time Complexity**: O(1) - constant time geometric calculation.
pub fn intersects(a: Collider, b: Collider) -> Bool {
  case a, b {
    // Box-Box intersection (AABB test)
    Box(min_a, max_a), Box(min_b, max_b) ->
      min_a.x <=. max_b.x
      && max_a.x >=. min_b.x
      && min_a.y <=. max_b.y
      && max_a.y >=. min_b.y
      && min_a.z <=. max_b.z
      && max_a.z >=. min_b.z

    // Sphere-Sphere intersection
    Sphere(center_a, radius_a), Sphere(center_b, radius_b) -> {
      let distance = vec3f.distance(center_a, center_b)
      distance <=. { radius_a +. radius_b }
    }

    // Box-Sphere intersection (order doesn't matter)
    Box(min, max), Sphere(center, radius)
    | Sphere(center, radius), Box(min, max)
    -> {
      let closest_x = float.clamp(center.x, min.x, max.x)
      let closest_y = float.clamp(center.y, min.y, max.y)
      let closest_z = float.clamp(center.z, min.z, max.z)
      let closest = vec3.Vec3(closest_x, closest_y, closest_z)
      vec3f.distance(center, closest) <=. radius
    }

    // Capsule-Capsule intersection
    Capsule(start_a, end_a, radius_a), Capsule(start_b, end_b, radius_b) -> {
      let distance =
        line_segment_to_line_segment_distance(start_a, end_a, start_b, end_b)
      distance <=. { radius_a +. radius_b }
    }

    // Sphere-Capsule intersection
    Sphere(center, sphere_radius), Capsule(start, end, cap_radius)
    | Capsule(start, end, cap_radius), Sphere(center, sphere_radius)
    -> {
      let distance = point_to_line_segment_distance(center, start, end)
      distance <=. { sphere_radius +. cap_radius }
    }

    // Box-Capsule intersection
    Box(min, max), Capsule(start, end, radius)
    | Capsule(start, end, radius), Box(min, max)
    -> {
      // Check if line segment intersects expanded box
      let expanded_min =
        vec3.Vec3(min.x -. radius, min.y -. radius, min.z -. radius)
      let expanded_max =
        vec3.Vec3(max.x +. radius, max.y +. radius, max.z +. radius)
      line_segment_intersects_box(start, end, expanded_min, expanded_max)
    }

    // Cylinder-Sphere intersection
    Cylinder(cyl_center, cyl_radius, height),
      Sphere(sphere_center, sphere_radius)
    | Sphere(sphere_center, sphere_radius),
      Cylinder(cyl_center, cyl_radius, height)
    -> {
      let half_height = height /. 2.0
      let dx = sphere_center.x -. cyl_center.x
      let dz = sphere_center.z -. cyl_center.z
      let radial_dist_sq = dx *. dx +. dz *. dz
      let radial_dist = case float.square_root(radial_dist_sq) {
        Ok(d) -> d
        Error(_) -> 0.0
      }
      let y_clamped =
        float.clamp(
          sphere_center.y,
          cyl_center.y -. half_height,
          cyl_center.y +. half_height,
        )
      let closest_y_dist = float.absolute_value(sphere_center.y -. y_clamped)

      radial_dist <=. { cyl_radius +. sphere_radius }
      && closest_y_dist <=. sphere_radius
    }

    // Box-Cylinder intersection (approximate using sphere test)
    Box(min, max), Cylinder(center, radius, height)
    | Cylinder(center, radius, height), Box(min, max)
    -> {
      // Approximate: test cylinder's bounding box
      let half_height = height /. 2.0
      let cyl_min =
        vec3.Vec3(
          center.x -. radius,
          center.y -. half_height,
          center.z -. radius,
        )
      let cyl_max =
        vec3.Vec3(
          center.x +. radius,
          center.y +. half_height,
          center.z +. radius,
        )

      cyl_min.x <=. max.x
      && cyl_max.x >=. min.x
      && cyl_min.y <=. max.y
      && cyl_max.y >=. min.y
      && cyl_min.z <=. max.z
      && cyl_max.z >=. min.z
    }

    // Capsule-Cylinder intersection (conservative test)
    Capsule(start, end, cap_radius), Cylinder(cyl_center, cyl_radius, height)
    | Cylinder(cyl_center, cyl_radius, height), Capsule(start, end, cap_radius)
    -> {
      let half_height = height /. 2.0
      let min_dist = point_to_line_segment_distance(cyl_center, start, end)
      let y_in_range =
        {
          start.y <=. cyl_center.y +. half_height
          && start.y >=. cyl_center.y -. half_height
        }
        || {
          end.y <=. cyl_center.y +. half_height
          && end.y >=. cyl_center.y -. half_height
        }

      min_dist <=. { cyl_radius +. cap_radius } && y_in_range
    }

    // Cylinder-Cylinder intersection (approximate)
    Cylinder(center_a, radius_a, height_a),
      Cylinder(center_b, radius_b, height_b)
    -> {
      let half_height_a = height_a /. 2.0
      let half_height_b = height_b /. 2.0
      let dx = center_a.x -. center_b.x
      let dz = center_a.z -. center_b.z
      let radial_dist_sq = dx *. dx +. dz *. dz
      let radial_dist = case float.square_root(radial_dist_sq) {
        Ok(d) -> d
        Error(_) -> 0.0
      }
      let y_overlap =
        float.min(center_a.y +. half_height_a, center_b.y +. half_height_b)
        >. float.max(center_a.y -. half_height_a, center_b.y -. half_height_b)

      radial_dist <=. { radius_a +. radius_b } && y_overlap
    }
  }
}

/// Get the center of a collider.
pub fn center(collider: Collider) -> Vec3(Float) {
  case collider {
    Box(min, max) ->
      vec3.Vec3(
        { min.x +. max.x } /. 2.0,
        { min.y +. max.y } /. 2.0,
        { min.z +. max.z } /. 2.0,
      )
    Sphere(center, _) -> center
    Capsule(start, end, _) ->
      vec3.Vec3(
        { start.x +. end.x } /. 2.0,
        { start.y +. end.y } /. 2.0,
        { start.z +. end.z } /. 2.0,
      )
    Cylinder(center, _, _) -> center
  }
}

/// Get the size (dimensions) of a collider.
///
/// Returns the bounding box dimensions for all collider types.
pub fn size(collider: Collider) -> Vec3(Float) {
  case collider {
    Box(min, max) -> vec3f.subtract(max, min)
    Sphere(_, radius) -> {
      let diameter = radius *. 2.0
      vec3.Vec3(diameter, diameter, diameter)
    }
    Capsule(start, end, radius) -> {
      let length = vec3f.distance(start, end)
      let diameter = radius *. 2.0
      vec3.Vec3(diameter, length +. diameter, diameter)
    }
    Cylinder(_, radius, height) -> {
      let diameter = radius *. 2.0
      vec3.Vec3(diameter, height, diameter)
    }
  }
}

/// Create a new collider from a local-space collider with position, rotation, and scale.
///
/// For Box: Computes a new axis-aligned bounding box that encompasses
/// all 8 corners after rotation, translation, and scaling.
///
/// For Sphere: Transforms the center and scales the radius by the maximum
/// scale component (since spheres remain spherical under uniform scaling).
///
/// **Time Complexity**: O(1) - transforms a constant number of points (8 for Box).
///
/// ## Example
/// ```gleam
/// // Local space box
/// let local_box = collider.box(
///   min: vec3.Vec3(-1.0, -1.0, -1.0),
///   max: vec3.Vec3(1.0, 1.0, 1.0),
/// )
///
/// // Rotated 45 degrees around Y axis
/// let rotation = q.from_axis_angle(vec3.Vec3(0.0, 1.0, 0.0), 0.785)
///
/// // Get world-space collider
/// let world_box = collider.from_rotation(
///   local_box,
///   position: vec3.Vec3(5.0, 0.0, 0.0),
///   rotation: rotation,
///   scale: vec3.Vec3(1.0, 1.0, 1.0),
/// )
/// ```
pub fn from_rotation(
  collider: Collider,
  position position: Vec3(Float),
  rotation rotation: quaternion.Quaternion,
  scale scale: Vec3(Float),
) -> Collider {
  case collider {
    Box(min, max) -> {
      // Get 8 corners of the local box
      let corners = [
        vec3.Vec3(min.x, min.y, min.z),
        vec3.Vec3(max.x, min.y, min.z),
        vec3.Vec3(min.x, max.y, min.z),
        vec3.Vec3(max.x, max.y, min.z),
        vec3.Vec3(min.x, min.y, max.z),
        vec3.Vec3(max.x, min.y, max.z),
        vec3.Vec3(min.x, max.y, max.z),
        vec3.Vec3(max.x, max.y, max.z),
      ]

      // Transform all 8 corners to world space
      let transformed_corners =
        list.map(corners, fn(corner) {
          transform_point(corner, position, rotation, scale)
        })

      // Find min/max of all transformed corners
      let init_min = vec3.Vec3(1.0e10, 1.0e10, 1.0e10)
      let init_max = vec3.Vec3(-1.0e10, -1.0e10, -1.0e10)

      let #(new_min, new_max) =
        list.fold(transformed_corners, #(init_min, init_max), fn(acc, point) {
          let #(current_min, current_max) = acc
          #(
            vec3.Vec3(
              float.min(current_min.x, point.x),
              float.min(current_min.y, point.y),
              float.min(current_min.z, point.z),
            ),
            vec3.Vec3(
              float.max(current_max.x, point.x),
              float.max(current_max.y, point.y),
              float.max(current_max.z, point.z),
            ),
          )
        })

      Box(min: new_min, max: new_max)
    }

    Sphere(center, radius) -> {
      // Transform center
      let new_center = transform_point(center, position, rotation, scale)

      // Scale radius by maximum scale component
      let max_scale = float.max(scale.x, float.max(scale.y, scale.z))
      let new_radius = radius *. max_scale

      Sphere(center: new_center, radius: new_radius)
    }

    Capsule(start, end, radius) -> {
      let new_start = transform_point(start, position, rotation, scale)
      let new_end = transform_point(end, position, rotation, scale)
      let max_scale = float.max(scale.x, float.max(scale.y, scale.z))
      let new_radius = radius *. max_scale

      Capsule(start: new_start, end: new_end, radius: new_radius)
    }

    Cylinder(center, radius, height) -> {
      let new_center = transform_point(center, position, rotation, scale)
      let max_radial_scale = float.max(scale.x, scale.z)
      let new_radius = radius *. max_radial_scale
      let new_height = height *. scale.y

      Cylinder(center: new_center, radius: new_radius, height: new_height)
    }
  }
}

// --- Helper Functions ---

fn transform_point(
  point: Vec3(Float),
  position: Vec3(Float),
  rotation: quaternion.Quaternion,
  scale: Vec3(Float),
) -> Vec3(Float) {
  // Apply scale
  let scaled =
    vec3.Vec3(point.x *. scale.x, point.y *. scale.y, point.z *. scale.z)

  // Apply rotation (quaternion)
  let rotated = quaternion.rotate(rotation, scaled)

  // Apply translation
  vec3f.add(rotated, position)
}

// --- Helper Functions for Distance Calculations ---

fn point_to_line_segment_distance(
  point: Vec3(Float),
  start: Vec3(Float),
  end: Vec3(Float),
) -> Float {
  let line_vec = vec3f.subtract(end, start)
  let point_vec = vec3f.subtract(point, start)
  let line_len_sq = vec3f.dot(line_vec, line_vec)

  case line_len_sq <. 0.0001 {
    True -> vec3f.distance(point, start)
    False -> {
      let t =
        float.clamp(vec3f.dot(point_vec, line_vec) /. line_len_sq, 0.0, 1.0)
      let projection = vec3f.add(start, vec3f.scale(line_vec, t))
      vec3f.distance(point, projection)
    }
  }
}

fn line_segment_to_line_segment_distance(
  start_a: Vec3(Float),
  end_a: Vec3(Float),
  start_b: Vec3(Float),
  end_b: Vec3(Float),
) -> Float {
  let d1 = vec3f.subtract(end_a, start_a)
  let d2 = vec3f.subtract(end_b, start_b)
  let r = vec3f.subtract(start_a, start_b)

  let a = vec3f.dot(d1, d1)
  let e = vec3f.dot(d2, d2)
  let f = vec3f.dot(d2, r)

  case a <. 0.0001 && e <. 0.0001 {
    True -> vec3f.distance(start_a, start_b)
    False -> {
      case a <. 0.0001 {
        True -> {
          let t = float.clamp(f /. e, 0.0, 1.0)
          let point_on_b = vec3f.add(start_b, vec3f.scale(d2, t))
          vec3f.distance(start_a, point_on_b)
        }
        False -> {
          case e <. 0.0001 {
            True -> {
              let s = float.clamp(vec3f.dot(d1, r) /. a, 0.0, 1.0)
              let point_on_a = vec3f.add(start_a, vec3f.scale(d1, s))
              vec3f.distance(point_on_a, start_b)
            }
            False -> {
              let c = vec3f.dot(d1, r)
              let b = vec3f.dot(d1, d2)
              let denom = a *. e -. b *. b

              let s = case denom <. 0.0001 {
                True -> 0.0
                False -> float.clamp({ b *. f -. c *. e } /. denom, 0.0, 1.0)
              }

              let t = { b *. s +. f } /. e
              let t_clamped = float.clamp(t, 0.0, 1.0)

              let point_on_a = vec3f.add(start_a, vec3f.scale(d1, s))
              let point_on_b = vec3f.add(start_b, vec3f.scale(d2, t_clamped))
              vec3f.distance(point_on_a, point_on_b)
            }
          }
        }
      }
    }
  }
}

fn line_segment_intersects_box(
  start: Vec3(Float),
  end: Vec3(Float),
  min: Vec3(Float),
  max: Vec3(Float),
) -> Bool {
  // Simple slab method for line-AABB intersection
  let dir = vec3f.subtract(end, start)
  let t_min = 0.0
  let t_max = 1.0

  // Check X slab
  let inv_dir_x = case float.absolute_value(dir.x) <. 0.0001 {
    True -> 1.0e10
    False -> 1.0 /. dir.x
  }
  let tx1 = { min.x -. start.x } *. inv_dir_x
  let tx2 = { max.x -. start.x } *. inv_dir_x
  let t_min = float.max(t_min, float.min(tx1, tx2))
  let t_max = float.min(t_max, float.max(tx1, tx2))

  case t_max <. t_min {
    True -> False
    False -> {
      // Check Y slab
      let inv_dir_y = case float.absolute_value(dir.y) <. 0.0001 {
        True -> 1.0e10
        False -> 1.0 /. dir.y
      }
      let ty1 = { min.y -. start.y } *. inv_dir_y
      let ty2 = { max.y -. start.y } *. inv_dir_y
      let t_min = float.max(t_min, float.min(ty1, ty2))
      let t_max = float.min(t_max, float.max(ty1, ty2))

      case t_max <. t_min {
        True -> False
        False -> {
          // Check Z slab
          let inv_dir_z = case float.absolute_value(dir.z) <. 0.0001 {
            True -> 1.0e10
            False -> 1.0 /. dir.z
          }
          let tz1 = { min.z -. start.z } *. inv_dir_z
          let tz2 = { max.z -. start.z } *. inv_dir_z
          let t_min = float.max(t_min, float.min(tz1, tz2))
          let t_max = float.min(t_max, float.max(tz1, tz2))

          t_max >=. t_min
        }
      }
    }
  }
}
