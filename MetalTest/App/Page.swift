//
//  Page.swift
//  MetalTest
//
//  Created by Marcel on 21/07/2022.
//

import Foundation
import UIKit

class Page {
  var strokes: [[CGVector]] = []
  
  func add_stroke(_ stroke: [CGVector]) {
    strokes.append(stroke)
  }
  
  func get_stroke_data() -> [Vertex] {
    var data: [Vertex] = []
    
    for stroke in strokes {
      let first = stroke.first!
      data.append(Vertex(position: SIMD3(Float(first.dx), Float(first.dy), 1.0), color: SIMD4(0,0,0,0)))
      for pt in stroke {
        data.append(Vertex(position: SIMD3(Float(pt.dx), Float(pt.dy), 1.0), color: SIMD4(0,0,0,1)))
      }
      let last = stroke.last!
      data.append(Vertex(position: SIMD3(Float(last.dx), Float(last.dy), 1.0), color: SIMD4(0,0,0,0)))
    }
    
    return data
  }
}
