//
//  Page.swift
//  MetalTest
//
//  Created by Marcel on 21/07/2022.
//

import Foundation
import UIKit

var MONOTONIC_IDS = 0
var LINE_SEGMENT_IDS = 0

func generate_id() -> Int {
  MONOTONIC_IDS += 1
  return MONOTONIC_IDS
}

enum MorphableStroke {
  case Line(MorphableLine)
  case Bezier(MorphableBezier)
}

class MorphableLine {
  var a: CGVector
  var b: CGVector
  var points: [CGVector]
  var color: Color
  var id: Int
  
  init(a: CGVector, b: CGVector, points: [CGVector], color: Color){
    self.a = a
    self.b = b
    self.points = points
    self.color = color
    self.id = LINE_SEGMENT_IDS
    LINE_SEGMENT_IDS += 1
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
  var color: Color
  
  init(a: CGVector, b: CGVector, c: CGVector, d: CGVector, points: [CGVector], color: Color){
    self.a = a
    self.b = b
    self.c = c
    self.d = d
    self.points = points
    self.color = color
  }
}


protocol ControlPoint {
  var pos: CGVector {get set}
  
  func grab(_ pos: CGVector)
  func move(_ pos: CGVector)
}

class EndControlPoint: ControlPoint {
  var line: MorphableLine
  var start: Bool
  var pos: CGVector
  var connected_to: EndControlPoint?
  var id: String
  
  init(line: MorphableLine, start: Bool){
    self.line = line
    self.start = start
    
    if start {
      self.pos = line.a
      self.id = "\(line.id)_s"
    } else {
      self.pos = line.b
      self.id = "\(line.id)_e"
    }
  }
  
  func grab(_ pos: CGVector) {
    
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

class ClusterControlPoint: ControlPoint {
  var pos: CGVector
  var points: [EndControlPoint] = []
  
  var down_point = CGVector()
  var down_points: [CGVector] = []
  var id: String
  
  init(_ points: [EndControlPoint]) {
    self.points = points
    self.pos = pointcloud_center(points.map({$0.pos}))
    self.id = self.points.map({ pt in
      pt.id
    }).joined()
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
    self.pos = pointcloud_center(points.map({$0.pos}))
  }
}

class IntersectionControlPoint: ControlPoint {
  var pos: CGVector
  var line_a: MorphableLine
  var line_b: MorphableLine
  
  init(_ line_a: MorphableLine, _ line_b: MorphableLine, intersection: CGVector) {
    self.line_a = line_a
    self.line_b = line_b
    self.pos = intersection
  }

  func grab(_ pos: CGVector) {
    //self.pos = pos
  }

  func move(_ pos: CGVector){
    
    // Update line A
    let closest_on_a = distance(self.pos, line_a.a) < distance(self.pos, line_a.b)
    let move_on_a = closest_on_a ? line_a.a : line_a.b
    let stable_on_a = closest_on_a ? line_a.b : line_a.a
    
    let scale_on_a = distance(move_on_a, self.pos)
    let new_on_a = pos + ((pos - stable_on_a).normalized() * scale_on_a)
    
    closest_on_a ? line_a.move(new_on_a, line_a.b) : line_a.move(line_a.a, new_on_a);
    
    // Update Line B
    let closest_on_b = distance(self.pos, line_b.a) < distance(self.pos, line_b.b)
    let move_on_b = closest_on_b ? line_b.a : line_b.b
    let stable_on_b = closest_on_b ? line_b.b : line_b.a
    
    let scale_on_b = distance(move_on_b, self.pos)
    let new_on_b = pos + ((pos - stable_on_b).normalized() * scale_on_b)
    
    closest_on_b ? line_b.move(new_on_b, line_b.b) : line_b.move(line_b.a, new_on_b);
    
    self.pos = pos
  }
}

class SurfaceControlPoint: ControlPoint {
  var pos: CGVector
  var points: [ControlPoint] = []
  
  var down_point = CGVector()
  
  init(_ points: [ControlPoint]) {
    self.points = points
    self.pos = pointcloud_center(points.map({$0.pos}))
  }
  
  func grab(_ pos: CGVector){
    down_point = pos
    for p in points {
      p.grab(pos)
    }
  }
  
  func move(_ pos: CGVector) {
    let delta = pos - down_point
    
    for p in points {
      p.move(pos)
    }
    
    //update_center()
  }
  
  func update_center(){
    self.pos = pointcloud_center(points.map({$0.pos}))
  }
}

class Fill {
  let loop: [String]
  let color: Color
  
  init(_ loop: [String], _ color: Color) {
    self.loop = loop
    self.color = color
  }
}


// Page
class Page {
  var morphable_strokes: [MorphableStroke] = []
  
  // Dragging mode info
  var dragging_point: ControlPoint? = nil
  
  var control_points: [ControlPoint] = []
  var end_control_points: [EndControlPoint] = []
  var cluster_control_points: [ClusterControlPoint] = []
  var intersection_control_points: [IntersectionControlPoint] = []
  
  var cluster_loop_ids: [[String]] = []
  
  var fills: [Fill] = []
  
  func add_stroke(_ stroke: [CGVector], color: Color) {
    morphable_strokes.append(contentsOf: split_stroke_into_morphable_strokes(stroke, color: color))
    
    update_abstract_model()
  }
  
  func add_fill(_ pos: CGVector, _ color: Color) {
    let closest_surface = find_closest_surface(pos)
    if let closest_surface = closest_surface {
      let ids = closest_surface.map { cp in cp.id }
      fills.append(Fill(ids, color))
    }
  }
  
  func down_pencil(_ pos: CGVector){
    // Check if we tapped on a point
    
    var dragging_point_index = closest_point_in_collection(points: control_points.map({$0.pos}), point: pos, min_dist: 15.0)
    if dragging_point_index > -1 {
      dragging_point = control_points[dragging_point_index]
      dragging_point!.grab(pos)
      return
    }
    
    // Check if we tapped a line so we can pull it appart
    dragging_point_index = closest_point_in_collection(points: end_control_points.map({$0.pos}), point: pos, min_dist: 30.0)
    if dragging_point_index > -1 {
      dragging_point = end_control_points[dragging_point_index]
      dragging_point!.grab(pos)
      return
    }
    
    // Check if we tapped a surface
    let closest_surface = find_closest_surface(pos)
    if let closest_surface = closest_surface {
      dragging_point = SurfaceControlPoint(closest_surface)
      dragging_point!.grab(pos)
    }
    
    
  }
  
  func move_pencil(_ pos: CGVector){
    if let dragging_point = dragging_point {
      dragging_point.move(pos)
    }
  }
  
  func up_pencil() {
    dragging_point = nil
    update_abstract_model()
  }
  
  func find_closest_surface(_ pos: CGVector) -> [ClusterControlPoint]? {
    // Check if we tapped on a surface and find the smallest surface area
    var closest_surface_index: Int? = nil
    var surface_area: CGFloat = 1000000000
    
    // Find clusterpoints for each loop
    let cluster_point_loops = cluster_loop_ids.map { cluster_loop in
      cluster_loop.map { id in
        cluster_control_points.first(where: { cp in
          cp.id == id
        })!
      }
    }
    
    // Find the smallest loop that i've tapped
    for (loop_index, loop) in cluster_point_loops.enumerated() {
      let loop_pts = loop.map { cp in cp.pos }
      if is_point_in_polygon(pos, loop_pts) {
        let area = polygon_area(loop_pts + [loop_pts[0]])
        if area < surface_area {
          closest_surface_index = loop_index
          surface_area = area
        }
      }
    }
    
    if closest_surface_index == nil {
      return nil
    }
    return cluster_point_loops[closest_surface_index!]
  }
  
  
  func update_abstract_model(){
    MONOTONIC_IDS = 0;
    
    // Find all control points
    
    end_control_points = []
    var lines: [MorphableLine] = []
    
    for stroke in morphable_strokes {
      if case let .Line(line) = stroke {
        let a = EndControlPoint(line: line, start: true)
        let b = EndControlPoint(line: line, start: false)
        a.connected_to = b
        b.connected_to = a
        end_control_points.append(a)
        end_control_points.append(b)
        lines.append(line)
      }
    }
    
    cluster_control_points = generate_cluster_control_points(end_control_points)
    intersection_control_points = intersect_lines(lines)
    
    // Cluster control points
    control_points = (intersection_control_points as [ControlPoint] + cluster_control_points as [ControlPoint])
   
    // Construct a graph from clusters and intersections
    let graph = ConnectivityGraph()
    
    // Loop through pairs of cluster_points
    for i in 0..<cluster_control_points.count {
      let points_connected_to_i = Set(cluster_control_points[i].points.map({ $0.connected_to!.id }))
      
      for j in i+1..<cluster_control_points.count {
        let points_in_j = Set(cluster_control_points[j].points.map({ $0.id }))
        
        if points_connected_to_i.intersection(points_in_j).count > 0 {
          graph.add_edge(i, j)
        }
      }
    }
    
    if graph.nodes_count() > 0 {
      let loops = graph.get_base_cycles_disconnected()
      cluster_loop_ids = loops.map { loop in
        loop.map { index in
          cluster_control_points[index].id
        }
      }
    }
  }
  
  func undo(){
    if morphable_strokes.count > 0 {
      morphable_strokes.remove(at: morphable_strokes.count - 1)
      update_abstract_model()
    }
  }
  
  func render(_ renderer: Renderer) {
    var data: [Vertex] = []
    
    for fill in fills {
      let pts = fill.loop.map({id in
        cluster_control_points.first(where: {cp in cp.id == id})!.pos
      })
      renderer.addShapeData(polyFillShape(points: pts, color: fill.color))
    }
    
    for stroke in morphable_strokes {
      var points: [CGVector] = []
      var color: Color = Color(0, 0, 0)
      switch stroke {
        case let .Line(line):
          points = line.points
          color = line.color
        case let .Bezier(curve):
          points = curve.points
          color = curve.color
      }
      
      let first = points.first!
      data.append(Vertex(position: SIMD3(Float(first.dx), Float(first.dy), 1.0), color: color.as_simd_transparent()))
      for pt in points {
        data.append(Vertex(position: SIMD3(Float(pt.dx), Float(pt.dy), 1.0), color: color.as_simd()))
      }
      let last = points.last!
      data.append(Vertex(position: SIMD3(Float(last.dx), Float(last.dy), 1.0), color: color.as_simd_transparent()))
      
    }
    
    renderer.addStrokeData(data)

  }
  
  func render_control_points(_ renderer: Renderer){
    for cp in control_points {
      renderer.addShapeData(circleShape(pos: cp.pos, radius: 4.0, resolution: 8, color: GUIDE_COLOR))
    }
//
//    for ip in intersection_points {
//      renderer.addShapeData(circleShape(pos: ip.intersection, radius: 4.0, resolution: 8, color: Color(0,255,0)))
//    }
  }
}

func split_stroke_into_morphable_strokes(_ stroke: [CGVector], color: Color) -> [MorphableStroke] {
  
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
        morphable_strokes.append(MorphableStroke.Bezier(MorphableBezier(a: curve_accumulator.first!, b: CGVector(), c: CGVector(), d: curve_accumulator.last!, points: curve_accumulator, color: color)))
        curve_accumulator = []
      }
      // Append the current segment as a line
      morphable_strokes.append(MorphableStroke.Line(MorphableLine(a: segment.first!, b: segment.last!, points: segment, color: color)))
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
    morphable_strokes.append(MorphableStroke.Bezier(MorphableBezier(a: curve_accumulator.first!, b: CGVector(), c: CGVector(), d: curve_accumulator.last!, points: curve_accumulator, color: color)))
  }
  
  return morphable_strokes
}


func generate_cluster_control_points(_ points: [EndControlPoint]) -> [ClusterControlPoint] {
  var clusters: [ClusterControlPoint] = []
  
  // Create a cluster for each individual point
  for i in 0..<points.count {
    let a = points[i]
    clusters.append(ClusterControlPoint([a]))
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
