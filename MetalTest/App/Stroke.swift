//
//  Stroke.swift
//  MetalTest
//
//  Created by Marcel on 18/08/2022.
//

import Foundation
import UIKit

class Stroke {
  var points: [CGVector]
  var color: Color
  var verts: [Vertex]
  
  init(_ points: [CGVector], _ color: Color) {
    self.points = points
    self.color = color
    self.verts = []
    update_verts()
  }
  
  func update_verts(){
    self.verts = self.points.map({
      pt in Vertex(position: SIMD3(Float(pt.dx), Float(pt.dy), 1.0), color: color.as_simd())
    })
  }
  
  func render(_ renderer: Renderer) {
    renderer.addStrokeData(verts);
  }
}
