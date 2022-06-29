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
