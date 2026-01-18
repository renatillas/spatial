// Comprehensive benchmarks for all critical spatial functions
// Run with: gleam run -m comprehensive_benchmarks

import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleamy/bench
import simplifile
import spatial/bvh
import spatial/collider
import spatial/grid
import spatial/octree
import vec/vec3

pub fn main() {
  io.println("╔══════════════════════════════════════════════════════════════╗")
  io.println("║     Spatial Library Comprehensive Benchmark Suite           ║")
  io.println("╚══════════════════════════════════════════════════════════════╝")
  io.println("")

  // Run all benchmarks and collect their output strings
  let octree_output = run_octree_benchmarks()
  let grid_output = run_grid_benchmarks()
  let bvh_output = run_bvh_benchmarks()
  let collider_output = run_collider_benchmarks()

  // Combine all outputs
  let full_output =
    string.join(
      [
        "╔══════════════════════════════════════════════════════════════╗",
        "║     Spatial Library Comprehensive Benchmark Results         ║",
        "╚══════════════════════════════════════════════════════════════╝",
        "",
        "Target: erlang",
        "",
        octree_output,
        grid_output,
        bvh_output,
        collider_output,
      ],
      "\n",
    )

  // Save the full text output
  let _ = simplifile.create_directory_all("dist/benchmarks")

  case simplifile.write("dist/benchmarks/latest_results.txt", full_output) {
    Ok(_) ->
      io.println("\n✅ Results saved to: dist/benchmarks/latest_results.txt")
    Error(_) -> io.println("\n❌ Failed to save results")
  }

  io.println("\n🎉 All benchmarks complete!")
}

// ============================================================================
// Octree Benchmarks
// ============================================================================

fn run_octree_benchmarks() -> String {
  io.println("\n=== Octree Benchmarks ===\n")

  let output1 = benchmark_octree_insert()
  let output2 = benchmark_octree_remove()
  let output3 = benchmark_octree_query()
  let output4 = benchmark_octree_query_radius()
  let output5 = benchmark_octree_query_all()

  string.join(
    [
      "=== Octree Benchmarks ===\n",
      output1,
      "\n",
      output2,
      "\n",
      output3,
      "\n",
      output4,
      "\n",
      output5,
    ],
    "",
  )
}

fn benchmark_octree_insert() -> String {
  io.println("Octree: Insert operations...")

  bench.run(
    [
      bench.Input("100 items", create_insertion_input(100, 8)),
      bench.Input("500 items", create_insertion_input(500, 8)),
      bench.Input("1000 items", create_insertion_input(1000, 8)),
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
}

fn benchmark_octree_remove() -> String {
  io.println("Octree: Remove operations...")

  bench.run(
    [
      bench.Input("100 items", create_populated_octree(100)),
      bench.Input("500 items", create_populated_octree(500)),
    ],
    [
      bench.Function("remove_first", fn(tree: octree.Octree(String)) {
        octree.remove(tree, vec3.Vec3(0.0, 0.0, 0.0), fn(_) { True })
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_octree_query() -> String {
  io.println("Octree: Query operations...")

  bench.run(
    [
      bench.Input("100 items, small", create_query_input(100, 10.0)),
      bench.Input("500 items, small", create_query_input(500, 10.0)),
      bench.Input("500 items, large", create_query_input(500, 50.0)),
    ],
    [
      bench.Function("query", fn(input: QueryInput) {
        octree.query(input.tree, input.query_bounds)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_octree_query_radius() -> String {
  io.println("Octree: Query radius operations...")

  bench.run(
    [
      bench.Input("100 items, r=5", create_radius_query_input(100, 5.0)),
      bench.Input("500 items, r=5", create_radius_query_input(500, 5.0)),
      bench.Input("500 items, r=20", create_radius_query_input(500, 20.0)),
    ],
    [
      bench.Function("query_radius", fn(input: RadiusQueryInput) {
        octree.query_radius(input.tree, input.center, input.radius)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_octree_query_all() -> String {
  io.println("Octree: Query all operations...")

  bench.run(
    [
      bench.Input("100 items", create_populated_octree(100)),
      bench.Input("500 items", create_populated_octree(500)),
      bench.Input("1000 items", create_populated_octree(1000)),
    ],
    [
      bench.Function("query_all", fn(tree: octree.Octree(String)) {
        octree.query_all(tree)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

// ============================================================================
// Grid Benchmarks
// ============================================================================

fn run_grid_benchmarks() -> String {
  io.println("\n=== Grid Benchmarks ===\n")

  let output1 = benchmark_grid_insert()
  let output2 = benchmark_grid_remove()
  let output3 = benchmark_grid_query()
  let output4 = benchmark_grid_query_radius()
  let output5 = benchmark_grid_query_all()

  string.join(
    [
      "=== Grid Benchmarks ===\n",
      output1,
      "\n",
      output2,
      "\n",
      output3,
      "\n",
      output4,
      "\n",
      output5,
    ],
    "",
  )
}

fn benchmark_grid_insert() -> String {
  io.println("Grid: Insert operations...")

  bench.run(
    [
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
}

fn benchmark_grid_remove() -> String {
  io.println("Grid: Remove operations...")

  bench.run(
    [
      bench.Input("100 items", create_populated_grid(100)),
      bench.Input("500 items", create_populated_grid(500)),
    ],
    [
      bench.Function("remove_first", fn(g: grid.Grid(String)) {
        grid.remove(g, vec3.Vec3(0.0, 0.0, 0.0), fn(_) { True })
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_grid_query() -> String {
  io.println("Grid: Query operations...")

  bench.run(
    [
      bench.Input("100 items, small", create_grid_query_input(100, 10.0)),
      bench.Input("500 items, small", create_grid_query_input(500, 10.0)),
      bench.Input("500 items, large", create_grid_query_input(500, 50.0)),
    ],
    [
      bench.Function("query", fn(input: GridQueryInput) {
        grid.query(input.grid, input.query_bounds)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_grid_query_radius() -> String {
  io.println("Grid: Query radius operations...")

  bench.run(
    [
      bench.Input("100 items, r=5", create_grid_radius_query_input(100, 5.0)),
      bench.Input("500 items, r=5", create_grid_radius_query_input(500, 5.0)),
      bench.Input("500 items, r=20", create_grid_radius_query_input(500, 20.0)),
    ],
    [
      bench.Function("query_radius", fn(input: GridRadiusQueryInput) {
        grid.query_radius(input.grid, input.center, input.radius)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_grid_query_all() -> String {
  io.println("Grid: Query all operations...")

  bench.run(
    [
      bench.Input("100 items", create_populated_grid(100)),
      bench.Input("500 items", create_populated_grid(500)),
      bench.Input("1000 items", create_populated_grid(1000)),
    ],
    [
      bench.Function("query_all", fn(g: grid.Grid(String)) { grid.query_all(g) }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

// ============================================================================
// BVH Benchmarks
// ============================================================================

fn run_bvh_benchmarks() -> String {
  io.println("\n=== BVH Benchmarks ===\n")

  let output1 = benchmark_bvh_construction()
  let output2 = benchmark_bvh_insert()
  let output3 = benchmark_bvh_remove()
  let output4 = benchmark_bvh_update()
  let output5 = benchmark_bvh_refit()
  let output6 = benchmark_bvh_query()
  let output7 = benchmark_bvh_query_radius()
  let output8 = benchmark_bvh_query_all()

  string.join(
    [
      "=== BVH Benchmarks ===\n",
      output1,
      "\n",
      output2,
      "\n",
      output3,
      "\n",
      output4,
      "\n",
      output5,
      "\n",
      output6,
      "\n",
      output7,
      "\n",
      output8,
    ],
    "",
  )
}

fn benchmark_bvh_construction() -> String {
  io.println("BVH: Construction operations...")

  bench.run(
    [
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
}

fn benchmark_bvh_insert() -> String {
  io.println("BVH: Insert operations...")

  bench.run(
    [
      bench.Input("100 items", create_populated_bvh(100)),
      bench.Input("500 items", create_populated_bvh(500)),
    ],
    [
      bench.Function("insert", fn(b: bvh.BVH(String)) {
        bvh.insert(b, vec3.Vec3(50.0, 50.0, 50.0), "new_item", max_leaf_size: 8)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_bvh_remove() -> String {
  io.println("BVH: Remove operations...")

  bench.run(
    [
      bench.Input("100 items", create_populated_bvh(100)),
      bench.Input("500 items", create_populated_bvh(500)),
    ],
    [
      bench.Function("remove", fn(b: bvh.BVH(String)) {
        bvh.remove(b, fn(item) { item == "item_0" })
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_bvh_update() -> String {
  io.println("BVH: Update operations...")

  bench.run(
    [
      bench.Input("100 items", create_populated_bvh(100)),
      bench.Input("500 items", create_populated_bvh(500)),
    ],
    [
      bench.Function("update", fn(b: bvh.BVH(String)) {
        bvh.update(
          b,
          fn(item) { item == "item_0" },
          vec3.Vec3(100.0, 100.0, 100.0),
          "item_0",
          max_leaf_size: 8,
        )
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_bvh_refit() -> String {
  io.println("BVH: Refit operations...")

  bench.run(
    [
      bench.Input("100 items", create_populated_bvh(100)),
      bench.Input("500 items", create_populated_bvh(500)),
      bench.Input("1000 items", create_populated_bvh(1000)),
    ],
    [
      bench.Function("refit", fn(b: bvh.BVH(String)) { bvh.refit(b) }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_bvh_query() -> String {
  io.println("BVH: Query operations...")

  bench.run(
    [
      bench.Input("100 items, small", create_bvh_query_input(100, 10.0)),
      bench.Input("500 items, small", create_bvh_query_input(500, 10.0)),
      bench.Input("500 items, large", create_bvh_query_input(500, 50.0)),
    ],
    [
      bench.Function("query", fn(input: BVHQueryInput) {
        bvh.query(input.bvh, input.query_bounds)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_bvh_query_radius() -> String {
  io.println("BVH: Query radius operations...")

  bench.run(
    [
      bench.Input("100 items, r=5", create_bvh_radius_query_input(100, 5.0)),
      bench.Input("500 items, r=5", create_bvh_radius_query_input(500, 5.0)),
      bench.Input("500 items, r=20", create_bvh_radius_query_input(500, 20.0)),
    ],
    [
      bench.Function("query_radius", fn(input: BVHRadiusQueryInput) {
        bvh.query_radius(input.bvh, input.center, input.radius)
      }),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

fn benchmark_bvh_query_all() -> String {
  io.println("BVH: Query all operations...")

  let bvh_100 = create_populated_bvh(100)
  let bvh_500 = create_populated_bvh(500)
  let bvh_1000 = create_populated_bvh(1000)

  bench.run(
    [
      bench.Input("100 items", bvh_100),
      bench.Input("500 items", bvh_500),
      bench.Input("1000 items", bvh_1000),
    ],
    [bench.Function("query_all", fn(b: bvh.BVH(String)) { bvh.query_all(b) })],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
}

// ============================================================================
// Collider Benchmarks
// ============================================================================

fn run_collider_benchmarks() -> String {
  io.println("\n=== Collider Benchmarks ===\n")

  let output1 = benchmark_collider_intersects()
  let output2 = benchmark_collider_contains_point()

  string.join(["=== Collider Benchmarks ===\n", output1, "\n", output2], "")
}

fn benchmark_collider_intersects() -> String {
  io.println("Collider: Intersection tests...")

  let box1 =
    collider.box(
      min: vec3.Vec3(-1.0, -1.0, -1.0),
      max: vec3.Vec3(1.0, 1.0, 1.0),
    )
  let box2 =
    collider.box(min: vec3.Vec3(0.5, 0.5, 0.5), max: vec3.Vec3(2.0, 2.0, 2.0))
  let sphere1 = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 1.0)
  let sphere2 = collider.sphere(center: vec3.Vec3(1.5, 0.0, 0.0), radius: 1.0)
  let capsule1 =
    collider.capsule(
      start: vec3.Vec3(0.0, 0.0, 0.0),
      end: vec3.Vec3(0.0, 2.0, 0.0),
      radius: 0.5,
    )

  bench.run(
    [
      bench.Input("Box-Box", #(box1, box2)),
      bench.Input("Sphere-Sphere", #(sphere1, sphere2)),
      bench.Input("Box-Sphere", #(box1, sphere1)),
      bench.Input("Sphere-Capsule", #(sphere1, capsule1)),
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
}

fn benchmark_collider_contains_point() -> String {
  io.println("Collider: Contains point tests...")

  let box1 =
    collider.box(
      min: vec3.Vec3(-10.0, -10.0, -10.0),
      max: vec3.Vec3(10.0, 10.0, 10.0),
    )
  let sphere1 = collider.sphere(center: vec3.Vec3(0.0, 0.0, 0.0), radius: 10.0)
  let point = vec3.Vec3(5.0, 5.0, 5.0)

  bench.run(
    [
      bench.Input("Box", #(box1, point)),
      bench.Input("Sphere", #(sphere1, point)),
    ],
    [
      bench.Function(
        "contains_point",
        fn(pair: #(collider.Collider, vec3.Vec3(Float))) {
          collider.contains_point(pair.0, pair.1)
        },
      ),
    ],
    [bench.Duration(1000), bench.Warmup(100)],
  )
  |> bench.table([bench.IPS, bench.Min, bench.Mean, bench.Max])
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

pub type GridQueryInput {
  GridQueryInput(grid: grid.Grid(String), query_bounds: collider.Collider)
}

pub type GridRadiusQueryInput {
  GridRadiusQueryInput(
    grid: grid.Grid(String),
    center: vec3.Vec3(Float),
    radius: Float,
  )
}

pub type BVHQueryInput {
  BVHQueryInput(bvh: bvh.BVH(String), query_bounds: collider.Collider)
}

pub type BVHRadiusQueryInput {
  BVHRadiusQueryInput(
    bvh: bvh.BVH(String),
    center: vec3.Vec3(Float),
    radius: Float,
  )
}

fn create_insertion_input(count: Int, capacity: Int) -> InsertionInput {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let tree = octree.new(bounds, capacity)
  let items = create_items(count)
  InsertionInput(tree: tree, items: items)
}

fn create_grid_insertion_input(count: Int) -> GridInsertionInput {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let g = grid.new(cell_size: 10.0, bounds: bounds)
  let items = create_items(count)
  GridInsertionInput(grid: g, items: items)
}

fn create_populated_octree(count: Int) -> octree.Octree(String) {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let items = create_items(count)
  list.fold(items, octree.new(bounds, 8), fn(tree, item) {
    octree.insert(tree, item.0, item.1)
  })
}

fn create_populated_grid(count: Int) -> grid.Grid(String) {
  let bounds =
    collider.box(
      min: vec3.Vec3(-100.0, -100.0, -100.0),
      max: vec3.Vec3(100.0, 100.0, 100.0),
    )
  let items = create_items(count)
  list.fold(items, grid.new(cell_size: 10.0, bounds: bounds), fn(g, item) {
    grid.insert(g, item.0, item.1)
  })
}

fn create_populated_bvh(count: Int) -> bvh.BVH(String) {
  let items = create_items(count)
  let assert Ok(b) = bvh.from_items(items, max_leaf_size: 8)
  b
}

fn create_query_input(count: Int, query_size: Float) -> QueryInput {
  let tree = create_populated_octree(count)
  let query_bounds =
    collider.box(
      min: vec3.Vec3(0.0 -. query_size, 0.0 -. query_size, 0.0 -. query_size),
      max: vec3.Vec3(query_size, query_size, query_size),
    )
  QueryInput(tree: tree, query_bounds: query_bounds)
}

fn create_radius_query_input(count: Int, radius: Float) -> RadiusQueryInput {
  let tree = create_populated_octree(count)
  RadiusQueryInput(tree: tree, center: vec3.Vec3(0.0, 0.0, 0.0), radius: radius)
}

fn create_grid_query_input(count: Int, query_size: Float) -> GridQueryInput {
  let g = create_populated_grid(count)
  let query_bounds =
    collider.box(
      min: vec3.Vec3(0.0 -. query_size, 0.0 -. query_size, 0.0 -. query_size),
      max: vec3.Vec3(query_size, query_size, query_size),
    )
  GridQueryInput(grid: g, query_bounds: query_bounds)
}

fn create_grid_radius_query_input(
  count: Int,
  radius: Float,
) -> GridRadiusQueryInput {
  let g = create_populated_grid(count)
  GridRadiusQueryInput(
    grid: g,
    center: vec3.Vec3(0.0, 0.0, 0.0),
    radius: radius,
  )
}

fn create_bvh_query_input(count: Int, query_size: Float) -> BVHQueryInput {
  let b = create_populated_bvh(count)
  let query_bounds =
    collider.box(
      min: vec3.Vec3(0.0 -. query_size, 0.0 -. query_size, 0.0 -. query_size),
      max: vec3.Vec3(query_size, query_size, query_size),
    )
  BVHQueryInput(bvh: b, query_bounds: query_bounds)
}

fn create_bvh_radius_query_input(
  count: Int,
  radius: Float,
) -> BVHRadiusQueryInput {
  let b = create_populated_bvh(count)
  BVHRadiusQueryInput(bvh: b, center: vec3.Vec3(0.0, 0.0, 0.0), radius: radius)
}

fn create_items(count: Int) -> List(#(vec3.Vec3(Float), String)) {
  list.range(0, count - 1)
  |> list.map(fn(i) {
    let x = { int.to_float(i % 20) -. 10.0 } *. 8.0
    let y = { int.to_float({ i / 20 } % 20) -. 10.0 } *. 8.0
    let z = { int.to_float(i / 400) -. 10.0 } *. 8.0
    #(vec3.Vec3(x, y, z), "item_" <> int.to_string(i))
  })
}

fn create_bvh_items(count: Int) -> List(#(vec3.Vec3(Float), String)) {
  create_items(count)
}
