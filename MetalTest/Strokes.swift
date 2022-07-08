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
  
  var velocity: [CGVector] = []
  var acceleration: [CGVector] = []
  var curvature: [CGFloat] = []
  var lengths: [CGFloat] = []
  
  var geometry: [Vertex] = []
  
  init(_ p: [CGVector]) {
    points = p
    recompute_geometry()
  }
  
  
  init(_ s: DrawingStroke){
    points = s.points
    geometry = s.geometry
    
    //points = SimplifyStroke(line: points, epsilon: 1.0)
//    recompute_geometry()
    
    //Compute length
    var length_accumulator: CGFloat = 0
    lengths.append(length_accumulator)
    for i in 0..<points.count-1 {
      let length = (points[i+1] - points[i]).length()
      length_accumulator += length
      lengths.append(length_accumulator)
    }
    
    //Compute velocity
    for i in 0..<points.count-10 {
      //let v = points[i+3]*0.3 + points[i+2]*0.1 - points[i+1]*0.1 - points[i]*0.3
      //let v =  .3 x(k) + .1 x(k-1) - .1 x(k-2) - .3 x(k-3)
      let v = points[i+10] - points[i]
      velocity.append(v)
    }
    //Compute acceleration
    for i in 0..<velocity.count-10 {
      //let a = velocity[i+3]*0.3 + velocity[i+2]*0.1 - velocity[i+1]*0.1 - velocity[i]*0.3
      let a = velocity[i+10] - velocity[i]
      acceleration.append(a)
    }
    
    //Compute curvature
    for i in 3..<points.count-3 {
      let a = points[i-3]
      let b = points[i]
      let c = points[i+3]
      
      let ab = (b-a).normalized()
      let bc = (c-b).normalized()
      
      //Devide by two because maximum length is only ever going to be 2, so value is somewhere between 0-1
      let diff = (ab - bc).length()
      curvature.append(diff)
      
      //print(diff)
      
      // Colorize stroke so it's redder the more tight the corner is
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
        print("l", l)
        if l > 1.95 {
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
      i+=1
    }
    
    
    // Compute controller points
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
  
  func drag_points_between(a: Int, b: Int, new_pos: CGVector, last: Bool){
    let start = points[a]
    let end = points[b]
    
    
    var old_transform = TransformMatrix()
    old_transform.from_line(start, end)
    old_transform = old_transform.get_inverse()
    let new_transform = TransformMatrix()
    new_transform.from_line(start, new_pos)
    
    let old_vec_length = (start - end).length()
    let new_vec_length = (new_pos - start).length()
    let scale = new_vec_length / old_vec_length
    
    var low = a
    var hi = b
    if a > b {
      low = b
      hi = a
    }
    
    if last {
      hi+=1
    }
    
    for i in low..<hi {
      let point = points[i]
      var projected = old_transform.transform_vector(point)
      projected.dx = projected.dx * scale
        
      let new_point = new_transform.transform_vector(projected)
      points[i] = new_point
    }
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
    
    for i in 0...points.count-1 {
      let point = points[i]
      var projected = old_transform.transform_vector(point)
      projected.dx = projected.dx * scale
        
      let new_point = new_transform.transform_vector(projected)
      points[i] = new_point
    }
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

