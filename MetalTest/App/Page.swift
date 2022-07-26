//
//  Page.swift
//  MetalTest
//
//  Created by Marcel on 21/07/2022.
//

import Foundation
import UIKit

enum MorphableStroke {
  case Line(MorphableLine)
  case Bezier(MorphableBezier)
}

class MorphableLine {
  var a: CGVector
  var b: CGVector
  var points: [CGVector]
  
  init(a: CGVector, b: CGVector, points: [CGVector]){
    self.a = a
    self.b = b
    self.points = points
  }
  
  func move(_ new_a: CGVector, _ new_b: CGVector){
    var old_transform = TransformMatrix()
    old_transform.from_line(a, b)
    old_transform = old_transform.get_inverse()
    
    let new_transform = TransformMatrix()
    new_transform.from_line(new_a, new_b)
    
    let old_vec_length = distance(a, b)
    let new_vec_length = distance(new_a, new_b)
    let scale = new_vec_length / old_vec_length
    
    //let scale_width = new_vec_length < old_vec_length
    
    for i in 0...points.count - 1 {
      let point = points[i]
      var projected = old_transform.transform_vector(point)
      projected.dx = projected.dx * scale
      let new_point = new_transform.transform_vector(projected)
      points[i] = new_point
    }
    
    a = points.first!
    b = points.last!
  }
}

class MorphableBezier {
  var a: CGVector
  var b: CGVector
  var c: CGVector
  var d: CGVector
  var points: [CGVector]
  
  init(a: CGVector, b: CGVector, c: CGVector, d: CGVector, points: [CGVector]){
    self.a = a
    self.b = b
    self.c = c
    self.d = d
    self.points = points
  }
}


protocol ControlPointProtocol {
  func grab(_ pos: CGVector)
  func move(_ pos: CGVector)
}

class ControlPoint {
  var line: MorphableLine
  var start: Bool
  var pos: CGVector
  
  init(line: MorphableLine, start: Bool){
    self.line = line
    self.start = start
    
    if start {
      self.pos = line.a
    } else {
      self.pos = line.b
    }
  }
  
  func move(_ pos: CGVector){
    self.pos = pos
    if start {
      self.line.move(pos, self.line.b)
    } else {
      self.line.move(self.line.a, pos)
    }
  }
}

class ControlPointCluster {
  var center = CGVector()
  var points: [ControlPoint] = []
  
  var down_point = CGVector()
  var down_points: [CGVector] = []
  
  init(_ points: [ControlPoint]) {
    self.points = points
  }
  
  func grab(_ pos: CGVector){
    down_point = pos
    down_points = points.map({$0.pos})
  }
  
  func move(_ pos: CGVector) {
    let delta = pos - down_point
    
    for (i, pt) in points.enumerated() {
      pt.move(down_points[i] + delta)
    }
    
    update_center()
  }
  
  func update_center(){
    center = pointcloud_center(points.map({$0.pos}))
  }
}

class IntersectionControlPoint{
  var line_a: MorphableLine
  var line_b: MorphableLine
  var intersection: CGVector
  
  init(_ line_a: MorphableLine, _ line_b: MorphableLine, intersection: CGVector) {
    self.line_a = line_a
    self.line_b = line_b
    self.intersection = intersection
  }
}


// Page
class Page {
  var morphable_strokes: [MorphableStroke] = []
  
  // Dragging mode info
  var dragging_point_index = -1
  
  var control_points: [ControlPoint] = []
  var cluster_points: [ControlPointCluster] = []
  var intersection_points: [IntersectionControlPoint] = []
  
  func add_stroke(_ stroke: [CGVector]) {
    morphable_strokes.append(contentsOf: split_stroke_into_morphable_strokes(stroke))
    
    update_abstract_model()
    
  }
  
  func down_pencil(_ pos: CGVector){
    dragging_point_index = closest_point_in_collection(points: cluster_points.map({$0.center}), point: pos)
    if dragging_point_index > -1 {
      cluster_points[dragging_point_index].grab(pos)
    }
  }
  
  func move_pencil(_ pos: CGVector){
    if dragging_point_index > -1 {
      cluster_points[dragging_point_index].move(pos)
    }
  }
  
  func up_pencil() {
    dragging_point_index  = -1
  }
  
  
  func update_abstract_model(){
    // Find all control points
    
    control_points = []
    var lines: [MorphableLine] = []
    
    for stroke in morphable_strokes {
      if case let .Line(line) = stroke {
        control_points.append(ControlPoint(line: line, start: true))
        control_points.append(ControlPoint(line: line, start: false))
        lines.append(line)
      }
    }
    
    cluster_points = cluster_control_points(control_points)
    intersection_points = intersect_lines(lines)
    
    // Cluster control points
    
  }
  
  func render(_ renderer: Renderer) {
    var data: [Vertex] = []
    
    for stroke in morphable_strokes {
      var points: [CGVector] = []
      switch stroke {
        case let .Line(line):
          points = line.points
        case let .Bezier(curve):
          points = curve.points
      }
      
      let first = points.first!
      data.append(Vertex(position: SIMD3(Float(first.dx), Float(first.dy), 1.0), color: SIMD4(0,0,0,0)))
      for pt in points {
        data.append(Vertex(position: SIMD3(Float(pt.dx), Float(pt.dy), 1.0), color: SIMD4(0,0,0,1)))
      }
      let last = points.last!
      data.append(Vertex(position: SIMD3(Float(last.dx), Float(last.dy), 1.0), color: SIMD4(0,0,0,0)))
      
    }
    
    renderer.addStrokeData(data)

  }
  
  func render_control_points(_ renderer: Renderer){
    for cp in cluster_points {
      renderer.addShapeData(circleShape(pos: cp.center, radius: 4.0, resolution: 8, color: Color(0,0,255)))
    }
    
    for ip in intersection_points {
      renderer.addShapeData(circleShape(pos: ip.intersection, radius: 4.0, resolution: 8, color: Color(0,255,0)))
    }
  }
}

func split_stroke_into_morphable_strokes(_ stroke: [CGVector]) -> [MorphableStroke] {
  
  let resampled_stroke = resample_stroke_equidistant(stroke, lengths: stroke_lengths(stroke))
  let simplified_stroke = rdp_simplify_stroke(resampled_stroke)
  
  // Lookup key_point indices
  let key_point_indices = simplified_stroke.map({ simplified_point in
    resampled_stroke.firstIndex(where: {resampled_point in resampled_point == simplified_point})
  })
  
  // Split into segments
  var segments: [[CGVector]] = []
  
  for i in 0..<key_point_indices.count-1 {
    let ai = key_point_indices[i]!
    let bi = key_point_indices[i+1]!
    segments.append(Array(resampled_stroke[ai...bi]))
  }
  
  // Categorize segments as straight or not.
  // We accumulate curve segements together so they can be bezierified later
  var morphable_strokes: [MorphableStroke] = []
  var curve_accumulator: [CGVector] = []
  for segment in segments {
    let deviation = stroke_line_mean_deviation(segment, a: segment.first!, b: segment.last!)
    
    // Straight segment
    if (deviation < 2.0) {
      // Append the previously accumulated segments as a curve
      if curve_accumulator.count > 0 {
        morphable_strokes.append(MorphableStroke.Bezier(MorphableBezier(a: curve_accumulator.first!, b: CGVector(), c: CGVector(), d: curve_accumulator.last!, points: curve_accumulator)))
        curve_accumulator = []
      }
      // Append the current segment as a line
      morphable_strokes.append(MorphableStroke.Line(MorphableLine(a: segment.first!, b: segment.last!, points: segment)))
    } else {
      // Accumulate curve segments
      if(curve_accumulator.count == 0) {
       curve_accumulator = segment
      } else {
        curve_accumulator.append(contentsOf: segment[1...segment.count-1])
      }
      
    }
  }
  // If there are still accumulated segments left, append those
  if curve_accumulator.count > 0 {
    morphable_strokes.append(MorphableStroke.Bezier(MorphableBezier(a: curve_accumulator.first!, b: CGVector(), c: CGVector(), d: curve_accumulator.last!, points: curve_accumulator)))
  }
  
  return morphable_strokes
}


func cluster_control_points(_ points: [ControlPoint]) -> [ControlPointCluster] {
  var clusters: [ControlPointCluster] = []
  
  // Create a cluster for each individual point
  for i in 0..<points.count {
    let a = points[i]
    clusters.append(ControlPointCluster([a]))
  }
  
  for i in 0..<points.count {
    let a = points[i]
    for j in i+1..<points.count {
      let b = points[j]
      
      if distance(a.pos,b.pos) < 10 {
        // If the points are in different clusters, combine the two clusters into one
        let a_cluster = clusters.first(where: {cluster in cluster.points.contains(where: {$0 === a})})
        let b_cluster = clusters.first(where: {cluster in cluster.points.contains(where: {$0 === b})})
        
        if a_cluster !== b_cluster {
          a_cluster!.points.append(contentsOf: b_cluster!.points)
          a_cluster!.points.append(b)
          clusters = clusters.filter({$0 !== b_cluster!})
        }
      }
    }
  }
  
  for cluster in clusters {
    cluster.update_center()
  }
  
  return clusters
}

func intersect_lines(_ lines: [MorphableLine]) -> [IntersectionControlPoint] {
  // Pairs of lines
  var intersections: [IntersectionControlPoint] = []
  
  for i in 0..<lines.count {
    let a = lines[i]
    for j in i+1..<lines.count {
      let b = lines[j]
      
      let intersection = line_segment_intersection(a.a, a.b, b.a, b.b)
      if let intersection = intersection {
        intersections.append(IntersectionControlPoint(a, b, intersection: intersection))
      }
    }
  }
  
  return intersections
}
