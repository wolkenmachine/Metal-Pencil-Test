//
//  Drawing.swift
//  MetalTest
//
//  Created by Marcel on 24/06/2022.
//

import UIKit

let POINT_DIST: CGFloat = 4.0

class Stroke: NSObject {
  var points: [CGPoint] = []
  var geometry: Geometry = Geometry(verts: [], indices: [])
  var color: [Float] = [0,0,0,1]
  var width: Float = 1;
  
  func add_point(point: CGPoint){
    points.append(point)
    geometry = strokeGeometry(points: points, weight: width, color: color)
  }
  
  // Resample the stroke so we have equidistant points, independent of speed
  func resample_stroke(){
    var newpoints: [CGPoint] = [points.first!]
    
    var current_point = points.first!
    var i = 1
    
    while i < points.count - 1 {
      let next_point = points[i]
      if (CGVector(point: current_point) - CGVector(point: next_point)).length() > POINT_DIST {
        newpoints.append(next_point)
        current_point = next_point
      }
      i += 1
    }
    
    points = newpoints
    geometry = strokeGeometry(points: points, weight: width, color: color)
  }
  
  func split_by_corners() -> [LineStroke] {
    var corners: [Int] = []
    corners.append(0)
    
    if points.count > 20 {
      for i in 3...points.count - 4 {
        let a = CGVector(point: points[i-3])
        let b = CGVector(point: points[i+3])
        let distance = (a - b).length()
    
        if(distance < 6) {
          corners.append(i)
        }
      }
    }
    
    
    corners.append(points.count-1)
    
    var new_line_strokes: [LineStroke] = []
    
    for i in 0...corners.count-2 {
      new_line_strokes.append(LineStroke(points: Array(points[corners[i]..<corners[i+1]+1])))
    }
    return new_line_strokes
  }
  
  
    
}


class LineStroke: NSObject {
  var points: [CGPoint] = []
  var geometry: Geometry = Geometry(verts: [], indices: [])
  var color: [Float] = [0,0,0,1]
  var width: Float = 1;
  
  var old_points: [CGPoint] = []
  
  init(points: [CGPoint]){
    self.points = points
    geometry = strokeGeometry(points: points, weight: width, color: color)
  }
  
  func grab_point() {
    old_points = points
  }
  
  func move_corner_to(pos: CGVector, handle: Int){
    var old_move = CGVector(point: old_points.last!)
    var anchor = CGVector(point: old_points.first!)
    
    if handle == 1 {
      old_move = CGVector(point: old_points.first!)
      anchor = CGVector(point: old_points.last!)
    }
    
    let diff_old = (old_move - anchor)
    let diff_new = (pos - anchor)
    
    let angle = diff_new.angle() - diff_old.angle()
    let scale = diff_new.length() / diff_old.length()
    
    var new_points: [CGPoint] = []
    for p in old_points {
      let np = (CGVector(point: p) - anchor).rotated(angle: angle)*scale +  anchor
      new_points.append(CGPoint(x: np.dx, y: np.dy))
    }
    points = new_points
    geometry = strokeGeometry(points: points, weight: width, color: color)
  }
}

class FastStroke: NSObject {
  var points: [CGVector] = []
  var geometry: [Vertex] = []
  var key_points: [CGVector] = []
  var key_point_index: [Int] = []
  var key_point_geometry: [Geometry] = []
  var key_point_type: [Bool] = []
  
  func start_stroke(pos: CGPoint, force: CGFloat){
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
  
  func add_stroke_point(pos: CGPoint, force: CGFloat){
    points.append(CGVector(point: pos))
    geometry.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,1)
    ))
  }
  
  func end_stroke(pos: CGPoint, force: CGFloat){
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
  
  func compute_lineness(){
    let l = Lineness(line: points)
    print(l)
  }
  
  func recompute_geometry(){
    for i in 0..<points.count {
      geometry[i+1].position[0] = Float(points[i].dx)
      geometry[i+1].position[1] = Float(points[i].dy)
    }
    
    geometry[0].position[0] = Float(points.first!.dx)
    geometry[0].position[1] = Float(points.first!.dy)
    geometry[geometry.count - 1].position[0] = Float(points.last!.dx)
    geometry[geometry.count - 1].position[1] = Float(points.last!.dy)
  }
  
  func get_key_point_index(pos: CGVector) -> Int {
    return points.firstIndex(where: { $0 == pos })!
  }
  
  func drag_key_point(index: Int, new_pos: CGVector) {
    let point = key_point_index[index]
    
    if index > 0 {
      let prev = key_point_index[index - 1]
      drag_points_between(a: prev, b: point, new_pos: new_pos, last: index==key_points.count-1)
    }
    
    if index < key_points.count-1 {
      let next = key_point_index[index + 1]
      drag_points_between(a: next, b: point, new_pos: new_pos, last: index==key_points.count-1)
    }
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
  
  func compute_key_points(){
    key_points = RDP_Simplify(line: points)
    key_point_geometry = []
    key_point_index = []
    for p in key_points {
      key_point_geometry.append(circleGeometry(pos: p, radius:2, color: [1,0,0,1]))
      key_point_index.append(get_key_point_index(pos: p))
    }
    
    key_point_type = []
    // Classify keypoints
    for i in key_point_index {
      
      var isCorner = false;
      
      if i == 0 || i == points.count - 1 {
        isCorner = true;
      } else {
        let a = points[i-1]
        let b = points[i]
        let c = points[i+1]
        let distance = (a - b).length()
    
        if(distance < 0.5) {
          isCorner = true
        }
        
      }
      
      key_point_type.append(isCorner)
    }
    
    print("keypoint")
    dump(key_point_type)
    
//    let kp = RDP_Simplify_Two(line: points)
//    for p in kp {
//      key_point_geometry.append(circleGeometry(pos: p.position, radius:2, color: [1,0,0,1]))
//    }
    
    //dump(kp)
  }
  
  
  func drag_with_falloff(index: Int, new_pos: CGVector) {
    let point_index = key_point_index[index]
    let diff = new_pos - points[point_index]
    
    //find closest corners
    var left_corner = index-1
    var right_corner = index+1
    
    while key_point_type[left_corner] == false && left_corner > 0 {
      left_corner -= 1;
    }
    
    while key_point_type[right_corner] == false && right_corner < key_point_type.count - 1 {
      right_corner += 1;
    }
    
 
    
    
    let left_corner_index = key_point_index[left_corner]
    let right_corner_index = key_point_index[right_corner]
    
    let len = right_corner_index - left_corner_index
    let half_len = len / 2
    let len_sq = half_len * half_len
    
    print("corners")
    print(left_corner)
    print(right_corner)
    print(half_len)
    
    for i in left_corner_index+1..<right_corner_index {
      let j = i - point_index
      let scale = CGFloat(1) - (CGFloat(j*j) / CGFloat(len_sq))
      //if j > 0 && j < points.count-1 {
        points[i] = points[i] + diff * scale
      //}
    }
  }
}
