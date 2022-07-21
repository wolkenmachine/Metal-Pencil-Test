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

// CURVES
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
