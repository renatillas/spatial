// Internal FFI functions for performance-critical operations
// JavaScript implementations for browser/Node.js targets

/**
 * Fast AABB (Box-Box) intersection test
 * Returns true if two axis-aligned bounding boxes intersect
 */
export function box_intersects(min_a, max_a, min_b, max_b) {
  return (
    min_a.x <= max_b.x &&
    max_a.x >= min_b.x &&
    min_a.y <= max_b.y &&
    max_a.y >= min_b.y &&
    min_a.z <= max_b.z &&
    max_a.z >= min_b.z
  );
}

/**
 * Fast box contains point test
 * Returns true if a point is inside an axis-aligned bounding box
 */
export function box_contains_point(min, max, point) {
  return (
    point.x >= min.x &&
    point.x <= max.x &&
    point.y >= min.y &&
    point.y <= max.y &&
    point.z >= min.z &&
    point.z <= max.z
  );
}

/**
 * Fast sphere-sphere intersection test
 */
export function sphere_intersects(center_a, radius_a, center_b, radius_b) {
  const dx = center_a.x - center_b.x;
  const dy = center_a.y - center_b.y;
  const dz = center_a.z - center_b.z;
  const dist_sq = dx * dx + dy * dy + dz * dz;
  const radius_sum = radius_a + radius_b;
  return dist_sq <= radius_sum * radius_sum;
}

/**
 * Fast distance squared calculation
 */
export function distance_squared(a, b) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  const dz = a.z - b.z;
  return dx * dx + dy * dy + dz * dz;
}

/**
 * Fast distance calculation
 */
export function distance(a, b) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  const dz = a.z - b.z;
  return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

/**
 * Compute bounding box from list of positions
 * Returns [min, max] tuple
 */
export function compute_bounds(positions) {
  // Convert Gleam list to JavaScript array
  const posArray = positions.toArray();

  if (posArray.length === 0) {
    return [
      { x: 1e10, y: 1e10, z: 1e10 },
      { x: -1e10, y: -1e10, z: -1e10 },
    ];
  }

  let min_x = posArray[0].x;
  let min_y = posArray[0].y;
  let min_z = posArray[0].z;
  let max_x = posArray[0].x;
  let max_y = posArray[0].y;
  let max_z = posArray[0].z;

  for (let i = 1; i < posArray.length; i++) {
    const pos = posArray[i];
    if (pos.x < min_x) min_x = pos.x;
    if (pos.y < min_y) min_y = pos.y;
    if (pos.z < min_z) min_z = pos.z;
    if (pos.x > max_x) max_x = pos.x;
    if (pos.y > max_y) max_y = pos.y;
    if (pos.z > max_z) max_z = pos.z;
  }

  return [
    { x: min_x, y: min_y, z: min_z },
    { x: max_x, y: max_y, z: max_z },
  ];
}

/**
 * Merge two bounding boxes
 * Returns [min, max] tuple
 */
export function merge_bounds(min_a, max_a, min_b, max_b) {
  return [
    {
      x: Math.min(min_a.x, min_b.x),
      y: Math.min(min_a.y, min_b.y),
      z: Math.min(min_a.z, min_b.z),
    },
    {
      x: Math.max(max_a.x, max_b.x),
      y: Math.max(max_a.y, max_b.y),
      z: Math.max(max_a.z, max_b.z),
    },
  ];
}
