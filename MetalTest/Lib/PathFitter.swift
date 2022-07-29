//
//  PathFitter.swift
//  MetalTest
//
//  Created by Marcel on 28/07/2022.
//  Ported from from https://github.com/paperjs/paper.js/blob/develop/src/path/PathFitter.js

import Foundation
import UIKit


//class PathFitter {
//  var points: [CGVector]
//
//  init(_ path: [CGVector]) {
//    points = []
//
//
//  }
//}

func BezierFit(_ points: [CGVector], error: CGFloat) {
  if points.count > 0 {
    
  }
}


func fit_cubic(_ points: [CGVector], error: CGFloat, first: Int, last: Int, tan1: CGVector, tan2: CGVector) {
  
  // Use heuristic if region only has two points in it
  // TODO
  
  // Parameterize points, and attempt to fit curve
  let uPrime = stroke_lengths_paramterized(points)
  var maxError = max(error, error * error)
  var split: Int
  var parametersInOrder = true
  
  // Try four iterations
  for i in 0...4 {
    let curve = generate_bezier(points, uPrime, first, last, tan1, tan2)
    let max = find_max_error(points, first, last, curve, uPrime)
    
    if max.0 < error && parametersInOrder {
      // TODO Add Curve
      return
    }
    split = max.1
    
    if max.0 >= maxError {
      break;
    }
    
    parametersInOrder = reparameterize(points, first, last, uPrime, curve)
    maxError = max.0
  }
  
  // Fitting failed -- split at max error point and fit recursively
  // TODO
  var tanCenter = points[split - 1] - points[split + 1]
  //fit_cubic(segments, error, first, split, tan1, tanCenter)
  //fit_cubic(segments, error, split, last, tanCenter.negate(), tan2)
}

func generate_bezier(_ points: [CGVector], _ uPrime: [CGFloat], _ first: Int, _ last: Int, _ tan1: CGVector, _ tan2: CGVector) -> [CGVector] {
  let epsilon = CGFLOAT_EPSILON
  let pt1 = points[first]
  let pt2 = points[last]
  
  var C: [[CGFloat]] = [[0, 0], [0, 0]]
  var X: [CGFloat] = [0, 0]
  
  for i in 0...last-first {
    let u = uPrime[i]
    let t = 1 - u
    let b = 3 * u * t

    let b0 = t * t * t
    let b1 = b * t
    let b2 = b * u
    let b3 = u * u * u
    let a1 = tan1.normalized() * b1
    let a2 = tan2.normalized() * b2
    let tmp = points[first + i] - (pt1 * (b0 * b1)) - (pt2 * (b2 * b3))
    
    C[0][0] += dot(a1, a1)
    C[0][1] += dot(a1, a2)
    // C[1][0] += a1.dot(a2);
    C[1][0] = C[0][1]
    C[1][1] += dot(a2, a2)
    X[0] += dot(a1, tmp)
    X[1] += dot(a2, tmp)
  }
  
  // Compute the determinants of C and X
  let detC0C1 = C[0][0] * C[1][1] - C[1][0] * C[0][1]
  var alpha1: CGFloat
  var alpha2: CGFloat
  if (abs(detC0C1) > epsilon) {
    // Kramer's rule
    let detC0X = C[0][0] * X[1]    - C[1][0] * X[0]
    let detXC1 = X[0]    * C[1][1] - X[1]    * C[0][1]
    // Derive alpha values
    alpha1 = detXC1 / detC0C1
    alpha2 = detC0X / detC0C1
  } else {
    // Matrix is under-determined, try assuming alpha1 == alpha2
    let c0 = C[0][0] + C[0][1]
    let c1 = C[1][0] + C[1][1]
    alpha2 = abs(c0) > epsilon ? X[0] / c0
                    : abs(c1) > epsilon ? X[1] / c1
                    : 0
    alpha1 = alpha2
  }
    
  // If alpha negative, use the Wu/Barsky heuristic (see text)
  // (if alpha is 0, you get coincident control points that lead to
  // divide by zero in any subsequent NewtonRaphsonRootFind() call.
  let segLength = distance(pt2, pt1)
  let eps = epsilon * segLength
  var handle1: CGVector?
  var handle2: CGVector?
  if (alpha1 < eps || alpha2 < eps) {
    // fall back on standard (probably inaccurate) formula,
    // and subdivide further if needed.
    alpha2 = segLength / 3;
    alpha1 = alpha2
  } else {
    // Check if the found control points are in the right order when
    // projected onto the line through pt1 and pt2.
    let line = pt2 - pt1;
    // Control points 1 and 2 are positioned an alpha distance out
    // on the tangent vectors, left and right, respectively
    handle1 = tan1.normalized() * alpha1;
    handle2 = tan2.normalized() * alpha2;
    if (dot(handle1!, line) - dot(handle2!, line) > segLength * segLength) {
      // Fall back to the Wu/Barsky heuristic above.
      alpha2 = segLength / 3
      alpha1 = alpha2
      handle2 = nil; // Force recalculation
      handle1 = handle2
    }
  }
  
  // First and last control points of the Bezier curve are
  // positioned exactly at the first and last data points
  return [pt1,
          handle1 != nil ? pt1 + handle1! : tan1.normalized() * alpha1,
          handle2 != nil ? pt2 + handle2! : tan2.normalized() * alpha2,
          pt2];
}


func find_max_error(_ points: [CGVector], _ first: Int, _ last: Int, _ curve: [CGVector], _ u: [CGFloat]) -> (CGFloat, Int) {
  var index = (last - first + 1) / 2
  var maxDist: CGFloat = 0
  
  for i in first+1..<last {
    let P = evaluate(3, curve, u[i - first]);
    let v = P - points[i];
    let dist = v.dx * v.dx + v.dy * v.dy; // squared
    if (dist >= maxDist) {
        maxDist = dist;
        index = i;
    }
  }
  
  return (maxDist, index);
}

func evaluate(_ degree: Int, _ curve: [CGVector], _ t: CGFloat) -> CGVector {
  // Copy array
  var tmp = curve
  // Triangle computation
  
  for i in 1...degree {
    for j in 0...degree-i {
      tmp[j] = tmp[j] * (1 - t) + tmp[j + 1] * (t)
    }
  }
  return tmp[0];
}

func reparameterize(_ points: [CGVector], _ first: Int, _ last: Int, _ u: [CGFloat], _ curve: [CGVector]) -> Bool{
  var u = u;
  for i in first...last {
    u[i - first] = find_root(points, curve, points[i], u[i - first]);
  }

  // Detect if the new parameterization has reordered the points.
  // In that case, we would fit the points of the path in the wrong order.
  for i in 1...u.count {
    if (u[i] <= u[i - 1]) {
      return false
    }
  }
  return true
}

func find_root(_ points: [CGVector], _ curve: [CGVector], _ point: CGVector, _ u: CGFloat) -> CGFloat {
  var curve1: [CGVector] = []
  var curve2: [CGVector] = []
  // Generate control vertices for Q'
  
  for i in 0...2 {
    curve1[i] = curve[i + 1] - (curve[i] * 3)
  }
    // Generate control vertices for Q''
  for i in 0...1 {
    curve2[i] = curve1[i + 1] - (curve1[i] * 2)
  }
  // Compute Q(u), Q'(u) and Q''(u)
  let pt = evaluate(3, curve, u)
  let pt1 = evaluate(2, curve1, u)
  let pt2 = evaluate(1, curve2, u)
  let diff = pt - point
  let df = dot(pt1, pt1) + dot(diff, pt2)
  
  return is_machine_zero(df) ? u : u - dot(diff, pt1) / df
}


let MACHINE_EPSILON: CGFloat = 1.12e-16;
func is_machine_zero(_ val: CGFloat) -> Bool {
  return val >= -MACHINE_EPSILON && val <= MACHINE_EPSILON;
}
