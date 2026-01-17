import collider
import gleam/list
import octree
import vec/vec3

pub fn new_octree_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let tree = octree.new(bounds, 8)
  assert octree.count(tree) == 0
}

pub fn insert_single_item_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let tree = octree.new(bounds, 4)
  let tree = octree.insert(tree, vec3.Vec3(0.0, 0.0, 0.0), "item1")
  assert octree.count(tree) == 1
}

pub fn insert_multiple_items_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let tree = octree.new(bounds, 4)
  let tree = octree.insert(tree, vec3.Vec3(1.0, 1.0, 1.0), "item1")
  let tree = octree.insert(tree, vec3.Vec3(-1.0, -1.0, -1.0), "item2")
  let tree = octree.insert(tree, vec3.Vec3(2.0, 2.0, 2.0), "item3")
  assert octree.count(tree) == 3
}

pub fn insert_out_of_bounds_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let tree = octree.new(bounds, 4)
  let tree = octree.insert(tree, vec3.Vec3(100.0, 100.0, 100.0), "item_outside")
  assert octree.count(tree) == 0
}

pub fn subdivide_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let tree = octree.new(bounds, 2)
  let tree = octree.insert(tree, vec3.Vec3(1.0, 1.0, 1.0), "item1")
  let tree = octree.insert(tree, vec3.Vec3(2.0, 2.0, 2.0), "item2")
  let tree = octree.insert(tree, vec3.Vec3(-1.0, -1.0, -1.0), "item3")
  assert octree.count(tree) == 3
}

pub fn remove_item_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let tree = octree.new(bounds, 4)
  let tree = octree.insert(tree, vec3.Vec3(1.0, 1.0, 1.0), "item1")
  let tree = octree.insert(tree, vec3.Vec3(-1.0, -1.0, -1.0), "item2")
  let tree =
    octree.remove(tree, vec3.Vec3(1.0, 1.0, 1.0), fn(x) { x == "item1" })
  assert octree.count(tree) == 1
}

pub fn query_all_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let tree = octree.new(bounds, 4)
  let tree = octree.insert(tree, vec3.Vec3(1.0, 1.0, 1.0), "item1")
  let tree = octree.insert(tree, vec3.Vec3(-1.0, -1.0, -1.0), "item2")
  let items = octree.query_all(tree)
  assert list.length(items) == 2
}

pub fn query_region_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let tree = octree.new(bounds, 4)
  let tree = octree.insert(tree, vec3.Vec3(1.0, 1.0, 1.0), "item1")
  let tree = octree.insert(tree, vec3.Vec3(5.0, 5.0, 5.0), "item2")
  let tree = octree.insert(tree, vec3.Vec3(-5.0, -5.0, -5.0), "item3")

  let query_bounds =
    collider.box(
      min: vec3.Vec3(0.0, 0.0, 0.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let results = octree.query(tree, query_bounds)
  assert list.length(results) == 2
}

pub fn query_radius_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let tree = octree.new(bounds, 4)
  let tree = octree.insert(tree, vec3.Vec3(0.0, 0.0, 0.0), "center")
  let tree = octree.insert(tree, vec3.Vec3(1.0, 0.0, 0.0), "near")
  let tree = octree.insert(tree, vec3.Vec3(5.0, 0.0, 0.0), "far")

  let results = octree.query_radius(tree, vec3.Vec3(0.0, 0.0, 0.0), 2.0)
  assert list.length(results) == 2
}

pub fn query_radius_empty_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let tree = octree.new(bounds, 4)
  let tree = octree.insert(tree, vec3.Vec3(5.0, 5.0, 5.0), "far")

  let results = octree.query_radius(tree, vec3.Vec3(0.0, 0.0, 0.0), 1.0)
  assert results == []
}

pub fn bounds_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let tree = octree.new(bounds, 4)
  let tree_bounds = octree.bounds(tree)
  assert tree_bounds == bounds
}
