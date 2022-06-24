//
//  Geometry.swift
//  MetalTest
//
//  Created by Marcel on 24/06/2022.
//

import Foundation
import UIKit

let circleFactor = (Float.pi*2)/32
var circlePoints: [SIMD3<Float>] = []

func precomputeCircle() {
  for i in 0...31 {
    circlePoints.append(SIMD3<Float>(cos(Float(i)*circleFactor) , sin(Float(i)*circleFactor), 0))
  }
}

func circleGeometry(pos: CGPoint, radius: Float, color: [Float]) -> Geometry {
  var verts: [Vertex] = []
  var indices: [UInt16] = []
  
  let x = Float(pos.x)
  let y = Float(pos.y)
  
  // Draw anti_alisassed circle
  let base_color = SIMD4<Float>(color[0], color[1], color[2], 1)
  let transparent_color = SIMD4<Float>(color[0], color[1], color[2], 0)
  
  verts.append(Vertex(position: SIMD3<Float>(x, y, 0), color: base_color))
  
  for v in circlePoints {
    verts.append(Vertex(position: SIMD3<Float>(x + v.x*radius , y + v.y*radius, 0), color: base_color))
  }
  
  let aa_radius = radius + 0.5
  for v in circlePoints {
    verts.append(Vertex(position: SIMD3<Float>(x + v.x*aa_radius , y + v.y*aa_radius, 0), color: transparent_color))
  }
  
  for i in 0...31 {
    indices.append(UInt16(0))
    indices.append(UInt16((i%32)+1))
    indices.append(UInt16((i+1)%32+1))
  }
  
  for i in 0...31 {
      indices.append(UInt16((i%32)   + 1))
      indices.append(UInt16((i+1)%32 + 1))
      indices.append(UInt16((i%32)   + 33))
    
      indices.append(UInt16((i%32)   + 33))
      indices.append(UInt16((i+1)%32 + 33))
      indices.append(UInt16((i+1)%32 + 1))
  }
  
  return Geometry (verts: verts, indices: indices)
}


func strokeGeometry(points: [CGPoint], weight: Float, color: [Float]) -> Geometry {
  var verts: [Vertex] = []
  var indices: [UInt16] = []
  var points = points
  var indexOffset = UInt16(0)
  
  let base_color = SIMD4<Float>(color[0], color[1], color[2], 1)
  let transparent_color = SIMD4<Float>(color[0], color[1], color[2], 0)
  
  var lastPoint = CGVector(point: points[0])
  points.removeFirst()
  
  verts += [
    Vertex(position: [Float(lastPoint.dx), Float(lastPoint.dy), 0], color: base_color),
    Vertex(position: [Float(lastPoint.dx), Float(lastPoint.dy), 0], color: base_color)
  ]
  
  for point in points {
    let newPoint = CGVector(point: point)
    let diff = (newPoint - lastPoint).normalized() * CGFloat(weight) // line thickness
    let left_offset = newPoint + diff.rotated90clockwise()
    let right_offset = newPoint + diff.rotated90counterclockwise()

    verts += [
      Vertex(position: [Float(right_offset.dx), Float(right_offset.dy), 0], color: base_color),
      Vertex(position: [Float(left_offset.dx), Float(left_offset.dy), 0], color: base_color),
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
