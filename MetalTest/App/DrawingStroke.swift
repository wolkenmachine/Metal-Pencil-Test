//
//  DrawingStroke.swift
//  MetalTest
//
//  Created by Marcel on 21/07/2022.
//

import Foundation
import UIKit

// Drawing stroke collects points while drawing
class DrawingStroke {
  var points: [CGVector] = []
  var predicted_points: [CGVector] = []
  var color: Color
  
  init(_ pos: CGVector, _ color: Color){
    points = [pos]
    predicted_points = []
    self.color = color
  }
  
  func add_point(_ pos: CGVector){
    points.append(pos)
  }
  
  func add_predicted_point(_ pos: CGVector){
    predicted_points.append(pos)
  }
  
  // Resets predicted points
  func get_stroke_data() -> [Vertex] {
    let joined_points = points + predicted_points
    predicted_points = []
    
    return joined_points.map({
      pt in Vertex(position: SIMD3(Float(pt.dx), Float(pt.dy), 1.0), color: color.as_simd())
    })
  }
}
