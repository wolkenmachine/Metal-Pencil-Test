//
//  Strokes.swift
//  MetalTest
//
//  Created by Marcel on 06/07/2022.
//

import Foundation
import UIKit

// Stroke object used while drawing
class DrawingStroke {
  var points: [CGVector] = []
  var predicted_geometry: [Vertex] = []
  var geometry: [Vertex] = []
  
  func start(pos: CGPoint, force: CGFloat){
    points.append(CGVector(point: pos))
    geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,0)
    ))
    geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,1)
    ))
  }
  
  func add_point(pos: CGPoint, force: CGFloat){
    points.append(CGVector(point: pos))
    geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,1)
    ))
  }
  
  func add_predicted_point(pos: CGPoint, force: CGFloat){
    predicted_geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,1)
    ))
  }
  
  func end(pos: CGPoint, force: CGFloat){
    points.append(CGVector(point: pos))
    geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,1)
    ))
    geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,0)
    ))
  }
  
  // Call this function once every frame
  func get_geometry() -> [Vertex] {
    let total = geometry + predicted_geometry
    predicted_geometry = []
    return total
  }
}

struct KeyPoint {
  var point: CGVector
  var index: Int
  var corner: Bool
  var tangent_upstream: CGVector
  var tangent_downstream: CGVector
}

class MorphableStroke {
  var points: [CGVector] = []
  var key_points: [KeyPoint] = []
  var control_points: [CGVector] = []
  var chaikin_points: [CGVector] = []
  var chaikin_segment_points: [Int] = []
  var segments: [StrokeSegment] = []
  
  var lengths: [CGFloat] = []
  
  var geometry: [Vertex] = []
  
  init(_ s: DrawingStroke){
    points = s.points
    geometry = s.geometry

    compute_properties()
  }
  
  func compute_properties() {
    key_points = []
    control_points = []
    chaikin_points = []
    segments = []
    lengths = []
    
    //Compute length
    var length_accumulator: CGFloat = 0
    lengths.append(length_accumulator)
    for i in 0..<points.count-1 {
      let length = (points[i+1] - points[i]).length()
      length_accumulator += length
      lengths.append(length_accumulator)
    }
    
    // Compute key points
    let simplified_points = SimplifyStroke(line: points, epsilon: 10.0)
    for simplified_point in simplified_points {
      // find key_point index
      let index = points.firstIndex(where: {$0 == simplified_point})!
      
      let length_of_point = lengths[index]
      
      let a = get_point_at_length(length_of_point - 10)
      let b = get_point_at_length(length_of_point + 10)

      // Short straw approximation for checking corners
      let tangent = (a-b)
      
      // Compare points further along the line, to see if the shape approximates a triangle
      let ma = get_point_at_length(length_of_point - 20)
      let mb = get_point_at_length(length_of_point + 20)
      let pla = PointLineDistance(p: ma, a: simplified_point, b: a)
      let plb = PointLineDistance(p: mb, a: simplified_point, b: b)
      let pldist = pla + plb
      
      let corner =  (pldist < 4.0 && tangent.lengthSquared() < 300.0) || index == 0 || index == points.count - 1
      
      
      
      let tangent_norm = (a-b).normalized()
      
      var tangent_upstream = corner ? (a - simplified_point).normalized() : tangent_norm
      var tangent_downstream = corner ? (b - simplified_point).normalized() : CGVector(dx: 0.0, dy: 0.0) - tangent_norm
      
      key_points.append(KeyPoint(
        point: simplified_point,
        index: index,
        corner: corner,
        tangent_upstream: tangent_upstream,
        tangent_downstream: tangent_downstream
      ))
    }
    
    // Find colinear-ish curve points
    var i = 0;
    while i < key_points.count-2 {
      let a = key_points[i]
      let b = key_points[i+1]

      if(a.corner == false && b.corner == false) {
        let l = (a.tangent_upstream - b.tangent_downstream).length()
        if l > 1.80 { // If the two points are roughly paralell
          // If the points are not colinear
          if PointLineDistance(p:b.point, a:a.point, b:a.tangent_upstream) > 10.0 {
            print("add midpoint", key_points.count)
            let mid_index = (a.index + b.index) / 2
            let mid_length = lengths[mid_index]

            let a = get_point_at_length(mid_length - 10)
            let b = get_point_at_length(mid_length + 10)
            let tangent_norm = (a-b).normalized()

            key_points.insert(KeyPoint(
              point: points[mid_index],
              index: mid_index,
              corner: false,
              tangent_upstream: tangent_norm,
              tangent_downstream: CGVector(dx: 0.0, dy: 0.0) - tangent_norm
            ), at: i+1)
            i+=1
          }
        }
      }
      i+=1
    }
    
    // Compute control points
    for i in 0..<key_points.count-1 {
      if(key_points[i].corner == false || key_points[i+1].corner == false) {
        let pa = key_points[i].point
        let pb = key_points[i].point + key_points[i].tangent_downstream
        
        let pc = key_points[i+1].point + key_points[i+1].tangent_upstream
        let pd = key_points[i+1].point
        
        let intersecting_point = line_line_intersection(pa, pb, pc, pd)
        
        if let ip = intersecting_point {
          control_points.append(ip)
        }
      }
    }
    
    

    
    // Compute approximate Chaikin curve
    chaikin_segment_points = []
    var last_chaikin_point = -1;
    if(control_points.count > 0) {
      chaikin_points = [points.first!] + compute_chaikin_points(points: control_points) + [points.last!]
      
    //For each chaikin point find the closest index on the curve
      for cp in chaikin_points {
        var min_dist: CGFloat = 100;
        var closest_point = -1;
        for (i, p) in points.enumerated() {
          let dist = (cp - p).length()
          if dist < min_dist {
            closest_point = i;
            min_dist = dist
          }
        }
        
        // Guard against decreasing points
        if closest_point < last_chaikin_point {
          closest_point = last_chaikin_point
        }
        
        last_chaikin_point = closest_point
        chaikin_segment_points.append(closest_point)
      }
    }
    
    print(chaikin_segment_points)
      
    
//    var chaikin_segment_offset = 0
//    for i in 0..<key_points.count - 1 {
//      let kpa = key_points[i]
//      let kpb = key_points[i+1]
//      if kpa.corner == true  && kpb.corner {
//        segments.append(StrokeSegment(Array(points[kpa.index...kpb.index])))
//      } else {
//
//      }
//    }
      
    // Split into segments
    if chaikin_segment_points.count > 0 {
//      for i in 0..<chaikin_segment_points.count-1 {
//        let kpa = chaikin_segment_points[i]
//        let kpb = chaikin_segment_points[i+1]
//        segments.append(StrokeSegment(Array(points[kpa...kpb])))
//      }
    } else {
      for i in 0..<key_points.count-1 {
        let kpa = key_points[i].index
        let kpb = key_points[i+1].index

        segments.append(StrokeSegment(Array(points[kpa...kpb])))
      }
    }
  }
  
  func drag_control_point(_ index: Int, _ pos: CGVector) {
    control_points[index] = pos
    let new_chaikin_points = [points.first!] + compute_chaikin_points(points: control_points) + [points.last!]
    var deltas: [CGVector] = []
    for (i, ncp) in new_chaikin_points.enumerated() {
      deltas.append(ncp - chaikin_points[i])
    }
    
    print("deltas", deltas)
    for i in 0...deltas.count - 2 {
      let start_delta = deltas[i]
      let end_delta = deltas[i+1]
      
      let start_point = chaikin_segment_points[i]
      let end_point = chaikin_segment_points[i+1]
      let segment_n_points = end_point - start_point
      
      for j in 0..<segment_n_points {
        let proportion = CGFloat(j) / CGFloat(segment_n_points)
        
        print("proportion", proportion)
        let inv_proportion = CGFloat(1) - proportion
        let point_index = start_point + j
        points[point_index] = points[point_index] + (start_delta * inv_proportion) + (end_delta * proportion)
      }
    }
    
//    for i in 0...deltas.count - 2 {
//      let start_delta = deltas[i]
//      let end_delta = deltas[i+1]
//
//      let segment = segments[i]
//      segment.drag_points(new_start: segment.start + start_delta , new_end: segment.end + end_delta)
//    }
    
    chaikin_points = new_chaikin_points
    //recompute_geometry_from_segments()
    recompute_geometry()
  }
  
  func drag_key_point(_ index: Int, _ pos: CGVector) {
    if index < segments.count {
      let segment = segments[index]
      segment.drag_points(new_start: pos, new_end: segment.end)
    }
    
    if index > 0 {
      let segment = segments[index - 1]
      segment.drag_points(new_start: segment.start, new_end: pos)
    }
    
    recompute_geometry_from_segments()
  }
  
  func get_point_at_length(_ length: CGFloat) -> CGVector {
    if(length <= 0) {
      return points[0]
    }
    
    if(length >= lengths[lengths.count-1]) {
      return points[points.count-1]
    }
    
    let index = lengths.firstIndex(where: {$0 >= length})!
    
    
    let start_length = lengths[index-1]
    let end_length = lengths[index]
    
    let t = (length - start_length) / (end_length - start_length)
    
    let start = points[index-1]
    let end = points[index]
    
    return lerp(start: start, end: end, t: t)
  }
  
  func recompute_geometry(){
    geometry = []
    
    let pos = points[0]
    geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos.dx), Float(pos.dy), Float(1.0)),
      color: SIMD4<Float>(0,0,0,0)
    ))
    geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos.dx), Float(pos.dy), Float(1.0)),
      color: SIMD4<Float>(0,0,0,1)
    ))
    
    for i in 1..<points.count-1 {
      let pos = points[i]
      geometry.append(Vertex(
        position: SIMD3<Float>(Float(pos.dx), Float(pos.dy), Float(1.0)),
        color: SIMD4<Float>(0,0,0,1)
      ))
    }
    
    let pos2 = points.last!
    geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos2.dx), Float(pos2.dy), Float(1.0)),
      color: SIMD4<Float>(0,0,0,1)
    ))
    geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos2.dx), Float(pos2.dy), Float(1.0)),
      color: SIMD4<Float>(0,0,0,0)
    ))
  }
  
  func recompute_geometry_from_segments(){
    points = []
    for segment in segments {
      if(segment.points.count > 1) {
        points.append(contentsOf: segment.points[0...segment.points.count-2])
      }
    }
    
    points.append(segments.last!.points.last!)
    recompute_geometry()
  }
}

class StrokeSegment {
  var points: [CGVector] = []
  var start: CGVector
  var end: CGVector
  
  init(_ points: [CGVector]){
    self.points = points
    start = points.first!
    end = points.last!
  }
  
  func drag_points(new_start: CGVector, new_end: CGVector){
    var old_transform = TransformMatrix()
    old_transform.from_line(start, end)
    old_transform = old_transform.get_inverse()
    
    let new_transform = TransformMatrix()
    new_transform.from_line(new_start, new_end)
    
    let old_vec_length = (start - end).length()
    let new_vec_length = (new_start - new_end).length()
    let scale = new_vec_length / old_vec_length
    
    //let scale_width = new_vec_length < old_vec_length
    
    for i in 0...points.count - 1 {
      let point = points[i]
      var projected = old_transform.transform_vector(point)
      projected.dx = projected.dx * scale
//      if(scale_width) {
//        projected.dy = projected.dy * scale
//      }
        
      let new_point = new_transform.transform_vector(projected)
      points[i] = new_point
    }
    
    start = points.first!
    end = points.last!
  }
}


//RDP Line Simplification Algorithm
func SimplifyStroke(line:[CGVector], epsilon: CGFloat) -> [CGVector] {
  if line.count == 2 {
    return line
  }
  
  let start = line.first!
  let end = line.last!
  
  var largestDistance: CGFloat = -1;
  var furthestIndex = -1;
  
  for i in 1..<line.count {
    let point = line[i]
    let dist = PointLineDistance(p:point, a:start, b:end)
    if dist > largestDistance {
      largestDistance = dist
      furthestIndex = i
    }
  }
  
  if(largestDistance > epsilon) {
    let segment_a = SimplifyStroke(line: Array(line[...furthestIndex]), epsilon: epsilon)
    let segment_b = SimplifyStroke(line: Array(line[furthestIndex...]), epsilon: epsilon)
    
    return segment_a + segment_b[1...]
  }
  return [start, end]
}

func compute_chaikin_points(points: [CGVector], depth: Int = 2) -> [CGVector] {
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
