//// Hash Grid spatial partitioning data structure.
////
//// Uses Erlang maps (HAMT with branching factor 32) providing O(log₃₂ n) operations,
//// which is effectively O(1) in practice. At 1 million cells, operations take only
//// ~5 steps. Excellent for uniformly distributed objects like particles or crowds.

import gleam/dict.{type Dict}
import gleam/float
import gleam/list
import gleam/result
import spatial/collider.{type Collider}
import vec/vec3.{type Vec3}
import vec/vec3f

/// Hash Grid for fast spatial queries with uniform distributions.
///
/// Uses Erlang maps (32-way HAMT) for O(log₃₂ n) insertion/removal,
/// effectively O(1) in practice. n is the number of occupied cells.
pub opaque type Grid(a) {
  Grid(
    cell_size: Float,
    bounds: Collider,
    cells: Dict(#(Int, Int, Int), List(#(Vec3(Float), a))),
  )
}

/// Create a new empty hash grid.
///
/// ## Parameters
/// - `cell_size`: Size of each grid cell (should match typical object size)
/// - `bounds`: The spatial region this grid covers
///
/// ## Example
/// ```gleam
/// let bounds = collider.box(
///   min: vec3.Vec3(-100.0, -100.0, -100.0),
///   max: vec3.Vec3(100.0, 100.0, 100.0),
/// )
/// let grid = grid.new(cell_size: 10.0, bounds: bounds)
/// ```
pub fn new(cell_size cell_size: Float, bounds bounds: Collider) -> Grid(a) {
  Grid(cell_size: cell_size, bounds: bounds, cells: dict.new())
}

/// Insert an item at a position into the grid.
///
/// **Time Complexity**: O(log₃₂ n) where n is the number of occupied cells,
/// effectively O(1) in practice. Faster than octree for uniform distributions.
pub fn insert(grid: Grid(a), position: Vec3(Float), item: a) -> Grid(a) {
  case collider.contains_point(grid.bounds, position) {
    False -> grid
    True -> {
      let cell_key = position_to_cell(position, grid.cell_size)
      let current_items = dict.get(grid.cells, cell_key) |> result.unwrap([])
      let updated_items = [#(position, item), ..current_items]
      let updated_cells = dict.insert(grid.cells, cell_key, updated_items)
      Grid(..grid, cells: updated_cells)
    }
  }
}

/// Remove an item from the grid.
///
/// **Time Complexity**: O(log₃₂ n) cell lookup + O(k) filtering where n is the
/// number of occupied cells and k is items in that cell. Effectively O(k) in practice.
pub fn remove(
  grid: Grid(a),
  position: Vec3(Float),
  predicate: fn(a) -> Bool,
) -> Grid(a) {
  case collider.contains_point(grid.bounds, position) {
    False -> grid
    True -> {
      let cell_key = position_to_cell(position, grid.cell_size)
      case dict.get(grid.cells, cell_key) {
        Error(_) -> grid
        Ok(items) -> {
          let filtered_items =
            list.filter(items, fn(item_pair) {
              let #(pos, item) = item_pair
              let is_at_position = vec3f.distance(pos, position) <. 0.0001
              let matches_predicate = predicate(item)
              !{ is_at_position && matches_predicate }
            })

          let updated_cells = case filtered_items {
            [] -> dict.delete(grid.cells, cell_key)
            _ -> dict.insert(grid.cells, cell_key, filtered_items)
          }
          Grid(..grid, cells: updated_cells)
        }
      }
    }
  }
}

/// Query all items within a collider region.
///
/// More efficient than octree for uniform distributions.
///
/// **Time Complexity**: O(c·log₃₂ m + k) where c is cells checked, m is occupied
/// cells, and k is results. Effectively O(c + k) in practice.
pub fn query(grid: Grid(a), query_bounds: Collider) -> List(#(Vec3(Float), a)) {
  let cells_to_check = get_cells_in_bounds(query_bounds, grid.cell_size)

  list.fold(cells_to_check, [], fn(acc, cell_key) {
    case dict.get(grid.cells, cell_key) {
      Error(_) -> acc
      Ok(items) ->
        list.fold(items, acc, fn(acc_inner, item_pair) {
          let #(pos, _) = item_pair
          case collider.contains_point(query_bounds, pos) {
            True -> [item_pair, ..acc_inner]
            False -> acc_inner
          }
        })
    }
  })
}

/// Query all items within a radius of a point.
///
/// Extremely fast for uniform distributions - only checks nearby cells.
///
/// **Time Complexity**: O(c·log₃₂ m + k) where c is cells checked, m is occupied
/// cells, and k is results. Effectively O(c + k) in practice.
pub fn query_radius(
  grid: Grid(a),
  center: Vec3(Float),
  radius: Float,
) -> List(#(Vec3(Float), a)) {
  let cells_to_check = get_cells_in_radius(center, radius, grid.cell_size)

  // Single fold instead of flat_map + filter to avoid intermediate lists
  list.fold(cells_to_check, [], fn(acc, cell_key) {
    case dict.get(grid.cells, cell_key) {
      Error(_) -> acc
      Ok(items) ->
        list.fold(items, acc, fn(acc_inner, item_pair) {
          let #(pos, _) = item_pair
          case vec3f.distance(center, pos) <=. radius {
            True -> [item_pair, ..acc_inner]
            False -> acc_inner
          }
        })
    }
  })
}

/// Query all items in the grid (useful for iteration).
///
/// **Time Complexity**: O(n) where n is the total number of items.
pub fn query_all(grid: Grid(a)) -> List(#(Vec3(Float), a)) {
  dict.values(grid.cells)
  |> list.flatten()
}

/// Count total items in the grid.
///
/// **Time Complexity**: O(m) where m is the number of occupied cells.
pub fn count(grid: Grid(a)) -> Int {
  dict.fold(grid.cells, 0, fn(acc, _key, items) { acc + list.length(items) })
}

/// Get the bounds of the grid.
pub fn bounds(grid: Grid(a)) -> Collider {
  grid.bounds
}

/// Get the cell size of the grid.
pub fn cell_size(grid: Grid(a)) -> Float {
  grid.cell_size
}

/// Get the number of non-empty cells.
pub fn cell_count(grid: Grid(a)) -> Int {
  dict.size(grid.cells)
}

// --- Private Helper Functions ---

fn position_to_cell(position: Vec3(Float), cell_size: Float) -> #(Int, Int, Int) {
  let x = float.floor(position.x /. cell_size) |> float.round()
  let y = float.floor(position.y /. cell_size) |> float.round()
  let z = float.floor(position.z /. cell_size) |> float.round()
  #(x, y, z)
}

fn get_cells_in_radius(
  center: Vec3(Float),
  radius: Float,
  cell_size: Float,
) -> List(#(Int, Int, Int)) {
  let center_cell = position_to_cell(center, cell_size)
  let cell_radius = float.ceiling(radius /. cell_size) |> float.round()

  let range_x =
    list.range(center_cell.0 - cell_radius, center_cell.0 + cell_radius)
  let range_y =
    list.range(center_cell.1 - cell_radius, center_cell.1 + cell_radius)
  let range_z =
    list.range(center_cell.2 - cell_radius, center_cell.2 + cell_radius)

  list.flat_map(range_x, fn(x) {
    list.flat_map(range_y, fn(y) { list.map(range_z, fn(z) { #(x, y, z) }) })
  })
}

fn get_cells_in_bounds(
  bounds: Collider,
  cell_size: Float,
) -> List(#(Int, Int, Int)) {
  let center = collider.center(bounds)
  let size = collider.size(bounds)
  let radius = float.max(size.x, float.max(size.y, size.z)) /. 2.0

  get_cells_in_radius(center, radius, cell_size)
}
