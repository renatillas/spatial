//// Bounding Volume Hierarchy (BVH) for efficient spatial queries.
////
//// BVH is a tree structure where each node contains a bounding box that
//// encompasses all its children. Excellent for dynamic scenes and collision detection.

import gleam/list
import spatial/collider.{type Collider}
import spatial/internal/ffi
import vec/vec3.{type Vec3}

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

  // Use distance_squared for better performance
  let radius_sq = radius *. radius
  query(bvh, query_bounds)
  |> list.filter(fn(item_pair) {
    let #(pos, _) = item_pair
    ffi.distance_squared(center, pos) <=. radius_sq
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

/// Insert a new item into the BVH.
///
/// Uses Surface Area Heuristic (SAH) to find the best insertion point.
/// Returns a new BVH with the item inserted.
///
/// **Time Complexity**: O(log n) average case.
///
/// ## Example
/// ```gleam
/// let bvh = bvh.from_items([#(vec3.Vec3(0.0, 0.0, 0.0), "item1")], max_leaf_size: 4)
/// let updated_bvh = bvh.insert(bvh, vec3.Vec3(1.0, 0.0, 0.0), "item2", max_leaf_size: 4)
/// ```
pub fn insert(
  bvh: BVH(a),
  position: Vec3(Float),
  item: a,
  max_leaf_size max_leaf_size: Int,
) -> BVH(a) {
  do_insert(bvh, #(position, item), max_leaf_size)
}

fn do_insert(bvh: BVH(a), item: #(Vec3(Float), a), max_leaf_size: Int) -> BVH(a) {
  case bvh {
    BVHLeaf(leaf_bounds, items) -> {
      let new_items = [item, ..items]
      case list.length(new_items) <= max_leaf_size {
        True -> {
          // Still within max_leaf_size, just expand bounds
          let new_bounds = expand_bounds(leaf_bounds, item.0)
          BVHLeaf(bounds: new_bounds, items: new_items)
        }
        False -> {
          // Need to split the leaf
          let #(left_items, right_items) = split_items(new_items)
          let left = build_bvh(left_items, max_leaf_size)
          let right = build_bvh(right_items, max_leaf_size)
          let new_bounds = merge_bounds(bounds(left), bounds(right))
          BVHNode(bounds: new_bounds, left: left, right: right)
        }
      }
    }
    BVHNode(_node_bounds, left, right) -> {
      // Choose which subtree to insert into based on Surface Area Heuristic
      let left_bounds = bounds(left)
      let right_bounds = bounds(right)

      let left_expanded = expand_bounds(left_bounds, item.0)
      let right_expanded = expand_bounds(right_bounds, item.0)

      let left_cost = surface_area(left_expanded)
      let right_cost = surface_area(right_expanded)

      case left_cost <=. right_cost {
        True -> {
          let new_left = do_insert(left, item, max_leaf_size)
          let new_bounds = merge_bounds(bounds(new_left), right_bounds)
          BVHNode(bounds: new_bounds, left: new_left, right: right)
        }
        False -> {
          let new_right = do_insert(right, item, max_leaf_size)
          let new_bounds = merge_bounds(left_bounds, bounds(new_right))
          BVHNode(bounds: new_bounds, left: left, right: new_right)
        }
      }
    }
  }
}

/// Remove an item from the BVH by comparing values using equality.
///
/// Returns a new BVH with the item removed, or the original BVH if not found.
///
/// **Time Complexity**: O(n) worst case (must search all leaves).
///
/// ## Example
/// ```gleam
/// let bvh = bvh.from_items([...], max_leaf_size: 4)
/// let updated_bvh = bvh.remove(bvh, fn(item) { item == "item_to_remove" })
/// ```
pub fn remove(bvh: BVH(a), predicate: fn(a) -> Bool) -> Result(BVH(a), Nil) {
  do_remove(bvh, predicate)
}

fn do_remove(bvh: BVH(a), predicate: fn(a) -> Bool) -> Result(BVH(a), Nil) {
  case bvh {
    BVHLeaf(_bounds, items) -> {
      let new_items =
        list.filter(items, fn(item_pair) {
          let #(_, item) = item_pair
          !predicate(item)
        })

      case new_items {
        [] -> Error(Nil)
        _ -> {
          // Check if anything was actually removed
          case list.length(new_items) == list.length(items) {
            True -> Error(Nil)
            // Nothing was removed
            False -> {
              let new_bounds = compute_bounds(new_items)
              Ok(BVHLeaf(bounds: new_bounds, items: new_items))
            }
          }
        }
      }
    }
    BVHNode(_, left, right) -> {
      // Try removing from left
      case do_remove(left, predicate) {
        Ok(new_left) -> {
          // Successfully removed from left
          let new_bounds = merge_bounds(bounds(new_left), bounds(right))
          Ok(BVHNode(bounds: new_bounds, left: new_left, right: right))
        }
        Error(Nil) -> {
          // Not in left, try right
          case do_remove(right, predicate) {
            Ok(new_right) -> {
              let new_bounds = merge_bounds(bounds(left), bounds(new_right))
              Ok(BVHNode(bounds: new_bounds, left: left, right: new_right))
            }
            Error(Nil) -> Error(Nil)
          }
        }
      }
    }
  }
}

/// Update an item's position in the BVH.
///
/// This is equivalent to removing the old item and inserting it at the new position.
///
/// **Time Complexity**: O(n + log n) = O(n) due to removal requiring search.
///
/// ## Example
/// ```gleam
/// let bvh = bvh.from_items([...], max_leaf_size: 4)
/// let updated_bvh = bvh.update(
///   bvh,
///   fn(item) { item.id == target_id },
///   new_position,
///   updated_item,
///   max_leaf_size: 4
/// )
/// ```
pub fn update(
  bvh: BVH(a),
  predicate: fn(a) -> Bool,
  new_position: Vec3(Float),
  new_item: a,
  max_leaf_size max_leaf_size: Int,
) -> Result(BVH(a), Nil) {
  case remove(bvh, predicate) {
    Ok(bvh_after_remove) ->
      Ok(insert(bvh_after_remove, new_position, new_item, max_leaf_size))
    Error(Nil) -> Error(Nil)
  }
}

/// Refit the BVH bounds after items have been modified.
///
/// This is cheaper than rebuilding but doesn't optimize the tree structure.
/// Use this when items haven't moved much, or rebuild when structure degrades.
///
/// **Time Complexity**: O(n) where n is the number of nodes.
///
/// ## Example
/// ```gleam
/// let refitted_bvh = bvh.refit(bvh)
/// ```
pub fn refit(bvh: BVH(a)) -> BVH(a) {
  case bvh {
    BVHLeaf(_, items) -> {
      let new_bounds = compute_bounds(items)
      BVHLeaf(bounds: new_bounds, items: items)
    }
    BVHNode(_, left, right) -> {
      let new_left = refit(left)
      let new_right = refit(right)
      let new_bounds = merge_bounds(bounds(new_left), bounds(new_right))
      BVHNode(bounds: new_bounds, left: new_left, right: new_right)
    }
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

  // Use FFI for fast bounds computation
  let #(min, max) = ffi.compute_bounds(positions)

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

  // Use FFI for fast bounds merging
  let #(min, max) = ffi.merge_bounds(min_a, max_a, min_b, max_b)
  collider.box(min: min, max: max)
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

fn expand_bounds(bounds: Collider, point: Vec3(Float)) -> Collider {
  let assert collider.Box(min, max) = bounds

  let new_min =
    vec3.Vec3(
      case point.x <. min.x {
        True -> point.x
        False -> min.x
      },
      case point.y <. min.y {
        True -> point.y
        False -> min.y
      },
      case point.z <. min.z {
        True -> point.z
        False -> min.z
      },
    )

  let new_max =
    vec3.Vec3(
      case point.x >. max.x {
        True -> point.x
        False -> max.x
      },
      case point.y >. max.y {
        True -> point.y
        False -> max.y
      },
      case point.z >. max.z {
        True -> point.z
        False -> max.z
      },
    )

  // Add padding to avoid zero-size boxes
  let padding = 0.01
  collider.box(
    min: vec3.Vec3(
      new_min.x -. padding,
      new_min.y -. padding,
      new_min.z -. padding,
    ),
    max: vec3.Vec3(
      new_max.x +. padding,
      new_max.y +. padding,
      new_max.z +. padding,
    ),
  )
}

fn surface_area(bounds: Collider) -> Float {
  let size = collider.size(bounds)
  // Surface area of a box: 2 * (w*h + w*d + h*d)
  2.0 *. { size.x *. size.y +. size.x *. size.z +. size.y *. size.z }
}
