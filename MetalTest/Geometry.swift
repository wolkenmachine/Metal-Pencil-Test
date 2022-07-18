//
//  Geometry.swift
//  MetalTest
//
//  Created by Marcel on 24/06/2022.
//

import Foundation
import UIKit

let circleFactor = (Float.pi*2)/16
var circlePoints: [SIMD3<Float>] = []

func precomputeCircle() {
  for i in 0..<16 {
    circlePoints.append(SIMD3<Float>(cos(Float(i)*circleFactor) , sin(Float(i)*circleFactor), 0))
  }
}

func circleGeometryAA(pos: CGPoint, radius: Float, color: [Float]) -> Geometry {
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

func circleGeometry(pos: CGVector, radius: Float, color: [Float]) -> Geometry {
  var verts: [Vertex] = []
  var indices: [UInt16] = []
  
  let x = Float(pos.dx)
  let y = Float(pos.dy)
  
  // Draw anti_alisassed circle
  let base_color = SIMD4<Float>(color[0], color[1], color[2], color[3])
  
  verts.append(Vertex(position: SIMD3<Float>(x, y, 0), color: base_color))
  
  for v in circlePoints {
    verts.append(Vertex(position: SIMD3<Float>(x + v.x*radius , y + v.y*radius, 0), color: base_color))
  }
  
  for i in 0..<16 {
    indices.append(UInt16(0))
    indices.append(UInt16((i%16)+1))
    indices.append(UInt16((i+1)%16+1))
  }
  
  return Geometry (verts: verts, indices: indices)
}

func lineGeometry(a: CGVector, b: CGVector, weight: CGFloat, color: [Float]) -> Geometry {
  
  let color = SIMD4<Float>(color[0], color[1], color[2], color[3])
  
  let diff = (a - b).normalized() * CGFloat(weight) // line thickness
  let left_offset = diff.rotated90clockwise()
  let right_offset = diff.rotated90counterclockwise()
  
  let la = a + left_offset
  let ra = a + right_offset
  let lb = b + left_offset
  let rb = b + right_offset
  
  
  var verts: [Vertex] = [
    Vertex(position: [Float(la.dx), Float(la.dy), 0], color: color),
    Vertex(position: [Float(ra.dx), Float(ra.dy), 0], color: color),
    Vertex(position: [Float(lb.dx), Float(lb.dy), 0], color: color),
    Vertex(position: [Float(rb.dx), Float(rb.dy), 0], color: color),
  ]
  
  var indices: [UInt16] = [
    0,1,2,
    2,3,1,
  ]
  
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

func polygonGeometry(points: [CGVector]){
  
}

func triangulate(_ points: [CGVector]) -> [Int] {
  if points.count < 3 {
    return []
  }
  
  // Should be sure that lines don't overlap (No figure 8 for example)
  // Edges shouldn't be colinear (We can remove those up front)
  // Winding order should be clockwise
  
  
  var indices: [Int] = Array(0..<points.count)
  var triangles: [Int] = []
  
  print("indices", indices)
  
  while indices.count > 3 {
    for i in 0..<indices.count {
      let a = indices[i]
      let b = getCycleElement(indices, i-1)
      let c = getCycleElement(indices, i+1)
      
      print("trying", a,b,c)
      
      let va = points[a]
      let vb = points[b]
      let vc = points[c]
      
      let vab = vb - va
      let vac = vc - va
      
      // Check if ear is Convex or Reflex, if reflex skip
      print("checking convexity")
      if cross(vac, vab) < 0 {
        continue;
      }
      
      print("convex")
      
      // Check if anything lies inside of this triangle
      var isEar = true;
      
      print("checking is ear")
      for j in 0..<indices.count {
        if j == a || j == b || j == c {
          continue
        }
        
        let p = points[j]
        if isPointInTriangle(p: p, a: vb, b: va, c: vc) {
          isEar = false
          break
        }
      }
      
      // If it is an ear, add it to the triangle list
      if isEar {
        print("isEar")
        triangles.append(b)
        triangles.append(a)
        triangles.append(c)
        indices.remove(at: i)
        break
      }
    }
  }
  
  triangles.append(indices[0])
  triangles.append(indices[1])
  triangles.append(indices[2])
  
  
  return triangles
}



func getCycleElement(_ points: [Int], _ index: Int) -> Int {
  if index >= points.count {
    return points[index % points.count]
  } else if index < 0 {
    return points[index % points.count + points.count]
  } else {
    return points[index]
  }
}


func isPointInTriangle(p: CGVector, a: CGVector, b: CGVector, c: CGVector) -> Bool {
  let ab = b - a
  let bc = c - b
  let ca = a - c
  
  let ap = p - a
  let bp = p - b
  let cp = p - c
  
  let cross1 = cross(ab, ap)
  let cross2 = cross(bc, bp)
  let cross3 = cross(ca, cp)
  
  if cross1 > 0 || cross2 > 0 || cross3 > 0 {
    return false
  }
  
  return true
}

//RDP Line Simplification Algorithm -- Enhanced
//struct KeyPoint {
//  var position: CGVector
//  var index: Int
//  var order: Int
//  var isCorner: Bool
//}
//
//func RDP_Simplify_Two(line:[CGVector], order: Int = 0, offset: Int = 0) -> [KeyPoint] {
//  let start = line.first!
//  let end = line.last!
//  
//  if line.count == 2 {
//    print("count == 2")
//    let a = KeyPoint(position: start, index: 0, order: order, isCorner: false)
//    let b = KeyPoint(position: end, index: line.count-1, order: order, isCorner: false)
//    return [a, b]
//  }
//  
//  var largestDistance: CGFloat = -1;
//  var furthestIndex = -1;
//  
//  for i in 1..<line.count {
//    let point = line[i]
//    let dist = PointLineDistance(p:point, a:start, b:end)
//    if dist > largestDistance {
//      largestDistance = dist
//      furthestIndex = i
//    }
//  }
//  
//  if(largestDistance > 5) {
//    print("split", order)
//    let a = KeyPoint(position: start, index: offset, order: order, isCorner: false)
//    let b = KeyPoint(position: line[furthestIndex], index: furthestIndex, order: order+1, isCorner: false)
//    let c = KeyPoint(position: end, index: offset + line.count-1, order: order, isCorner: false)
//    //return [a, b, c]
//    
//    let segment_a = RDP_Simplify_Two(line: Array(line[...furthestIndex]), order: order+1, offset: offset)
//    let segment_b = RDP_Simplify_Two(line: Array(line[furthestIndex...]), order: order+1, offset: offset+furthestIndex)
//
//    let a_end = segment_a.count-1
//    let b_end = segment_b.count-1
//    return [a] + Array(segment_a[1..<a_end]) + [b] + Array(segment_b[1..<b_end]) + [c]
//  }
//  
//  print("no split", order)
//  let a = KeyPoint(position: start, index: offset, order: order, isCorner: false)
//  let c = KeyPoint(position: end, index: offset + line.count-1, order: order, isCorner: false)
//  return [a, c]
//}

//func CreateKeyPoint(line: [CGVector], position: Int, order: Int) -> KeyPoint {
//  var corner = false;
//  if(position == 0 || position == line.count-1) {
//    corner = true
//  } else {
//    
//  }
//  
//  KeyPoint(position: line[position], index: position, order: order, isCorner: false)
//}


//RDP Line Simplification Algorithm
func RDP_Simplify(line:[CGVector]) -> [CGVector] {
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
  
  if(largestDistance > 5) {
    let segment_a = RDP_Simplify(line: Array(line[...furthestIndex]))
    let segment_b = RDP_Simplify(line: Array(line[furthestIndex...]))
    
    return segment_a + segment_b[1...]
  }
  return [start, end]
}


func FindFurthestOnLine(line:[CGVector], a: Int, b: Int) -> Int {
  var largestDistance: CGFloat = -1;
  var furthestIndex = -1;
  
  let start = line[a]
  let end = line[b]
  
  for i in a+1..<b {
    let point = line[i]
    let dist = PointLineDistance(p:point, a:start, b:end)
    if dist > largestDistance {
      largestDistance = dist
      furthestIndex = i
    }
  }
  
  // Epsilon is max distance from line
  if(largestDistance > 1) {
    return furthestIndex
  }
  return -1
}

func Lineness(line: [CGVector]) -> CGFloat {
  let start = line.first!
  let end = line.last!
  
  var total_dist: CGFloat = 0
  for p in line {
    let dist = PointLineDistance(p: p, a: start, b: end)
    total_dist += dist
  }
  
  return total_dist / CGFloat(line.count)
}

func PointLineDistance(p:CGVector, a:CGVector, b:CGVector) -> CGFloat {
  let norm = ScalarProjection(p: p, a: a, b: b)
  return (p - norm).length()
}

func ScalarProjection(p:CGVector, a:CGVector, b:CGVector) -> CGVector{
  let ap = p - a
  let ab = (b - a).normalized()
  let f = ab * dot(ap, ab)
  return a + f
}
