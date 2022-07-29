//
//  Geom.swift
//  MetalTest
//
//  Created by Marcel on 21/07/2022.
//

import Foundation

import UIKit


// The closest point on a line is the scalar projection
let closest_point_on_line = scalar_projection

func closest_point_on_line_segment(_ p: CGVector, _ a: CGVector, _ b: CGVector) -> CGVector {
  let atob = b - a
  let atop = p - a
  
  let len = atob.dx * atob.dx + atob.dy * atob.dy
  var dot = atop.dx * atob.dx + atop.dy * atob.dy
  
  let t = min( 1, max( 0, dot / len ) )

  dot = ( b.dx - a.dx ) * ( p.dy - a.dy ) - ( b.dy - a.dy ) * ( p.dx - a.dx )
    
  return CGVector(dx: a.dx + atob.dx * t,  dy: a.dy + atob.dy * t)
}


func closest_point_in_collection(points: [CGVector], point: CGVector, min_dist: CGFloat = 100) -> Int {
  var closest_distance = min_dist
  var closest_index = -1
  for (i, pt) in points.enumerated() {
    let d = distance(pt, point)
    
    if d < closest_distance {
      closest_distance = d
      closest_index = i
    }
  }
  
  return closest_index
}

func closest_line_in_collection(lines: [(CGVector, CGVector)], point: CGVector, min_dist: CGFloat = 100) -> Int {
  var closest_distance = min_dist
  var closest_index = -1
  for (i, line) in lines.enumerated() {
    let pt = closest_point_on_line_segment(point, line.0, line.1)
    let d = distance(pt, point)
    
    if d < closest_distance {
      closest_distance = d
      closest_index = i
    }
  }
  
  return closest_index
}

func closest_point_on_curve(line: [CGVector], point: CGVector, min_dist: CGFloat = 100) -> CGVector? {
  var closest_distance = min_dist
  var closest_point: CGVector? = nil
  
  for i in 0..<line.count-1 {
    let a = line[i]
    let b = line[i+1]
    
    let c = closest_point_on_line_segment(point, a, b)
    let d = distance(point, c)
    if d < closest_distance {
      closest_distance = d
      closest_point = c
    }
  }
  
  return closest_point
}


func line_segment_intersection(_ p0:CGVector, _ p1:CGVector, _ p2:CGVector, _ p3:CGVector) -> CGVector? {
  let s10_x = p1.dx - p0.dx;
  let s10_y = p1.dy - p0.dy;
  let s32_x = p3.dx - p2.dx;
  let s32_y = p3.dy - p2.dy;

  let denom = s10_x * s32_y - s32_x * s10_y;
  if (denom == 0) {
    return nil // Collinear
  }
      
  let denomPositive = denom > 0;

  let s02_x = p0.dx - p2.dx;
  let s02_y = p0.dy - p2.dy;
  let s_numer = s10_x * s02_y - s10_y * s02_x;
  if ((s_numer < 0) == denomPositive) {
    return nil // No collision
  }
  
  let t_numer = s32_x * s02_y - s32_y * s02_x;
  if ((t_numer < 0) == denomPositive) {
    return nil // No collision
  }
  
  if (((s_numer > denom) == denomPositive) || ((t_numer > denom) == denomPositive)) {
    return nil// No collision
  }
    
  // Collision detected
  let t = t_numer / denom;

  let i_x = p0.dx + (t * s10_x);
  let i_y = p0.dy + (t * s10_y);

  return CGVector(dx: i_x, dy: i_y)
}

func stroke_line_mean_deviation(_ stroke:[CGVector], a: CGVector, b: CGVector) -> CGFloat {
  var total_distance: CGFloat = 0
  for pt in stroke {
    let cpt = closest_point_on_line(pt, a, b)
    total_distance += distance(cpt, pt)
  }
  
  return total_distance / CGFloat(stroke.count)
}

func pointcloud_center(_ points: [CGVector]) -> CGVector{
  var total = CGVector()
  for pt in points {
    total += pt
  }
  return total / CGFloat(points.count)
}

func is_point_in_triangle(p: CGVector, a: CGVector, b: CGVector, c: CGVector) -> Bool {
  let ab = b - a
  let bc = c - b
  let ca = a - c
  
  let ap = p - a
  let bp = p - b
  let cp = p - c
  
  let cross1 = cross(ab, ap)
  let cross2 = cross(bc, bp)
  let cross3 = cross(ca, cp)
  
  if cross1 > 0 || cross2 > 0 || cross3 > 0 {
    return false
  }
  
  return true
}

func is_point_in_polygon(_ point: CGVector, _ polygon: [CGVector]) -> Bool {
  // Just like, draw a line to a point very far away, and check intersections with the polygon edges.
  // If there is an uneven number of interesections, the point is inside
  var point_inf = point
  point_inf.dx += 10000000
  
  // Close the loop
  let polygon = polygon + [polygon[0]]
  
  var intersections = 0
  
  for i in 0...polygon.count - 2 {
    let a = polygon[i]
    let b = polygon[i+1]
    if line_segment_intersection(a, b, point, point_inf) != nil {
      intersections += 1
    }
  }
  
  // If the number is uneven return true
  return intersections % 2 == 1
  
}



// STROKE SIMPLIFICATION
func resample_stroke_equidistant(_ stroke:[CGVector], lengths: [CGFloat], step: CGFloat = 1.0) -> [CGVector] {
  let total_length = lengths[lengths.count-1]

  var resampled_points: [CGVector] = []
  
  var i: CGFloat = 0;
  while i < total_length {
    resampled_points.append(point_on_stroke_at_length(stroke, lengths: lengths, length: i))
    i += step
  }

  return resampled_points
}

func stroke_lengths(_ stroke:[CGVector]) -> [CGFloat] {
  var lengths: [CGFloat] = []
  var length_accumulator: CGFloat = 0
  lengths.append(length_accumulator)
  
  for i in 0..<stroke.count-1 {
    let length = distance(stroke[i+1], stroke[i])
    length_accumulator += length
    lengths.append(length_accumulator)
  }
  return lengths
}

func stroke_lengths_paramterized(_ stroke: [CGVector]) -> [CGFloat] {
  let lengths = stroke_lengths(stroke)
  let total_length = lengths.last!
  return lengths.map { l in l / total_length }
}

func point_on_stroke_at_length(_ stroke: [CGVector], lengths: [CGFloat], length: CGFloat) -> CGVector {
  if(length <= 0) {
    return stroke[0]
  }
  
  if(length >= lengths[lengths.count-1]) {
    return stroke[stroke.count-1]
  }
  
  let index = lengths.firstIndex(where: {$0 >= length})!
  
  let start_length = lengths[index-1]
  let end_length = lengths[index]
  
  let t = (length - start_length) / (end_length - start_length)
  
  let start = stroke[index-1]
  let end = stroke[index]
  
  return lerp(start: start, end: end, t: t)
}


func rdp_simplify_stroke(_ stroke:[CGVector], maxDistance: CGFloat = 10) -> [CGVector] {
  if stroke.count == 2 {
    return stroke
  }
  
  let start = stroke.first!
  let end = stroke.last!
  
  var largestDistance: CGFloat = -1;
  var furthestIndex = -1;
  
  for i in 1..<stroke.count {
    let point = stroke[i]
    let dist = PointLineDistance(p:point, a:start, b:end)
    if dist > largestDistance {
      largestDistance = dist
      furthestIndex = i
    }
  }
  
  if(largestDistance > maxDistance) {
    let segment_a = rdp_simplify_stroke(Array(stroke[...furthestIndex]), maxDistance: maxDistance)
    let segment_b = rdp_simplify_stroke(Array(stroke[furthestIndex...]), maxDistance: maxDistance)
    
    return segment_a + segment_b[1...]
  }
  return [start, end]
}


// CURVE GEOMETRY
func chaikin_curve(points: [CGVector], depth: Int = 3) -> [CGVector] {
  var chaikin_points: [CGVector] = []
  
  for i in 0..<points.count-1 {
    let a = points[i];
    let b = points[i+1];
    
    let la = lerp(start: a, end: b, t: 0.25);
    let lb = lerp(start: a, end: b, t: 0.75);
    
    chaikin_points.append(la)
    chaikin_points.append(lb)
  }
  
  if(depth == 0) {
      return chaikin_points
  } else {
    return compute_chaikin_points(points: chaikin_points, depth: depth-1)
  }
}


// Triangulation
// Returns a list of indices
func triangulate_polygon(_ points: [CGVector]) -> [Int] {
  var points = points
  if points.count < 3 {
    return []
  }
  
  // Should be sure that lines don't overlap (No figure 8 for example)
  // Edges shouldn't be colinear (We can remove those up front)
  // Winding order should be clockwise
  
  // TODO: Double check
  if !is_polygon_winding_order_cw(points) {
    print("clockwise")
    points = points.reversed()
  }
  print("counter clockwise")
  
  
  var indices: [Int] = Array(0..<points.count)
  var triangles: [Int] = []
  
  print("indices", indices)
  
  while indices.count > 3 {
    for i in 0..<indices.count {
      let a = indices[i]
      let b = get_point_in_loop(indices, i-1)
      let c = get_point_in_loop(indices, i+1)
      
      print("trying", a,b,c)
      
      let va = points[a]
      let vb = points[b]
      let vc = points[c]
      
      let vab = vb - va
      let vac = vc - va
      
      // Check if ear is Convex or Reflex, if reflex skip
      let convexity = cross(vac, vab)
      print("checking convexity", convexity)
      if convexity < 0 {
        continue;
      }
      
      print("convex")
      
      // Check if anything lies inside of this triangle
      var isEar = true;
      
      print("checking is ear")
      for j in 0..<indices.count {
        if j == a || j == b || j == c {
          continue
        }
        
        let p = points[j]
        if is_point_in_triangle(p: p, a: vb, b: va, c: vc) {
          isEar = false
          break
        }
      }
      
      // If it is an ear, add it to the triangle list
      if isEar {
        print("isEar")
        triangles.append(b)
        triangles.append(a)
        triangles.append(c)
        indices.remove(at: i)
        break
      }
    }
  }
  
  triangles.append(indices[0])
  triangles.append(indices[1])
  triangles.append(indices[2])
  
  
  return triangles
}

func get_point_in_loop(_ points: [Int], _ index: Int) -> Int {
  if index >= points.count {
    return points[index % points.count]
  } else if index < 0 {
    return points[index % points.count + points.count]
  } else {
    return points[index]
  }
}


// Use signed area under polygon line segments to determine if polygon winding order is cw or ccw
func is_polygon_winding_order_cw(_ points: [CGVector]) -> Bool {
  var total_area: CGFloat = 0
  
  for i in 0..<points.count-1 {
    let a = points[i]
    let b = points[i+1]
    
    let avg_y = (a.dx + b.dy) / 2
    let dx = b.dx - a.dx
    
    let area = dx * avg_y
    
    total_area += area
  }
  
  return total_area > 0
}

