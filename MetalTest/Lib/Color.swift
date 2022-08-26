//
//  Color.swift
//  MetalTest
//
//  Created by Marcel on 21/07/2022.
//

import Foundation

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
