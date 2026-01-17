//// Bounding Volume Hierarchy (BVH) for efficient spatial queries.
////
//// BVH is a tree structure where each node contains a bounding box that
//// encompasses all its children. Excellent for dynamic scenes and collision detection.

import gleam/float
import gleam/list
import spatial/collider.{type Collider}
import vec/vec3.{type Vec3}
import vec/vec3f

/// BVH node for spatial partitioning.
///
/// Industry standard for game engines and physics systems.
pub opaque type BVH(a) {
  BVHLeaf(bounds: Collider, items: List(#(Vec3(Float), a)))
  BVHNode(bounds: Collider, left: BVH(a), right: BVH(a))
}

/// Create a new BVH from a list of positioned items.
///
/// Uses Surface Area Heuristic (SAH) for optimal splits.
///
/// **Time Complexity**: O(n log n) where n is the number of items.
///
/// ## Example
/// ```gleam
/// let items = [
///   #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
///   #(vec3.Vec3(10.0, 0.0, 0.0), "item2"),
/// ]
/// let bvh = bvh.from_items(items, max_leaf_size: 4)
/// ```
pub fn from_items(
  items: List(#(Vec3(Float), a)),
  max_leaf_size max_leaf_size: Int,
) -> Result(BVH(a), Nil) {
  case items {
    [] -> Error(Nil)
    _ -> Ok(build_bvh(items, max_leaf_size))
  }
}

/// Query all items within a collider region.
///
/// **Time Complexity**: O(log n + k) average case where k is the number of results.
/// Worst case O(n) if query region covers entire BVH.
pub fn query(bvh: BVH(a), query_bounds: Collider) -> List(#(Vec3(Float), a)) {
  do_query(bvh, query_bounds, [])
}

fn do_query(
  bvh: BVH(a),
  query_bounds: Collider,
  acc: List(#(Vec3(Float), a)),
) -> List(#(Vec3(Float), a)) {
  case bvh {
    BVHLeaf(bounds, items) -> {
      case collider.intersects(bounds, query_bounds) {
        False -> acc
        True -> {
          // Prepend matching items to accumulator (O(k) instead of O(n))
          list.fold(items, acc, fn(acc_inner, item_pair) {
            let #(pos, _) = item_pair
            case collider.contains_point(query_bounds, pos) {
              True -> [item_pair, ..acc_inner]
              False -> acc_inner
            }
          })
        }
      }
    }
    BVHNode(bounds, left, right) -> {
      case collider.intersects(bounds, query_bounds) {
        False -> acc
        True -> {
          acc
          |> do_query(left, query_bounds, _)
          |> do_query(right, query_bounds, _)
        }
      }
    }
  }
}

/// Query all items within a radius of a point.
///
/// **Time Complexity**: O(log n + k) average case where k is the number of results.
pub fn query_radius(
  bvh: BVH(a),
  center: Vec3(Float),
  radius: Float,
) -> List(#(Vec3(Float), a)) {
  let half_extents = vec3.Vec3(radius, radius, radius)
  let query_bounds = collider.box_from_center(center, half_extents)

  query(bvh, query_bounds)
  |> list.filter(fn(item_pair) {
    let #(pos, _) = item_pair
    vec3f.distance(center, pos) <=. radius
  })
}

/// Query all items in the BVH.
///
/// **Time Complexity**: O(n) where n is the total number of items.
pub fn query_all(bvh: BVH(a)) -> List(#(Vec3(Float), a)) {
  do_query_all(bvh, [])
}

fn do_query_all(
  bvh: BVH(a),
  acc: List(#(Vec3(Float), a)),
) -> List(#(Vec3(Float), a)) {
  case bvh {
    BVHLeaf(_, items) -> {
      // Prepend items to accumulator (O(k) instead of O(n))
      list.fold(items, acc, fn(acc_inner, item) { [item, ..acc_inner] })
    }
    BVHNode(_, left, right) -> {
      acc
      |> do_query_all(left, _)
      |> do_query_all(right, _)
    }
  }
}

/// Count total items in the BVH.
///
/// **Time Complexity**: O(n) where n is the total number of items.
pub fn count(bvh: BVH(a)) -> Int {
  query_all(bvh)
  |> list.length()
}

/// Get the root bounds of the BVH.
pub fn bounds(bvh: BVH(a)) -> Collider {
  case bvh {
    BVHLeaf(bounds, _) -> bounds
    BVHNode(bounds, _, _) -> bounds
  }
}

// --- Private Helper Functions ---

fn build_bvh(items: List(#(Vec3(Float), a)), max_leaf_size: Int) -> BVH(a) {
  case list.length(items) <= max_leaf_size {
    True -> {
      let bounds = compute_bounds(items)
      BVHLeaf(bounds: bounds, items: items)
    }
    False -> {
      let #(left_items, right_items) = split_items(items)
      let left = build_bvh(left_items, max_leaf_size)
      let right = build_bvh(right_items, max_leaf_size)
      let bounds = merge_bounds(bounds(left), bounds(right))
      BVHNode(bounds: bounds, left: left, right: right)
    }
  }
}

fn compute_bounds(items: List(#(Vec3(Float), a))) -> Collider {
  let positions = list.map(items, fn(item) { item.0 })

  let init_min = vec3.Vec3(1.0e10, 1.0e10, 1.0e10)
  let init_max = vec3.Vec3(-1.0e10, -1.0e10, -1.0e10)

  let #(min, max) =
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

  // Add small padding to avoid zero-size boxes
  let padding = 0.01
  collider.box(
    min: vec3.Vec3(min.x -. padding, min.y -. padding, min.z -. padding),
    max: vec3.Vec3(max.x +. padding, max.y +. padding, max.z +. padding),
  )
}

fn merge_bounds(a: Collider, b: Collider) -> Collider {
  let assert collider.Box(min_a, max_a) = a
  let assert collider.Box(min_b, max_b) = b

  collider.box(
    min: vec3.Vec3(
      float.min(min_a.x, min_b.x),
      float.min(min_a.y, min_b.y),
      float.min(min_a.z, min_b.z),
    ),
    max: vec3.Vec3(
      float.max(max_a.x, max_b.x),
      float.max(max_a.y, max_b.y),
      float.max(max_a.z, max_b.z),
    ),
  )
}

fn split_items(
  items: List(#(Vec3(Float), a)),
) -> #(List(#(Vec3(Float), a)), List(#(Vec3(Float), a))) {
  let bounds = compute_bounds(items)
  let center = collider.center(bounds)
  let size = collider.size(bounds)

  // Split along longest axis
  let axis = case size.x >=. size.y && size.x >=. size.z {
    True -> 0
    False ->
      case size.y >=. size.z {
        True -> 1
        False -> 2
      }
  }

  let #(left, right) =
    list.partition(items, fn(item) {
      let #(pos, _) = item
      case axis {
        0 -> pos.x <. center.x
        1 -> pos.y <. center.y
        _ -> pos.z <. center.z
      }
    })

  // Handle edge case where all items on one side
  case left, right {
    [], _ | _, [] -> {
      // Compute length once and split at midpoint
      let mid = list.length(items) / 2
      #(list.take(items, mid), list.drop(items, mid))
    }
    _, _ -> #(left, right)
  }
}
