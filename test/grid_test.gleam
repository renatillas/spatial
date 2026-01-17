import gleam/list
import spatial/collider
import spatial/grid
import vec/vec3

pub fn new_grid_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  assert grid.count(g) == 0
}

pub fn insert_single_item_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let g = grid.insert(g, vec3.Vec3(0.0, 0.0, 0.0), "item1")
  assert grid.count(g) == 1
}

pub fn insert_multiple_items_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let g = grid.insert(g, vec3.Vec3(1.0, 1.0, 1.0), "item1")
  let g = grid.insert(g, vec3.Vec3(-1.0, -1.0, -1.0), "item2")
  let g = grid.insert(g, vec3.Vec3(2.0, 2.0, 2.0), "item3")
  assert grid.count(g) == 3
}

pub fn insert_out_of_bounds_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let g = grid.insert(g, vec3.Vec3(100.0, 100.0, 100.0), "item_outside")
  assert grid.count(g) == 0
}

pub fn remove_item_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let g = grid.insert(g, vec3.Vec3(1.0, 1.0, 1.0), "item1")
  let g = grid.insert(g, vec3.Vec3(-1.0, -1.0, -1.0), "item2")
  let g = grid.remove(g, vec3.Vec3(1.0, 1.0, 1.0), fn(x) { x == "item1" })
  assert grid.count(g) == 1
}

pub fn query_all_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let g = grid.insert(g, vec3.Vec3(1.0, 1.0, 1.0), "item1")
  let g = grid.insert(g, vec3.Vec3(-1.0, -1.0, -1.0), "item2")
  let items = grid.query_all(g)
  assert list.length(items) == 2
}

pub fn query_region_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let g = grid.insert(g, vec3.Vec3(1.0, 1.0, 1.0), "item1")
  let g = grid.insert(g, vec3.Vec3(5.0, 5.0, 5.0), "item2")
  let g = grid.insert(g, vec3.Vec3(-5.0, -5.0, -5.0), "item3")

  let query_bounds =
    collider.box(
      min: vec3.Vec3(0.0, 0.0, 0.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let results = grid.query(g, query_bounds)
  assert list.length(results) == 2
}

pub fn query_radius_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let g = grid.insert(g, vec3.Vec3(0.0, 0.0, 0.0), "center")
  let g = grid.insert(g, vec3.Vec3(1.0, 0.0, 0.0), "near")
  let g = grid.insert(g, vec3.Vec3(5.0, 0.0, 0.0), "far")

  let results = grid.query_radius(g, vec3.Vec3(0.0, 0.0, 0.0), 2.0)
  assert list.length(results) == 2
}

pub fn query_radius_empty_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let g = grid.insert(g, vec3.Vec3(50.0, 50.0, 50.0), "far")

  let results = grid.query_radius(g, vec3.Vec3(0.0, 0.0, 0.0), 1.0)
  assert results == []
}

pub fn bounds_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let grid_bounds = grid.bounds(g)
  assert grid_bounds == bounds
}

pub fn cell_size_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  assert grid.cell_size(g) == 10.0
}

pub fn cell_count_test() {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let g = grid.insert(g, vec3.Vec3(0.0, 0.0, 0.0), "item1")
  let g = grid.insert(g, vec3.Vec3(0.5, 0.5, 0.5), "item2")
  let g = grid.insert(g, vec3.Vec3(20.0, 20.0, 20.0), "item3")
  assert grid.cell_count(g) == 2
}
