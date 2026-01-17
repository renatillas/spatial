// Spatial Library Performance Benchmark
// Run with: gleam run -m dev/spatial_dev

import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleamy/bench
import spatial/bvh
import spatial/collider
import spatial/grid
import spatial/octree
import vec/vec3

pub fn main() {
  io.println("╔══════════════════════════════════════════════════════════════╗")
  io.println("║          Spatial Library Performance Benchmark              ║")
  io.println("╚══════════════════════════════════════════════════════════════╝")
  io.println("")

  benchmark_octree_insertion()
  benchmark_grid_insertion()
  benchmark_bvh_construction()

  io.println("\n" <> string.repeat("=", 64))
  io.println("\n🏆 PERFORMANCE SHOWDOWN: Octree vs Grid vs BVH")
  benchmark_comparison_queries()
  benchmark_collider_intersection()
}

// ============================================================================
// Benchmark 1: Octree Insertion Performance
// ============================================================================

pub fn benchmark_octree_insertion() {
  io.println("=== 1. Octree Insertion Performance ===")
  io.println("Measures: Inserting items into octree with various capacities")
  io.println("")

  bench.run(
    [
      bench.Input("10 items, cap 4", create_insertion_input(10, 4)),
      bench.Input("50 items, cap 8", create_insertion_input(50, 8)),
      bench.Input("100 items, cap 8", create_insertion_input(100, 8)),
      bench.Input("500 items, cap 8", create_insertion_input(500, 8)),
      bench.Input("1000 items, cap 8", create_insertion_input(1000, 8)),
    ],
    [
      bench.Function("insert_all", fn(input: InsertionInput) {
        list.fold(input.items, input.tree, fn(tree, item) {
          octree.insert(tree, item.0, item.1)
        })
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
  |> io.println

  io.println("\n📊 Target: >1000 ops/sec for 1000 items")
  io.println(
    "   Key optimization: Minimize list operations during subdivision\n",
  )
}

// ============================================================================
// Benchmark 2: Grid Insertion Performance
// ============================================================================

pub fn benchmark_grid_insertion() {
  io.println("=== 2. Grid Insertion Performance ===")
  io.println("Measures: O(log₃₂ n) insertion (effectively O(1)) into hash grid")
  io.println("")

  bench.run(
    [
      bench.Input("10 items", create_grid_insertion_input(10)),
      bench.Input("50 items", create_grid_insertion_input(50)),
      bench.Input("100 items", create_grid_insertion_input(100)),
      bench.Input("500 items", create_grid_insertion_input(500)),
      bench.Input("1000 items", create_grid_insertion_input(1000)),
    ],
    [
      bench.Function("insert_all", fn(input: GridInsertionInput) {
        list.fold(input.items, input.grid, fn(g, item) {
          grid.insert(g, item.0, item.1)
        })
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
  |> io.println

  io.println(
    "\n📊 Expected: 5-10x faster than octree for uniform distributions\n",
  )
}

// ============================================================================
// Benchmark 3: BVH Construction Performance
// ============================================================================

pub fn benchmark_bvh_construction() {
  io.println("=== 3. BVH Construction Performance ===")
  io.println("Measures: Building BVH from item list")
  io.println("")

  bench.run(
    [
      bench.Input("10 items", create_bvh_items(10)),
      bench.Input("50 items", create_bvh_items(50)),
      bench.Input("100 items", create_bvh_items(100)),
      bench.Input("500 items", create_bvh_items(500)),
      bench.Input("1000 items", create_bvh_items(1000)),
    ],
    [
      bench.Function("from_items", fn(items: List(#(vec3.Vec3(Float), String))) {
        bvh.from_items(items, max_leaf_size: 8)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
  |> io.println

  io.println(
    "\n📊 Expected: Slower construction but faster queries for dynamic scenes\n",
  )
}

// ============================================================================
// Benchmark 4: Query Performance Comparison
// ============================================================================

pub fn benchmark_comparison_queries() {
  io.println("=== 4. Query Performance Comparison ===")
  io.println("Measures: Radius queries across all three structures")
  io.println("")

  let items = create_bvh_items(500)
  let octree_data = create_octree_from_items(items)
  let grid_data = create_grid_from_items(items)
  let assert option.Some(bvh_data) = bvh.from_items(items, max_leaf_size: 8)

  bench.run(
    [
      bench.Input("Octree", OctreeQueryData(octree_data)),
      bench.Input("Grid", GridQueryData(grid_data)),
      bench.Input("BVH", BVHQueryData(bvh_data)),
    ],
    [
      bench.Function("query_radius_r5", fn(data) {
        case data {
          OctreeQueryData(tree) ->
            octree.query_radius(tree, vec3.Vec3(0.0, 0.0, 0.0), 5.0)
          GridQueryData(g) ->
            grid.query_radius(g, vec3.Vec3(0.0, 0.0, 0.0), 5.0)
          BVHQueryData(b) -> bvh.query_radius(b, vec3.Vec3(0.0, 0.0, 0.0), 5.0)
        }
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
  |> io.println

  io.println("\n📊 Grid should be fastest for uniform distributions!")
  io.println("   BVH should be competitive with octree\n")
}

// ============================================================================
// Benchmark 5: Octree Query Performance (Original)
// ============================================================================

pub fn benchmark_octree_query() {
  io.println("=== 5. Octree Query Performance ===")
  io.println("Measures: Querying regions in populated octrees")
  io.println("")

  bench.run(
    [
      bench.Input("100 items, small query", create_query_input(100, 10.0)),
      bench.Input("100 items, medium query", create_query_input(100, 50.0)),
      bench.Input("100 items, large query", create_query_input(100, 150.0)),
      bench.Input("500 items, small query", create_query_input(500, 10.0)),
      bench.Input("500 items, medium query", create_query_input(500, 50.0)),
      bench.Input("1000 items, small query", create_query_input(1000, 10.0)),
    ],
    [
      bench.Function("query", fn(input: QueryInput) {
        octree.query(input.tree, input.query_bounds)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
  |> io.println

  io.println("\n📊 Target: >10,000 ops/sec for small queries")
  io.println("   Key optimization: Early exit on non-intersecting nodes\n")
}

// ============================================================================
// Benchmark 3: Octree Radius Query Performance
// ============================================================================

pub fn benchmark_octree_query_radius() {
  io.println("=== 3. Octree Radius Query Performance ===")
  io.println("Measures: Finding items within radius (common game operation)")
  io.println("")

  bench.run(
    [
      bench.Input("100 items, r=5", create_radius_query_input(100, 5.0)),
      bench.Input("100 items, r=20", create_radius_query_input(100, 20.0)),
      bench.Input("500 items, r=5", create_radius_query_input(500, 5.0)),
      bench.Input("500 items, r=20", create_radius_query_input(500, 20.0)),
      bench.Input("1000 items, r=5", create_radius_query_input(1000, 5.0)),
    ],
    [
      bench.Function("query_radius", fn(input: RadiusQueryInput) {
        octree.query_radius(input.tree, input.center, input.radius)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
  |> io.println

  io.println("\n📊 Target: >5000 ops/sec for small radius queries")
  io.println("   Key optimization: Sphere culling before distance checks\n")
}

// ============================================================================
// Benchmark 4: Collider Intersection Tests
// ============================================================================

pub fn benchmark_collider_intersection() {
  io.println("=== 4. Collider Intersection Tests ===")
  io.println("Measures: Various collider intersection checks")
  io.println("")

  let box1 =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  let box2 =
    collider.box(min: vec3.Vec3(0.5, 0.5, 0.5), max: vec3.Vec3(2.0, 2.0, 2.0))
  let sphere1 = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 1.0)
  let sphere2 = collider.sphere(center: vec3.Vec3(1.5, 0.0, 0.0), radius: 1.0)

  bench.run(
    [
      bench.Input("Box-Box", #(box1, box2)),
      bench.Input("Sphere-Sphere", #(sphere1, sphere2)),
      bench.Input("Box-Sphere", #(box1, sphere1)),
    ],
    [
      bench.Function(
        "intersects",
        fn(pair: #(collider.Collider, collider.Collider)) {
          collider.intersects(pair.0, pair.1)
        },
      ),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
  |> io.println

  io.println("\n📊 Target: >100,000 ops/sec for all intersection types")
  io.println("   These are fundamental operations, must be extremely fast\n")
}

// ============================================================================
// Helper Types & Functions
// ============================================================================

pub type InsertionInput {
  InsertionInput(
    tree: octree.Octree(String),
    items: List(#(vec3.Vec3(Float), String)),
  )
}

pub type GridInsertionInput {
  GridInsertionInput(
    grid: grid.Grid(String),
    items: List(#(vec3.Vec3(Float), String)),
  )
}

pub type QueryInput {
  QueryInput(tree: octree.Octree(String), query_bounds: collider.Collider)
}

pub type RadiusQueryInput {
  RadiusQueryInput(
    tree: octree.Octree(String),
    center: vec3.Vec3(Float),
    radius: Float,
  )
}

pub type QueryData {
  OctreeQueryData(octree.Octree(String))
  GridQueryData(grid.Grid(String))
  BVHQueryData(bvh.BVH(String))
}

fn create_insertion_input(count: Int, capacity: Int) -> InsertionInput {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let tree = octree.new(bounds, capacity)

  let items =
    list.range(0, count - 1)
    |> list.map(fn(i) {
      let x = { int.to_float(i % 20) -. 10.0 } *. 8.0
      let y = { int.to_float({ i / 20 } % 20) -. 10.0 } *. 8.0
      let z = { int.to_float(i / 400) -. 10.0 } *. 8.0
      #(vec3.Vec3(x, y, z), "item_" <> int.to_string(i))
    })

  InsertionInput(tree: tree, items: items)
}

fn create_query_input(count: Int, query_size: Float) -> QueryInput {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let tree =
    list.range(0, count - 1)
    |> list.fold(octree.new(bounds, 8), fn(tree, i) {
      let x = { int.to_float(i % 20) -. 10.0 } *. 8.0
      let y = { int.to_float({ i / 20 } % 20) -. 10.0 } *. 8.0
      let z = { int.to_float(i / 400) -. 10.0 } *. 8.0
      octree.insert(tree, vec3.Vec3(x, y, z), "item_" <> int.to_string(i))
    })

  let query_bounds =
    collider.box(
      min: vec3.Vec3(0.0 -. query_size, 0.0 -. query_size, 0.0 -. query_size),
      max: vec3.Vec3(query_size, query_size, query_size),
    )

  QueryInput(tree: tree, query_bounds: query_bounds)
}

fn create_radius_query_input(count: Int, radius: Float) -> RadiusQueryInput {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let tree =
    list.range(0, count - 1)
    |> list.fold(octree.new(bounds, 8), fn(tree, i) {
      let x = { int.to_float(i % 20) -. 10.0 } *. 8.0
      let y = { int.to_float({ i / 20 } % 20) -. 10.0 } *. 8.0
      let z = { int.to_float(i / 400) -. 10.0 } *. 8.0
      octree.insert(tree, vec3.Vec3(x, y, z), "item_" <> int.to_string(i))
    })

  RadiusQueryInput(tree: tree, center: vec3.Vec3(0.0, 0.0, 0.0), radius: radius)
}

fn create_bvh_items(count: Int) -> List(#(vec3.Vec3(Float), String)) {
  list.range(0, count - 1)
  |> list.map(fn(i) {
    let x = { int.to_float(i % 20) -. 10.0 } *. 8.0
    let y = { int.to_float({ i / 20 } % 20) -. 10.0 } *. 8.0
    let z = { int.to_float(i / 400) -. 10.0 } *. 8.0
    #(vec3.Vec3(x, y, z), "item_" <> int.to_string(i))
  })
}

fn create_grid_insertion_input(count: Int) -> GridInsertionInput {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let items = create_bvh_items(count)
  GridInsertionInput(grid: g, items: items)
}

fn create_octree_from_items(
  items: List(#(vec3.Vec3(Float), String)),
) -> octree.Octree(String) {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  list.fold(items, octree.new(bounds, 8), fn(tree, item) {
    octree.insert(tree, item.0, item.1)
  })
}

fn create_grid_from_items(
  items: List(#(vec3.Vec3(Float), String)),
) -> grid.Grid(String) {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  list.fold(items, grid.new(cell_size: 10.0, bounds: bounds), fn(g, item) {
    grid.insert(g, item.0, item.1)
  })
}

import gleam/string
