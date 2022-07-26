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
