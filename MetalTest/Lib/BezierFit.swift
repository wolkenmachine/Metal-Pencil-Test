////
////  BezierFit.swift
////  MetalTest
////
////  Created by Marcel on 22/07/2022.
////
//
////  Algorithm for Automatically Fitting Digitized Curves
////  by Philip J. Schneider
////  "Graphics Gems", Academic Press, 1990
//
////  The MIT License (MIT)
////  Ported from: https://github.com/soswow/fit-curves
//
//import Foundation
//import UIKit
//
//struct BezierCurve {
//  var a: CGVector
//  var b: CGVector
//  var c: CGVector
//  var d: CGVector
//}
//
//func bezier_fit(_ points: [CGVector], max_error: CGFloat) -> [BezierCurve] {
//  if points.count < 2 {
//    return []
//  }
//  
//  let len = points.count
//  let left_tangent = create_tangent(points[1], points[0])
//  let right_tangent = create_tangent(points[len - 2], points[len - 1])
//  
//  
//  return fit_cubic(points: points, left_tangent: left_tangent, right_tangent: right_tangent, error: max_error)
//}
//
//func fit_cubic(points: [CGVector], left_tangent: CGVector, right_tangent: CGVector, error: CGFloat) -> [BezierCurve] {
//  let max_iterations = 20
//  
//  var curve: BezierCurve
//  var dist: CGFloat
//  
////  var bez_curve
////  u, u_prime, max_error, prev_error, split_point, prev_split, center_vector, to_center_tangent;
//  
//  
//  // Use heuristic if region has only two points
//  if points.count == 2 {
//    dist = (points[0] - points[1]).length() / 3.0
//    curve = BezierCurve(
//      a: points[0],
//      b: points[0] + left_tangent * dist,
//      c: points[1] + right_tangent * dist,
//      d: points[1]
//    )
//    return [curve]
//  }
//  
//  // Parameterize points and attempt to fit curve
//  let u: [CGFloat] = chord_length_parameterize(points: points)
//  generate_and_report(points: points, params_orig: u, params_prime: u, left_tangent: left_tangent, right_tangent: right_tangent)
//  
//  
//}
//
//// Create a tangent from two points
//func create_tangent(_ a: CGVector, _ b: CGVector) -> CGVector {
//  return (a - b).normalized()
//}
//
//// Assign parameter values to digitized points using relative distances between points.
//func chord_length_parameterize(points: [CGVector]) -> [CGFloat] {
//  var u: [CGFloat] = []
//  var prevU: CGFloat
//  var prevP: CGVector
//  
//  for (i, p) in points.enumerated() {
//    let currU = i != 0 ? prevU + distance(p, prevP)
//                   : 0
//    u.append(currU)
//
//    prevU = currU
//    prevP = p
//  }
//  
//  u = u.map({x in x / prevU})
//
//  return u
//}
//
//func generate_and_report(points: [CGVector], params_orig: [CGFloat], params_prime: [CGFloat], left_tangent: CGVector, right_tangent: CGVector){
//  
//  let curve = generate_bezier(points: points, params: params_prime, left_tangent: left_tangent, right_tangent: right_tangent)
//  
//}
//
//func generate_bezier(points: [CGVector], params: [CGFloat], left_tangent: CGVector, right_tangent: CGVector) {
//  
//}
