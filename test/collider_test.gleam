import quaternion
import spatial/collider
import vec/vec3

pub fn box_creation_test() {
  let box =
    collider.box(min: vec3.Vec3(0.0, 0.0, 0.0), max: vec3.Vec3(1.0, 1.0, 1.0))
  assert box
    == collider.Box(
      min: vec3.Vec3(0.0, 0.0, 0.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
}

pub fn box_from_center_test() {
  let box =
    collider.box_from_center(
      center: vec3.Vec3(0.0, 0.0, 0.0),
      half_extents: vec3.Vec3(1.0, 1.0, 1.0),
    )
  assert box
    == collider.Box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
}

pub fn sphere_creation_test() {
  let sphere = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 5.0)
  assert sphere
    == collider.Sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 5.0)
}

pub fn box_contains_point_inside_test() {
  let box =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  assert collider.contains_point(box, vec3.Vec3(0.0, 0.0, 0.0))
}

pub fn box_contains_point_outside_test() {
  let box =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  assert !collider.contains_point(box, vec3.Vec3(2.0, 0.0, 0.0))
}

pub fn box_contains_point_on_edge_test() {
  let box =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  assert collider.contains_point(box, vec3.Vec3(1.0, 0.0, 0.0))
}

pub fn sphere_contains_point_inside_test() {
  let sphere = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 5.0)
  assert collider.contains_point(sphere, vec3.Vec3(1.0, 1.0, 1.0))
}

pub fn sphere_contains_point_outside_test() {
  let sphere = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 5.0)
  assert !collider.contains_point(sphere, vec3.Vec3(10.0, 0.0, 0.0))
}

pub fn box_box_intersects_test() {
  let box1 =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  let box2 =
    collider.box(min: vec3.Vec3(0.0, 0.0, 0.0), max: vec3.Vec3(2.0, 2.0, 2.0))
  assert collider.intersects(box1, box2)
}

pub fn box_box_no_intersect_test() {
  let box1 =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  let box2 =
    collider.box(
      min: vec3.Vec3(5.0, 5.0, 5.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  assert !collider.intersects(box1, box2)
}

pub fn sphere_sphere_intersects_test() {
  let sphere1 = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 2.0)
  let sphere2 = collider.sphere(center: vec3.Vec3(3.0, 0.0, 0.0), radius: 2.0)
  assert collider.intersects(sphere1, sphere2)
}

pub fn sphere_sphere_no_intersect_test() {
  let sphere1 = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 1.0)
  let sphere2 = collider.sphere(center: vec3.Vec3(5.0, 0.0, 0.0), radius: 1.0)
  assert !collider.intersects(sphere1, sphere2)
}

pub fn box_sphere_intersects_test() {
  let box =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  let sphere = collider.sphere(center: vec3.Vec3(2.0, 0.0, 0.0), radius: 2.0)
  assert collider.intersects(box, sphere)
}

pub fn box_sphere_no_intersect_test() {
  let box =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  let sphere = collider.sphere(center: vec3.Vec3(5.0, 0.0, 0.0), radius: 1.0)
  assert !collider.intersects(box, sphere)
}

pub fn box_center_test() {
  let box =
    collider.box(
      min: vec3.Vec3(-2.0, -2.0, -2.0),
      max: vec3.Vec3(2.0, 2.0, 2.0),
    )
  assert collider.center(box) == vec3.Vec3(0.0, 0.0, 0.0)
}

pub fn sphere_center_test() {
  let sphere = collider.sphere(center: vec3.Vec3(5.0, 3.0, 1.0), radius: 2.0)
  assert collider.center(sphere) == vec3.Vec3(5.0, 3.0, 1.0)
}

pub fn box_size_test() {
  let box =
    collider.box(
      min: vec3.Vec3(-1.0, -2.0, -3.0),
      max: vec3.Vec3(1.0, 2.0, 3.0),
    )
  assert collider.size(box) == vec3.Vec3(2.0, 4.0, 6.0)
}

pub fn sphere_size_test() {
  let sphere = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 5.0)
  assert collider.size(sphere) == vec3.Vec3(10.0, 10.0, 10.0)
}

pub fn from_rotation_box_no_rotation_test() {
  let local_box =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  let rotation = quaternion.identity
  let world_box =
    collider.from_rotation(
      local_box,
      position: vec3.Vec3(5.0, 0.0, 0.0),
      rotation: rotation,
      scale: vec3.Vec3(1.0, 1.0, 1.0),
    )
  assert collider.center(world_box) == vec3.Vec3(5.0, 0.0, 0.0)
}

pub fn from_rotation_sphere_test() {
  let local_sphere =
    collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 1.0)
  let rotation = quaternion.identity
  let world_sphere =
    collider.from_rotation(
      local_sphere,
      position: vec3.Vec3(5.0, 3.0, 2.0),
      rotation: rotation,
      scale: vec3.Vec3(2.0, 2.0, 2.0),
    )

  let assert collider.Sphere(center, radius) = world_sphere
  assert center == vec3.Vec3(5.0, 3.0, 2.0)
  assert radius == 2.0
}

pub fn from_rotation_box_with_scale_test() {
  let local_box =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  let rotation = quaternion.identity
  let world_box =
    collider.from_rotation(
      local_box,
      position: vec3.Vec3(0.0, 0.0, 0.0),
      rotation: rotation,
      scale: vec3.Vec3(2.0, 2.0, 2.0),
    )
  assert collider.size(world_box) == vec3.Vec3(4.0, 4.0, 4.0)
}

// ============================================================================
// Capsule Tests
// ============================================================================

pub fn capsule_creation_test() {
  let capsule =
    collider.capsule(
      start: vec3.Vec3(0.0, 0.0, 0.0),
      end: vec3.Vec3(0.0, 2.0, 0.0),
      radius: 0.5,
    )
  assert capsule
    == collider.Capsule(
      start: vec3.Vec3(0.0, 0.0, 0.0),
      end: vec3.Vec3(0.0, 2.0, 0.0),
      radius: 0.5,
    )
}

pub fn capsule_contains_point_inside_test() {
  let capsule =
    collider.capsule(
      start: vec3.Vec3(0.0, 0.0, 0.0),
      end: vec3.Vec3(0.0, 2.0, 0.0),
      radius: 0.5,
    )
  assert collider.contains_point(capsule, vec3.Vec3(0.0, 1.0, 0.0))
  assert collider.contains_point(capsule, vec3.Vec3(0.4, 1.0, 0.0))
}

pub fn capsule_contains_point_outside_test() {
  let capsule =
    collider.capsule(
      start: vec3.Vec3(0.0, 0.0, 0.0),
      end: vec3.Vec3(0.0, 2.0, 0.0),
      radius: 0.5,
    )
  assert !collider.contains_point(capsule, vec3.Vec3(1.0, 1.0, 0.0))
}

pub fn capsule_capsule_intersects_test() {
  let cap1 =
    collider.capsule(
      start: vec3.Vec3(0.0, 0.0, 0.0),
      end: vec3.Vec3(0.0, 2.0, 0.0),
      radius: 0.5,
    )
  let cap2 =
    collider.capsule(
      start: vec3.Vec3(0.5, 0.0, 0.0),
      end: vec3.Vec3(0.5, 2.0, 0.0),
      radius: 0.5,
    )
  assert collider.intersects(cap1, cap2)
}

pub fn capsule_capsule_no_intersect_test() {
  let cap1 =
    collider.capsule(
      start: vec3.Vec3(0.0, 0.0, 0.0),
      end: vec3.Vec3(0.0, 2.0, 0.0),
      radius: 0.5,
    )
  let cap2 =
    collider.capsule(
      start: vec3.Vec3(5.0, 0.0, 0.0),
      end: vec3.Vec3(5.0, 2.0, 0.0),
      radius: 0.5,
    )
  assert !collider.intersects(cap1, cap2)
}

pub fn capsule_sphere_intersects_test() {
  let capsule =
    collider.capsule(
      start: vec3.Vec3(0.0, 0.0, 0.0),
      end: vec3.Vec3(0.0, 2.0, 0.0),
      radius: 0.5,
    )
  let sphere = collider.sphere(center: vec3.Vec3(0.8, 1.0, 0.0), radius: 0.5)
  assert collider.intersects(capsule, sphere)
}

pub fn capsule_center_test() {
  let capsule =
    collider.capsule(
      start: vec3.Vec3(0.0, 0.0, 0.0),
      end: vec3.Vec3(0.0, 4.0, 0.0),
      radius: 0.5,
    )
  assert collider.center(capsule) == vec3.Vec3(0.0, 2.0, 0.0)
}

// ============================================================================
// Cylinder Tests
// ============================================================================

pub fn cylinder_creation_test() {
  let cylinder =
    collider.cylinder(
      center: vec3.Vec3(0.0, 5.0, 0.0),
      radius: 1.0,
      height: 10.0,
    )
  assert cylinder
    == collider.Cylinder(
      center: vec3.Vec3(0.0, 5.0, 0.0),
      radius: 1.0,
      height: 10.0,
    )
}

pub fn cylinder_contains_point_inside_test() {
  let cylinder =
    collider.cylinder(
      center: vec3.Vec3(0.0, 5.0, 0.0),
      radius: 1.0,
      height: 10.0,
    )
  assert collider.contains_point(cylinder, vec3.Vec3(0.5, 5.0, 0.5))
}

pub fn cylinder_contains_point_outside_radial_test() {
  let cylinder =
    collider.cylinder(
      center: vec3.Vec3(0.0, 5.0, 0.0),
      radius: 1.0,
      height: 10.0,
    )
  assert !collider.contains_point(cylinder, vec3.Vec3(2.0, 5.0, 0.0))
}

pub fn cylinder_contains_point_outside_height_test() {
  let cylinder =
    collider.cylinder(
      center: vec3.Vec3(0.0, 5.0, 0.0),
      radius: 1.0,
      height: 10.0,
    )
  assert !collider.contains_point(cylinder, vec3.Vec3(0.0, 11.0, 0.0))
}

pub fn cylinder_sphere_intersects_test() {
  let cylinder =
    collider.cylinder(
      center: vec3.Vec3(0.0, 5.0, 0.0),
      radius: 1.0,
      height: 10.0,
    )
  let sphere = collider.sphere(center: vec3.Vec3(1.5, 5.0, 0.0), radius: 1.0)
  assert collider.intersects(cylinder, sphere)
}

pub fn cylinder_center_test() {
  let cylinder =
    collider.cylinder(
      center: vec3.Vec3(5.0, 10.0, 3.0),
      radius: 2.0,
      height: 8.0,
    )
  assert collider.center(cylinder) == vec3.Vec3(5.0, 10.0, 3.0)
}

pub fn cylinder_size_test() {
  let cylinder =
    collider.cylinder(
      center: vec3.Vec3(0.0, 5.0, 0.0),
      radius: 2.0,
      height: 10.0,
    )
  assert collider.size(cylinder) == vec3.Vec3(4.0, 10.0, 4.0)
}
