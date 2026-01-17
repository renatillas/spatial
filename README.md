# spatial

Spatial partitioning data structures for efficient 3D queries in Gleam.

[![Package Version](https://img.shields.io/hexpm/v/spatial)](https://hex.pm/packages/spatial)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/spatial/)

## Overview

This package provides high-performance spatial data structures for 3D games, simulations, and graphics applications. Efficiently query objects by position, detect collisions, and perform nearest-neighbor searches.

## Features

- **Octree**: Hierarchical tree structure that recursively divides 3D space into 8 octants
- **BVH (Bounding Volume Hierarchy)**: Industry-standard for dynamic scenes and collision detection
- **Grid**: Hash-based spatial grid for uniformly distributed objects
- **Colliders**: Box, Sphere, Capsule, and Cylinder collision volumes with intersection tests

## Installation

Add `spatial` to your Gleam project:

```sh
gleam add spatial
```

## Quick Start

```gleam
import spatial/octree
import spatial/collider
import vec/vec3

pub fn main() {
  // Create an octree for your game world
  let bounds = collider.box(
    min: vec3.Vec3(-100.0, -100.0, -100.0),
    max: vec3.Vec3(100.0, 100.0, 100.0),
  )
  let tree = octree.new(bounds, capacity: 8)
  
  // Insert entities
  let tree = octree.insert(tree, vec3.Vec3(10.0, 5.0, 0.0), "player")
  let tree = octree.insert(tree, vec3.Vec3(12.0, 5.0, 2.0), "enemy")
  
  // Query nearby entities (within 5 units of player)
  let nearby = octree.query_radius(tree, vec3.Vec3(10.0, 5.0, 0.0), 5.0)
}
```

## Data Structures

### Octree

Best for hierarchical spatial queries and non-uniform object distributions.

```gleam
import spatial/octree
import spatial/collider
import vec/vec3

let bounds = collider.box(
  min: vec3.Vec3(-100.0, -100.0, -100.0),
  max: vec3.Vec3(100.0, 100.0, 100.0),
)
let tree = octree.new(bounds, capacity: 8)
let tree = octree.insert(tree, vec3.Vec3(0.0, 0.0, 0.0), my_entity)

// Query a region
let query_bounds = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 10.0)
let results = octree.query(tree, query_bounds)

// Find nearby items
let nearby = octree.query_radius(tree, vec3.Vec3(5.0, 0.0, 0.0), 15.0)
```

**Time Complexity**:
- Insert: O(log n) average
- Query: O(log n + k) where k is results
- Radius query: O(log n + k)

### BVH (Bounding Volume Hierarchy)

Industry standard for game engines. Excellent for ray tracing and dynamic scenes.

```gleam
import spatial/bvh
import vec/vec3

let items = [
  #(vec3.Vec3(0.0, 0.0, 0.0), "item1"),
  #(vec3.Vec3(10.0, 0.0, 0.0), "item2"),
  #(vec3.Vec3(5.0, 5.0, 5.0), "item3"),
]

let assert Some(tree) = bvh.from_items(items, max_leaf_size: 4)

// Query regions
let query_bounds = collider.box(
  min: vec3.Vec3(-5.0, -5.0, -5.0),
  max: vec3.Vec3(5.0, 5.0, 5.0),
)
let results = bvh.query(tree, query_bounds)
```

**Time Complexity**:
- Build: O(n log n)
- Query: O(log n + k) average

### Grid

Fastest for uniformly distributed objects like particles, crowds, or bullets.

```gleam
import spatial/grid
import spatial/collider
import vec/vec3

let bounds = collider.box(
  min: vec3.Vec3(-100.0, -100.0, -100.0),
  max: vec3.Vec3(100.0, 100.0, 100.0),
)
let grid = grid.new(cell_size: 10.0, bounds: bounds)
let grid = grid.insert(grid, vec3.Vec3(15.0, 0.0, 0.0), "particle")

// Very fast radius queries
let nearby = grid.query_radius(grid, vec3.Vec3(10.0, 0.0, 0.0), 20.0)
```

**Time Complexity**:
- Insert: O(1) effective (O(log₃₂ n) technically)
- Query: O(c + k) where c is cells checked

### Colliders

Collision volumes for spatial queries and intersection tests.

```gleam
import spatial/collider
import vec/vec3

// Box collider
let box = collider.box(
  min: vec3.Vec3(-1.0, -1.0, -1.0),
  max: vec3.Vec3(1.0, 1.0, 1.0),
)

// Sphere collider
let sphere = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 2.5)

// Capsule (great for character controllers)
let character = collider.capsule(
  start: vec3.Vec3(0.0, 0.0, 0.0),
  end: vec3.Vec3(0.0, 2.0, 0.0),
  radius: 0.5,
)

// Cylinder
let pillar = collider.cylinder(
  center: vec3.Vec3(0.0, 5.0, 0.0),
  radius: 1.0,
  height: 10.0,
)

// Check intersections
let colliding = collider.intersects(box, sphere)

// Point containment
let contains = collider.contains_point(sphere, vec3.Vec3(1.0, 1.0, 1.0))
```

## When to Use Which?

| Structure | Best For | Performance |
|-----------|----------|-------------|
| **Octree** | Non-uniform distributions, hierarchical scenes | O(log n) queries |
| **BVH** | Ray tracing, collision detection, dynamic scenes | O(log n) queries, O(n log n) build |
| **Grid** | Uniform distributions, particles, crowds | O(1) insert/query (effective) |

## Dependencies

- [gleam_stdlib](https://hex.pm/packages/gleam_stdlib) - Gleam standard library
- [vec](https://hex.pm/packages/vec) - 3D vector math
- [quaterni](https://hex.pm/packages/quaterni) - Quaternion math for rotations

## Development

```sh
gleam test  # Run the tests
gleam build # Build the project
```

## License

This project is licensed under the MIT License.

## Links

- [Hex Package](https://hex.pm/packages/spatial)
- [Documentation](https://hexdocs.pm/spatial/)
- [Repository](https://github.com/renatillas/spatial)
