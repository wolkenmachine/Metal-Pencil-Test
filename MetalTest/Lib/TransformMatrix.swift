//
//  TransformMatrix.swift
//  MetalTest
//
//  Created by Marcel on 01/07/2022.
//

import Foundation
import UIKit

class TransformMatrix {
  var a = CGFloat(1);
  var b = CGFloat(0);
  var c = CGFloat(0);
  var d = CGFloat(1);
  var e = CGFloat(0);
  var f = CGFloat(0);
  
  func transform(_ a2: CGFloat, _ b2: CGFloat, _ c2: CGFloat, _ d2: CGFloat, _ e2: CGFloat, _ f2: CGFloat) {
    let a1 = a
    let b1 = b
    let c1 = c
    let d1 = d
    let e1 = e
    let f1 = f

    a = a1 * a2 + c1 * b2
    b = b1 * a2 + d1 * b2
    c = a1 * c2 + c1 * d2
    d = b1 * c2 + d1 * d2
    e = a1 * e2 + c1 * f2 + e1
    f = b1 * e2 + d1 * f2 + f1
  }
  
  func rotate(angle: CGFloat) {
    let cos = cos(angle)
    let sin = sin(angle)
    transform(cos, sin, -sin, cos, 0, 0)
  }
  
  func scale(sx: CGFloat, sy: CGFloat) {
    transform(sx, 0, 0, sy, 0, 0)
  }
  
  func skew(sx: CGFloat, sy: CGFloat) {
    transform(1, sy, sx, 1, 0, 0)
  }

  func translate(tx: CGFloat, ty: CGFloat) {
    transform(1, 0, 0, 1, tx, ty)
  }

  func flip_x(){
    transform(-1, 0, 0, 1, 0, 0)
  }

  func flip_y(){
    transform(1, 0, 0, -1, 0, 0)
  }
  
  //STATELESS TRANSFORMS
  func get_inverse() -> TransformMatrix{
    let m = TransformMatrix()
    let dt = (a * d - b * c)

    m.a = d / dt
    m.b = -b / dt
    m.c = -c / dt
    m.d = a / dt
    m.e = (c * f - d * e) / dt
    m.f = -(a * f - b * e) / dt

    return m
  }
  
  func transform_matrix(_ m2: TransformMatrix) -> TransformMatrix {
    let a1 = a
    let b1 = b
    let c1 = c
    let d1 = d
    let e1 = e
    let f1 = f

    let a2 = m2.a
    let b2 = m2.b
    let c2 = m2.c
    let d2 = m2.d
    let e2 = m2.e
    let f2 = m2.f

    let m = TransformMatrix()
    m.a = a1 * a2 + c1 * b2
    m.b = b1 * a2 + d1 * b2
    m.c = a1 * c2 + c1 * d2
    m.d = b1 * c2 + d1 * d2
    m.e = a1 * e2 + c1 * f2 + e1
    m.f = b1 * e2 + d1 * f2 + f1

    return m
  }
  
  func transform_vector(_ p: CGVector) -> CGVector {
    let x = p.dx
    let y = p.dy

    return CGVector(
      dx: x * a + y * c + e,
      dy: x * b + y * d + f
    )
  }
  
  func from_line(_ a: CGVector, _ b: CGVector){
    let line = b - a
    
    translate(tx: a.dx, ty: a.dy)
    rotate(angle: line.angle())
  }
}
