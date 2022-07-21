//
//  Stroke.swift
//  MetalTest
//
//  Created by Marcel on 18/07/2022.
//

import Foundation
import UIKit

class Color {
  var r: Float
  var g: Float
  var b: Float
  var a: Float
  
  init(_ r: Int, _ g: Int, _ b: Int, _ a: Int) {
    self.r = Float(r) / 255
    self.g = Float(g) / 255
    self.b = Float(b) / 255
    self.a = Float(a) / 255
  }
  
  init(_ r: Int, _ g: Int, _ b: Int) {
    self.r = Float(r) / 255
    self.g = Float(g) / 255
    self.b = Float(b) / 255
    self.a = 1.0
  }
  
  func as_simd() -> SIMD4<Float> {
    return SIMD4<Float>(r,g,b,a)
  }
  
  func as_simd_transparent() -> SIMD4<Float> {
    return SIMD4<Float>(r,g,b,0)
  }
  
  func as_simd_opaque() -> SIMD4<Float> {
    return SIMD4<Float>(r,g,b,1)
  }
}

class ActiveStroke {
  
  var mode = "Free"
  
  var pencil_down = false
  var control_point_down = false
  var control_point_id = 0
  
  var last_pencil = CGVector()
  var last_pencil_actual = CGVector()
  var last_control_point = CGVector()
  
  
  let base_color = Color(0,0,0,50).as_simd()
  //let trace_color = Color(228,72,170,255).as_simd()
  
  var current_trace: [CGVector] = []
  
  func start_stroke(){
    pencil_down = true
  }
  
  func move_stroke(pos: CGVector) {
    if (last_pencil_actual - pos).length() > 2 {
      if mode == "Free" {
        current_trace.append(pos)
        last_pencil = pos
      } else {
        let new_point = ScalarProjection(p: pos, a: last_control_point, b: last_pencil)
        current_trace.append(new_point)
        last_pencil = new_point
      }
      last_pencil_actual = pos
    }
  }
  
  func end_stroke() -> [CGVector] {
    pencil_down = false
    let returntrace = current_trace
    current_trace = []
    
    if control_point_down == false {
      mode = "Free"
    }
    
    return returntrace
  }
  
  func start_control_point(pos: CGVector, id: Int) {
    //control_point_down = true
  }
  
  func move_control_point(pos: CGVector, id: Int) {
    //print(mode, control_point_id, id)
    
    // If we're in free mode
    if mode == "Free" && control_point_down == false {
      if pencil_down && (pos - last_pencil).length() < 300 {
        mode = "Guide"
        control_point_id = id
        control_point_down = true
      }
    }
    
    if mode == "Guide" && control_point_down == false {
      if pencil_down && (pos - last_control_point).length() < 300 {
        control_point_id = id
        control_point_down = true
      }
    }
    
    if id == control_point_id {
      last_control_point = pos
    }
    
  }
  
  func end_control_point(id: Int) {
    if id == control_point_id {
      control_point_down = false
      if pencil_down == false {
        mode = "Free"
      }
    }
  }
}


class StaticGuide {
  var control_points = [Int: CGVector]()
  
  var active = false
  var curve_points: [(Int, CGVector)] = []
  var line: [CGVector] = []
  
  
  func start_control_point(pos: CGVector, id: Int) {
    control_points[id] = pos
    
    // Move existing control points
    if(active == true) {
      var found = false
      for i in 0..<curve_points.count {
        if (curve_points[i].1 - pos).length() < 50 {
          curve_points[i].0 = id
          found = true
        }
      }
      
      if !found {
        // Add a new control point
        print("add point", id)
        curve_points.append((id, pos))
      }
    }
    
    // Check for close pairs
    // Iterate over pairs of ids
    let ids = Array(control_points.keys)
    for i in 0..<ids.count {
      let a = control_points[ids[i]]!
      for j in i+1..<ids.count {
        let b = control_points[ids[j]]!
        
        if (a - b).length() < 100 {
          //print("trigger", ids[i], ids[j])
          if(active == false) {
            active = true
            curve_points = [
              (ids[i], a),
              (ids[j], b),
            ]
            return
          } else {
            active = false
          }
        }
      }
    }
  }
  
  func move_control_point(pos: CGVector, id: Int){
    control_points[id] = pos
    
    if(active == true) {
      // Update curve points if we're active
      for (id, v) in control_points {
        for i in 0..<curve_points.count {
          if id == curve_points[i].0 {
            curve_points[i].1 = v
          }
        }
      }
      
      generate_line()
    }
  }
  
  func end_control_point(id: Int) {
    control_points[id] = nil
  }
  
  func generate_line() {
    if curve_points.count == 2 {
      let offset = (curve_points[0].1 - curve_points[1].1) * 1000.0
      line = [curve_points[0].1 + offset, curve_points[0].1 - offset]
    } else {
      
      let offseta = (curve_points[0].1 - curve_points[1].1) * 1000.0
      let offsetb = (curve_points[curve_points.count-2].1 - curve_points[curve_points.count-1].1) * 1000.0
      line = [curve_points[0].1 + offseta] + compute_chaikin_points(points: curve_points.map({$0.1})) + [curve_points[curve_points.count-1].1 - offsetb]
    }
  }
}



///-----------------
class StringStroke {
  var start: CGVector
  var end: CGVector
  var mid: CGVector
  var type = "Line"
  
  var points: [CGVector] = []
  
  let base_color = Color(0,0,0,255).as_simd()
  
  init(_ point: CGVector) {
    start = point
    end = point
    mid = point
  }
  
  func move_pencil(_ point: CGVector) {
    end = point
    
    if type == "Curve" {
      let chaikinpts = compute_chaikin_points(points: [
        start,
        mid,
        end
      ])
      points = [start] + chaikinpts + [end]
    }
  }
  
  func move_finger(_ point: CGVector) {
    mid = point
    
    if (start - end).length() < 10 {
      type = "Circle"
    } else if(type=="Line") {
      type = "Curve"
    }
    
    if type == "Circle" {
      let radius = (end - mid).length()
      
      points = []
      for v in circlePoints {
        points.append(CGVector(dx: end.dx + CGFloat(v.x)*radius, dy: end.dy + CGFloat(v.y)*radius))
      }
    }
    
    if type == "Curve" {
      let chaikinpts = compute_chaikin_points(points: [
        start,
        mid,
        end
      ])
      points = [start] + chaikinpts + [end]
    }
    
  }
  
  func get_geometry() -> Geometry {
    
    if type == "Line" {
      return strokeGeometry(points: [
        start,
        end
      ], weight: 1.0, color: [0,0,0,1])
    } else {
      return strokeGeometry(points: points, weight: 1.0, color: [0,0,0,1])
    }
    
  }
}




class TapeStroke {
  var start: CGVector
  var end: CGVector
  let base_color = Color(0,0,0,50).as_simd()
  let trace_color = Color(0,0,0,255).as_simd()
  
  var trace: [CGVector] = []
  
  
  init(_ point: CGVector) {
    start = point
    end = point
  }
  
  func move_finger(_ point: CGVector) {
    //start = point
    let new_point = ScalarProjection(p: point, a: start, b: end)
    
    // Check if new_point is inside or outside of line segment
    let compare = (end - start).length()
    let check = (end - new_point).length()
    
    //print(diff)
    if compare > check {
      trace.append(new_point)
      start = new_point
    }
    
    
  }
  
  func move_pencil(_ point: CGVector) {
    end = point
  }
  
  func get_geometry() -> Geometry {
    let diff = (start - end).normalized() //* CGFloat(1.0) // line thickness
    
    let start_left_offset = start + diff.rotated90clockwise()
    let start_right_offset = start + diff.rotated90counterclockwise()
    let end_left_offset = end + diff.rotated90clockwise()
    let end_right_offset = end + diff.rotated90counterclockwise()

    let verts = [
      Vertex(position: [Float(start_left_offset.dx), Float(start_left_offset.dy), 0], color: base_color),
      Vertex(position: [Float(start_right_offset.dx), Float(start_right_offset.dy), 0], color: base_color),
      Vertex(position: [Float(end_left_offset.dx), Float(end_left_offset.dy), 0], color: base_color),
      Vertex(position: [Float(end_right_offset.dx), Float(end_right_offset.dy), 0], color: base_color),
    ]
    
    let indices: [UInt16] = [
      0,1,2,
      2,3,1
    ]
    
    return Geometry (verts: verts, indices: indices)
  }
  
  func get_trace_geometry() -> Geometry {
    var verts: [Vertex] = []
    var indices: [UInt16] = []
    var indexOffset = UInt16(0)
        
    var points = trace
    var lastPoint = points[0]
    points.removeFirst()
    
    verts += [
      Vertex(position: [Float(lastPoint.dx), Float(lastPoint.dy), 0], color: trace_color),
      Vertex(position: [Float(lastPoint.dx), Float(lastPoint.dy), 0], color: trace_color)
    ]
    
    for point in points {
      let newPoint = point
      let diff = (newPoint - lastPoint).normalized()
      let left_offset = newPoint + diff.rotated90clockwise()
      let right_offset = newPoint + diff.rotated90counterclockwise()

      verts += [
        Vertex(position: [Float(right_offset.dx), Float(right_offset.dy), 0], color: trace_color),
        Vertex(position: [Float(left_offset.dx), Float(left_offset.dy), 0], color: trace_color),
      ]


      indices += [
        indexOffset+0, indexOffset+1, indexOffset+2,
        indexOffset+2, indexOffset+3, indexOffset+1
      ]

      indexOffset += 2

      lastPoint = newPoint
    }
    
    return Geometry (verts: verts, indices: indices)
  }
}


func compute_chaikin_points(points: [CGVector], depth: Int = 3) -> [CGVector] {
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
