import bvh
import collider
import gleam/list
import gleam/option
import vec/vec3

pub fn from_empty_items_test() {
  let result = bvh.from_items([], max_leaf_size: 4)
  assert result == option.None
}

pub fn from_single_item_test() {
  let items = [#(vec3.Vec3(0.0, 0.0, 0.0), "item1")]
  let result = bvh.from_items(items, max_leaf_size: 4)
  assert result != option.None

  let assert option.Some(tree) = result
  assert bvh.count(tree) == 1
}

pub fn from_multiple_items_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(10.0, 0.0, 0.0), "item2"),
    #(vec3.Vec3(20.0, 0.0, 0.0), "item3"),
  ]
  let result = bvh.from_items(items, max_leaf_size: 4)
  let assert option.Some(tree) = result
  assert bvh.count(tree) == 3
}

pub fn from_many_items_splits_test() {
  let items =
    list.range(0, 20)
    |> list.map(fn(i) {
      let x = int.to_float(i) *. 2.0
      #(vec3.Vec3(x, 0.0, 0.0), "item_" <> int.to_string(i))
    })

  let result = bvh.from_items(items, max_leaf_size: 4)
  let assert option.Some(tree) = result
  assert bvh.count(tree) == 21
}

pub fn query_all_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(10.0, 0.0, 0.0), "item2"),
  ]
  let assert option.Some(tree) = bvh.from_items(items, max_leaf_size: 4)
  let results = bvh.query_all(tree)
  assert list.length(results) == 2
}

pub fn query_region_test() {
  let items = [
    #(vec3.Vec3(1.0, 1.0, 1.0), "item1"),
    #(vec3.Vec3(5.0, 5.0, 5.0), "item2"),
    #(vec3.Vec3(-5.0, -5.0, -5.0), "item3"),
  ]
  let assert option.Some(tree) = bvh.from_items(items, max_leaf_size: 4)

  let query_bounds =
    collider.box(
      min: vec3.Vec3(0.0, 0.0, 0.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let results = bvh.query(tree, query_bounds)
  assert list.length(results) == 2
}

pub fn query_radius_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "center"),
    #(vec3.Vec3(1.0, 0.0, 0.0), "near"),
    #(vec3.Vec3(5.0, 0.0, 0.0), "far"),
  ]
  let assert option.Some(tree) = bvh.from_items(items, max_leaf_size: 4)

  let results = bvh.query_radius(tree, vec3.Vec3(0.0, 0.0, 0.0), 2.0)
  assert list.length(results) == 2
}

pub fn query_radius_empty_test() {
  let items = [
    #(vec3.Vec3(50.0, 50.0, 50.0), "far"),
  ]
  let assert option.Some(tree) = bvh.from_items(items, max_leaf_size: 4)

  let results = bvh.query_radius(tree, vec3.Vec3(0.0, 0.0, 0.0), 1.0)
  assert results == []
}

pub fn bounds_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(10.0, 10.0, 10.0), "item2"),
  ]
  let assert option.Some(tree) = bvh.from_items(items, max_leaf_size: 4)
  let bounds = bvh.bounds(tree)

  // Check that bounds encompass all items
  assert collider.contains_point(bounds, vec3.Vec3(0.0, 0.0, 0.0))
  assert collider.contains_point(bounds, vec3.Vec3(10.0, 10.0, 10.0))
}

pub fn query_with_tight_bounds_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(1.0, 1.0, 1.0), "item2"),
    #(vec3.Vec3(2.0, 2.0, 2.0), "item3"),
  ]
  let assert option.Some(tree) = bvh.from_items(items, max_leaf_size: 4)

  let query_bounds =
    collider.box(min: vec3.Vec3(0.5, 0.5, 0.5), max: vec3.Vec3(1.5, 1.5, 1.5))
  let results = bvh.query(tree, query_bounds)
  assert list.length(results) == 1
}

import gleam/int
