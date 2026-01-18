import gleam/list
import spatial/bvh
import spatial/collider
import vec/vec3

pub fn from_empty_items_test() {
  let result = bvh.from_items([], max_leaf_size: 4)
  assert result == Error(Nil)
}

pub fn from_single_item_test() {
  let items = [#(vec3.Vec3(0.0, 0.0, 0.0), "item1")]
  let result = bvh.from_items(items, max_leaf_size: 4)
  assert result != Error(Nil)

  let assert Ok(tree) = result
  assert bvh.count(tree) == 1
}

pub fn from_multiple_items_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(10.0, 0.0, 0.0), "item2"),
    #(vec3.Vec3(20.0, 0.0, 0.0), "item3"),
  ]
  let result = bvh.from_items(items, max_leaf_size: 4)
  let assert Ok(tree) = result
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
  let assert Ok(tree) = result
  assert bvh.count(tree) == 21
}

pub fn query_all_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(10.0, 0.0, 0.0), "item2"),
  ]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)
  let results = bvh.query_all(tree)
  assert list.length(results) == 2
}

pub fn query_region_test() {
  let items = [
    #(vec3.Vec3(1.0, 1.0, 1.0), "item1"),
    #(vec3.Vec3(5.0, 5.0, 5.0), "item2"),
    #(vec3.Vec3(-5.0, -5.0, -5.0), "item3"),
  ]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

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
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  let results = bvh.query_radius(tree, vec3.Vec3(0.0, 0.0, 0.0), 2.0)
  assert list.length(results) == 2
}

pub fn query_radius_empty_test() {
  let items = [
    #(vec3.Vec3(50.0, 50.0, 50.0), "far"),
  ]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  let results = bvh.query_radius(tree, vec3.Vec3(0.0, 0.0, 0.0), 1.0)
  assert results == []
}

pub fn bounds_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(10.0, 10.0, 10.0), "item2"),
  ]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)
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
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  let query_bounds =
    collider.box(min: vec3.Vec3(0.5, 0.5, 0.5), max: vec3.Vec3(1.5, 1.5, 1.5))
  let results = bvh.query(tree, query_bounds)
  assert list.length(results) == 1
}

import gleam/int

// --- Incremental Update Tests ---

pub fn insert_to_small_leaf_test() {
  let items = [#(vec3.Vec3(0.0, 0.0, 0.0), "item1")]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  let updated_tree =
    bvh.insert(tree, vec3.Vec3(1.0, 0.0, 0.0), "item2", max_leaf_size: 4)
  assert bvh.count(updated_tree) == 2

  // Verify both items are queryable
  let all_items = bvh.query_all(updated_tree)
  assert list.length(all_items) == 2
}

pub fn insert_causes_split_test() {
  // Create a leaf at max capacity
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(1.0, 0.0, 0.0), "item2"),
    #(vec3.Vec3(2.0, 0.0, 0.0), "item3"),
    #(vec3.Vec3(3.0, 0.0, 0.0), "item4"),
  ]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  // Insert one more to trigger split
  let updated_tree =
    bvh.insert(tree, vec3.Vec3(4.0, 0.0, 0.0), "item5", max_leaf_size: 4)
  assert bvh.count(updated_tree) == 5

  // Verify all items are still queryable
  let all_items = bvh.query_all(updated_tree)
  assert list.length(all_items) == 5
}

pub fn insert_updates_bounds_test() {
  let items = [#(vec3.Vec3(0.0, 0.0, 0.0), "item1")]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  // Insert far away
  let updated_tree =
    bvh.insert(tree, vec3.Vec3(100.0, 100.0, 100.0), "item2", max_leaf_size: 4)

  // Bounds should encompass both points
  let bounds = bvh.bounds(updated_tree)
  assert collider.contains_point(bounds, vec3.Vec3(0.0, 0.0, 0.0))
  assert collider.contains_point(bounds, vec3.Vec3(100.0, 100.0, 100.0))
}

pub fn remove_from_leaf_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(1.0, 0.0, 0.0), "item2"),
  ]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  let result = bvh.remove(tree, fn(item) { item == "item1" })
  let assert Ok(updated_tree) = result
  assert bvh.count(updated_tree) == 1

  // Verify only item2 remains
  let all_items = bvh.query_all(updated_tree)
  assert list.length(all_items) == 1
  let assert [#(_pos, item)] = all_items
  assert item == "item2"
}

pub fn remove_last_item_from_leaf_test() {
  let items = [#(vec3.Vec3(0.0, 0.0, 0.0), "item1")]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  let result = bvh.remove(tree, fn(item) { item == "item1" })
  // Should return Error when removing the last item
  assert result == Error(Nil)
}

pub fn remove_nonexistent_item_test() {
  let items = [#(vec3.Vec3(0.0, 0.0, 0.0), "item1")]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  let result = bvh.remove(tree, fn(item) { item == "nonexistent" })
  assert result == Error(Nil)
}

pub fn update_item_position_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(1.0, 0.0, 0.0), "item2"),
  ]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  // Update item1's position
  let result =
    bvh.update(
      tree,
      fn(item) { item == "item1" },
      vec3.Vec3(100.0, 0.0, 0.0),
      "item1",
      max_leaf_size: 4,
    )
  let assert Ok(updated_tree) = result

  // Should still have 2 items
  assert bvh.count(updated_tree) == 2

  // Verify item1 is at new position
  let results = bvh.query_radius(updated_tree, vec3.Vec3(100.0, 0.0, 0.0), 1.0)
  assert list.length(results) == 1
}

pub fn refit_updates_all_bounds_test() {
  let items = [
    #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
    #(vec3.Vec3(10.0, 0.0, 0.0), "item2"),
  ]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  // Refit should maintain the same structure
  let refitted_tree = bvh.refit(tree)
  assert bvh.count(refitted_tree) == 2

  // Bounds should still encompass all items
  let bounds = bvh.bounds(refitted_tree)
  assert collider.contains_point(bounds, vec3.Vec3(0.0, 0.0, 0.0))
  assert collider.contains_point(bounds, vec3.Vec3(10.0, 0.0, 0.0))
}

pub fn multiple_inserts_test() {
  let items = [#(vec3.Vec3(0.0, 0.0, 0.0), "item1")]
  let assert Ok(tree) = bvh.from_items(items, max_leaf_size: 4)

  // Insert multiple items sequentially
  let tree =
    bvh.insert(tree, vec3.Vec3(1.0, 0.0, 0.0), "item2", max_leaf_size: 4)
  let tree =
    bvh.insert(tree, vec3.Vec3(2.0, 0.0, 0.0), "item3", max_leaf_size: 4)
  let tree =
    bvh.insert(tree, vec3.Vec3(3.0, 0.0, 0.0), "item4", max_leaf_size: 4)

  assert bvh.count(tree) == 4

  // All items should be queryable
  let all_items = bvh.query_all(tree)
  assert list.length(all_items) == 4
}
