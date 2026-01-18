//// Octree spatial partitioning data structure.
////
//// An octree divides 3D space into 8 octants recursively, enabling efficient
//// spatial queries for nearby objects.

import gleam/list
import gleam/option.{type Option, None, Some}
import spatial/collider.{type Collider}
import spatial/internal/ffi
import vec/vec3.{type Vec3}
import vec/vec3f

/// Octree node for spatial partitioning.
///
/// Divides 3D space into 8 octants recursively for efficient queries.
pub opaque type Octree(a) {
  OctreeNode(
    bounds: Collider,
    capacity: Int,
    items: List(#(Vec3(Float), a)),
    children: Option(OctreeChildren(a)),
  )
}

type OctreeChildren(a) {
  OctreeChildren(
    // Bottom 4 octants (y-)
    bottom_nw: Octree(a),
    bottom_ne: Octree(a),
    bottom_sw: Octree(a),
    bottom_se: Octree(a),
    // Top 4 octants (y+)
    top_nw: Octree(a),
    top_ne: Octree(a),
    top_sw: Octree(a),
    top_se: Octree(a),
  )
}

/// Create a new empty octree.
///
/// ## Parameters
/// - `bounds`: The spatial region this octree covers (must be a Box)
/// - `capacity`: Maximum items per node before subdividing (typically 8-16)
///
/// ## Example
/// ```gleam
/// let bounds = collider.box(
///   min: vec3.Vec3(-100.0, -100.0, -100.0),
///   max: vec3.Vec3(100.0, 100.0, 100.0),
/// )
/// let tree = octree.new(bounds, capacity: 8)
/// ```
pub fn new(bounds: Collider, capacity: Int) -> Octree(a) {
  OctreeNode(bounds: bounds, capacity: capacity, items: [], children: None)
}

/// Insert an item at a position into the octree.
///
/// **Time Complexity**: O(h + c) where h is the tree height (typically O(log n)) 
/// and c is the node capacity when subdivision occurs. Average case O(log n).
pub fn insert(tree: Octree(a), position: Vec3(Float), item: a) -> Octree(a) {
  case tree {
    OctreeNode(bounds, capacity, items, children) -> {
      // Check if position is within bounds
      case collider.contains_point(bounds, position) {
        False -> tree
        // Not in bounds, don't insert
        True ->
          case children {
            // No children yet - add to this node
            None -> {
              let new_items = [#(position, item), ..items]
              // Check if we need to subdivide
              case list.length(new_items) > capacity {
                False -> OctreeNode(..tree, items: new_items)
                True -> {
                  // Subdivide and redistribute items
                  let subdivided = subdivide(tree)
                  // Insert all items (including new one) into subdivided tree
                  list.fold(new_items, subdivided, fn(acc, item_pair) {
                    let #(pos, it) = item_pair
                    insert(acc, pos, it)
                  })
                }
              }
            }
            // Has children - insert into appropriate child
            Some(octants) -> {
              let new_children =
                insert_into_child(bounds, octants, position, item)
              OctreeNode(..tree, children: Some(new_children))
            }
          }
      }
    }
  }
}

/// Remove an item from the octree.
///
/// Removes the first occurrence of an item at the given position.
///
/// **Time Complexity**: O(n) worst case as it recursively checks all nodes, 
/// but typically O(h) where h is the tree height for sparse trees.
pub fn remove(
  tree: Octree(a),
  position: Vec3(Float),
  predicate: fn(a) -> Bool,
) -> Octree(a) {
  case tree {
    OctreeNode(bounds, _, items, children) -> {
      case collider.contains_point(bounds, position) {
        False -> tree
        True -> {
          // Try to remove from this node's items
          let new_items =
            list.filter(items, fn(item_pair) {
              let #(pos, item) = item_pair
              let is_at_position = vec3f.distance(pos, position) <. 0.0001
              let matches_predicate = predicate(item)
              !{ is_at_position && matches_predicate }
            })

          // Recursively remove from children
          let new_children = case children {
            None -> None
            Some(octants) ->
              Some(remove_from_child(bounds, octants, position, predicate))
          }

          OctreeNode(..tree, items: new_items, children: new_children)
        }
      }
    }
  }
}

/// Query all items within a collider region.
///
/// **Time Complexity**: O(log n + k) average case where k is the number of results.
/// Worst case O(n) if query region covers entire tree.
pub fn query(tree: Octree(a), query_bounds: Collider) -> List(#(Vec3(Float), a)) {
  do_query(tree, query_bounds, [])
}

fn do_query(
  tree: Octree(a),
  query_bounds: Collider,
  acc: List(#(Vec3(Float), a)),
) -> List(#(Vec3(Float), a)) {
  case tree {
    OctreeNode(bounds, _, items, children) -> {
      case collider.intersects(bounds, query_bounds) {
        False -> acc
        True -> {
          // Prepend matching items to accumulator (O(k) instead of O(n))
          let acc =
            list.fold(items, acc, fn(acc_inner, item_pair) {
              let #(pos, _) = item_pair
              case collider.contains_point(query_bounds, pos) {
                True -> [item_pair, ..acc_inner]
                False -> acc_inner
              }
            })

          case children {
            None -> acc
            Some(OctreeChildren(
              bottom_nw,
              bottom_ne,
              bottom_sw,
              bottom_se,
              top_nw,
              top_ne,
              top_sw,
              top_se,
            )) -> {
              acc
              |> do_query(bottom_nw, query_bounds, _)
              |> do_query(bottom_ne, query_bounds, _)
              |> do_query(bottom_sw, query_bounds, _)
              |> do_query(bottom_se, query_bounds, _)
              |> do_query(top_nw, query_bounds, _)
              |> do_query(top_ne, query_bounds, _)
              |> do_query(top_sw, query_bounds, _)
              |> do_query(top_se, query_bounds, _)
            }
          }
        }
      }
    }
  }
}

/// Query all items within a radius of a point.
///
/// **Time Complexity**: O(log n + k) average case where k is the number of results.
pub fn query_radius(
  tree: Octree(a),
  center: Vec3(Float),
  radius: Float,
) -> List(#(Vec3(Float), a)) {
  // Create a bounding box that encompasses the sphere
  let half_extents = vec3.Vec3(radius, radius, radius)
  let query_bounds = collider.box_from_center(center, half_extents)

  // Query the box, then filter by actual distance (using distance_squared for performance)
  let radius_sq = radius *. radius
  query(tree, query_bounds)
  |> list.filter(fn(item_pair) {
    let #(pos, _) = item_pair
    ffi.distance_squared(center, pos) <=. radius_sq
  })
}

/// Query all items in the octree (useful for iteration).
///
/// **Time Complexity**: O(n) where n is the total number of items.
pub fn query_all(tree: Octree(a)) -> List(#(Vec3(Float), a)) {
  do_query_all(tree, [])
}

fn do_query_all(
  tree: Octree(a),
  acc: List(#(Vec3(Float), a)),
) -> List(#(Vec3(Float), a)) {
  case tree {
    OctreeNode(_, _, items, children) -> {
      // Prepend items to accumulator (O(k) instead of O(n))
      let acc =
        list.fold(items, acc, fn(acc_inner, item) { [item, ..acc_inner] })
      case children {
        None -> acc
        Some(OctreeChildren(
          bottom_nw,
          bottom_ne,
          bottom_sw,
          bottom_se,
          top_nw,
          top_ne,
          top_sw,
          top_se,
        )) -> {
          acc
          |> do_query_all(bottom_nw, _)
          |> do_query_all(bottom_ne, _)
          |> do_query_all(bottom_sw, _)
          |> do_query_all(bottom_se, _)
          |> do_query_all(top_nw, _)
          |> do_query_all(top_ne, _)
          |> do_query_all(top_sw, _)
          |> do_query_all(top_se, _)
        }
      }
    }
  }
}

/// Count total items in the octree.
///
/// **Time Complexity**: O(n) where n is the total number of items.
pub fn count(tree: Octree(a)) -> Int {
  query_all(tree)
  |> list.length
}

/// Get the bounds of the octree.
pub fn bounds(tree: Octree(a)) -> Collider {
  case tree {
    OctreeNode(bounds, ..) -> bounds
  }
}

// --- Private Helper Functions ---

fn subdivide(tree: Octree(a)) -> Octree(a) {
  case tree {
    OctreeNode(bounds, capacity, _, _) -> {
      // Extract min/max from Box collider
      let assert collider.Box(min, max) = bounds
      let center = collider.center(bounds)

      // Create 8 child octants
      let bottom_nw =
        new(
          collider.Box(min: min, max: vec3.Vec3(center.x, center.y, center.z)),
          capacity,
        )
      let bottom_ne =
        new(
          collider.Box(
            min: vec3.Vec3(center.x, min.y, min.z),
            max: vec3.Vec3(max.x, center.y, center.z),
          ),
          capacity,
        )
      let bottom_sw =
        new(
          collider.Box(
            min: vec3.Vec3(min.x, min.y, center.z),
            max: vec3.Vec3(center.x, center.y, max.z),
          ),
          capacity,
        )
      let bottom_se =
        new(
          collider.Box(
            min: vec3.Vec3(center.x, min.y, center.z),
            max: vec3.Vec3(max.x, center.y, max.z),
          ),
          capacity,
        )
      let top_nw =
        new(
          collider.Box(
            min: vec3.Vec3(min.x, center.y, min.z),
            max: vec3.Vec3(center.x, max.y, center.z),
          ),
          capacity,
        )
      let top_ne =
        new(
          collider.Box(
            min: vec3.Vec3(center.x, center.y, min.z),
            max: vec3.Vec3(max.x, max.y, center.z),
          ),
          capacity,
        )
      let top_sw =
        new(
          collider.Box(
            min: vec3.Vec3(min.x, center.y, center.z),
            max: vec3.Vec3(center.x, max.y, max.z),
          ),
          capacity,
        )
      let top_se = new(collider.Box(min: center, max: max), capacity)

      OctreeNode(
        bounds: bounds,
        capacity: capacity,
        items: [],
        children: Some(OctreeChildren(
          bottom_nw: bottom_nw,
          bottom_ne: bottom_ne,
          bottom_sw: bottom_sw,
          bottom_se: bottom_se,
          top_nw: top_nw,
          top_ne: top_ne,
          top_sw: top_sw,
          top_se: top_se,
        )),
      )
    }
  }
}

fn insert_into_child(
  parent_bounds: Collider,
  children: OctreeChildren(a),
  position: Vec3(Float),
  item: a,
) -> OctreeChildren(a) {
  case children {
    OctreeChildren(
      bottom_nw,
      bottom_ne,
      bottom_sw,
      bottom_se,
      top_nw,
      top_ne,
      top_sw,
      top_se,
    ) -> {
      let center = collider.center(parent_bounds)

      case
        position.x <. center.x,
        position.y <. center.y,
        position.z <. center.z
      {
        True, True, True ->
          OctreeChildren(
            ..children,
            bottom_nw: insert(bottom_nw, position, item),
          )
        False, True, True ->
          OctreeChildren(
            ..children,
            bottom_ne: insert(bottom_ne, position, item),
          )
        True, True, False ->
          OctreeChildren(
            ..children,
            bottom_sw: insert(bottom_sw, position, item),
          )
        False, True, False ->
          OctreeChildren(
            ..children,
            bottom_se: insert(bottom_se, position, item),
          )
        True, False, True ->
          OctreeChildren(..children, top_nw: insert(top_nw, position, item))
        False, False, True ->
          OctreeChildren(..children, top_ne: insert(top_ne, position, item))
        True, False, False ->
          OctreeChildren(..children, top_sw: insert(top_sw, position, item))
        False, False, False ->
          OctreeChildren(..children, top_se: insert(top_se, position, item))
      }
    }
  }
}

fn remove_from_child(
  _parent_bounds: Collider,
  children: OctreeChildren(a),
  position: Vec3(Float),
  predicate: fn(a) -> Bool,
) -> OctreeChildren(a) {
  case children {
    OctreeChildren(
      bottom_nw,
      bottom_ne,
      bottom_sw,
      bottom_se,
      top_nw,
      top_ne,
      top_sw,
      top_se,
    ) -> {
      OctreeChildren(
        bottom_nw: remove(bottom_nw, position, predicate),
        bottom_ne: remove(bottom_ne, position, predicate),
        bottom_sw: remove(bottom_sw, position, predicate),
        bottom_se: remove(bottom_se, position, predicate),
        top_nw: remove(top_nw, position, predicate),
        top_ne: remove(top_ne, position, predicate),
        top_sw: remove(top_sw, position, predicate),
        top_se: remove(top_se, position, predicate),
      )
    }
  }
}
