//
//  FitCurve.swift
//  MetalTest
//
//  Created by Marcel on 29/07/2022.
//

import Foundation
import UIKit

func FitCurve(points: [CGVector], error: CGFloat) -> [[CGVector]] {
  let leftTangent = points[1] - points[0]
  let rightTangent = points[points.count-2] - points[points.count-1]
  //FitCubic(d, 0, nPts - 1, tHat1, tHat2, error);
  return fitCubic(points, leftTangent, rightTangent, error)
}

func fitCubic(_ points: [CGVector], _ leftTangent: CGVector, _ rightTangent: CGVector, _ error: CGFloat) -> [[CGVector]] {
  // Use heuristic if region only has two points in it
  if (points.count == 2) {
    let dist = distance(points[0], points[1]) / 3.0
    let bezCurve = [points[0], points[0] + leftTangent * dist, points[1] + rightTangent * dist, points[1]]
    return [bezCurve]
  }
  
  // Parameterize points, and attempt to fit curve
  var u = chordLengthParameterize(points)
  var bezCurve = generateBezier(points, u, leftTangent, rightTangent)
  // Find max deviation of points to fitted curve
  var (maxError, splitPoint) = computeMaxError(points, bezCurve, u)
  
  if maxError < pow(error,2) {
    for i in 0...4 {
      let uPrime = reparameterize(bezCurve, points, u)
      bezCurve = generateBezier(points, uPrime, leftTangent, rightTangent)
      (maxError, splitPoint) = computeMaxError(points, bezCurve, uPrime)
      if maxError < error {
        return [bezCurve]
      }
      u = uPrime
    }
  }
      

  //Fitting failed -- split at max error point and fit recursively
  let centerTangent = (points[splitPoint-1] - points[splitPoint+1]).normalized()
  let first_slice = points[0 ..< splitPoint+1]
  let second_slice = points[splitPoint...]
  
  let a = fitCubic(Array(first_slice), leftTangent, centerTangent, error)
  let b = fitCubic(Array(second_slice), CGVector() - centerTangent, rightTangent, error)
  return a + b
}

func generateBezier(_ points: [CGVector], _ parameters: [CGFloat], _ leftTangent: CGVector, _ rightTangent: CGVector) -> [CGVector] {
  var bezCurve: [CGVector] = [points[0], CGVector(), CGVector(), points[points.count-1]]

  let pt1 = points.first!
  let pt2 = points.last!
  
  // Create the C and X matrices
  var C: [[CGFloat]] = [[0,0], [0,0]]
  var X: [CGFloat] = [0,0]
  
  for (point, u) in zip(points, parameters) {
    let t = 1 - u
    let b = 3 * u * t

    let b0 = t * t * t
    let b1 = b * t
    let b2 = b * u
    let b3 = u * u * u
    let a1 = leftTangent.normalized() * b1
    let a2 = rightTangent.normalized() * b2
    let tmp = point - (pt1 * (b0 * b1)) - (pt2 * (b2 * b3))
    
    C[0][0] += dot(a1, a1)
    C[0][1] += dot(a1, a2)
    C[1][0] = C[0][1]
    C[1][1] += dot(a2, a2)
    X[0] += dot(a1, tmp)
    X[1] += dot(a2, tmp)
  }

  // Compute the determinants of C and X
  let det_C0_C1 = C[0][0] * C[1][1] - C[1][0] * C[0][1]
  let det_C0_X  = C[0][0] * X[1] - C[1][0] * X[0]
  let det_X_C1  = X[0] * C[1][1] - X[1] * C[0][1]

  // Finally, derive alpha values
  let alpha_l = det_C0_C1==0 ? 0.0 : det_X_C1 / det_C0_C1
  let alpha_r = det_C0_C1==0 ? 0.0 : det_C0_X / det_C0_C1

  // If alpha negative, use the Wu/Barsky heuristic (see text) */
  // (if alpha is 0, you get coincident control points that lead to
  // divide by zero in any subsequent NewtonRaphsonRootFind() call. */
  let segLength = distance(points[0], points[points.count-1])
  let epsilon = 1.0e-6 * segLength

  if alpha_l < epsilon || alpha_r < epsilon {
    // fall back on standard (probably inaccurate) formula, and subdivide further if needed.
    bezCurve[1] = bezCurve[0] + leftTangent * (segLength / 3.0)
    bezCurve[2] = bezCurve[3] + rightTangent * (segLength / 3.0)
  } else {
    // First and last control points of the Bezier curve are
    // positioned exactly at the first and last data points
    // Control points 1 and 2 are positioned an alpha distance out
    // on the tangent vectors, left and right, respectively
    bezCurve[1] = bezCurve[0] + leftTangent * alpha_l
    bezCurve[2] = bezCurve[3] + rightTangent * alpha_r
  }
        
  return bezCurve
}


func chordLengthParameterize(_ points: [CGVector]) -> [CGFloat] {
  var u: [CGFloat] = [0.0]
  for i in 1..<points.count {
    u.append(u[i-1] + distance(points[i], points[i-1]))
  }
  
  for i in 1..<points.count {
    u[i] = u[i] / u[points.count-1]
  }
  return u
}

func computeMaxError(_ points: [CGVector], _ bez: [CGVector], _ parameters: [CGFloat]) -> (CGFloat, Int) {
  var maxDist = 0.0
  var splitPoint = points.count/2
  for (i, (point, u)) in zip(points, parameters).enumerated() {
    let dist = pow(distance(bezierQ(bez, u), point), 2)
    if dist > maxDist {
      maxDist = dist
      splitPoint = i
    }
  }
  
  return (maxDist, splitPoint)
}
    



func reparameterize(_ bezier: [CGVector], _ points: [CGVector], _ parameters: [CGFloat]) -> [CGFloat] {
  var output: [CGFloat] = []
  for (point, u) in zip(points, parameters) {
    output.append(newtonRaphsonRootFind(bezier, point, u))
  }
  return output
}


func newtonRaphsonRootFind(_ bez: [CGVector], _ point: CGVector, _ u: CGFloat) -> CGFloat {
  /*
   Newton's root finding algorithm calculates f(x)=0 by reiterating
   x_n+1 = x_n - f(x_n)/f'(x_n)
   We are trying to find curve parameter u for some point p that minimizes
   the distance from that point to the curve. Distance point to curve is d=q(u)-p.
   At minimum distance the point is perpendicular to the curve.
   We are solving
   f = q(u)-p * q'(u) = 0
   with
   f' = q'(u) * q'(u) + q(u)-p * q''(u)
   gives
   u_n+1 = u_n - |q(u_n)-p * q'(u_n)| / |q'(u_n)**2 + q(u_n)-p * q''(u_n)|
   */
  
  let d = bezierQ(bez, u) - point
  
  let qPrime = bezierQPrime(bez, u)
  let qPrimePrime = bezierQPrimePrime(bez, u)
  
  let numerator = (d * qPrime).sum()
  let denominator = (qPrime * qPrime + d * qPrimePrime).sum()
  
  if denominator == 0 {
    return u
  }
  return u - numerator/denominator
}


// evaluates cubic bezier at t, return point
func bezierQ(_ ctrlPoly: [CGVector], _ t: CGFloat) -> CGVector {
  let a: CGVector = ctrlPoly[0] * pow(1.0 - t, 3)
  let b: CGVector = ctrlPoly[1] * CGFloat(3.0) * pow(1.0 - t,2) * t
  let c: CGVector = ctrlPoly[2] * CGFloat(3.0) * (1.0 - t) * pow(t,2)
  let d: CGVector = ctrlPoly[3] * pow(t,CGFloat(3.0))
  
  return a + b + c + d
}

// evaluates cubic bezier first derivative at t, return point
func bezierQPrime(_ ctrlPoly: [CGVector], _ t: CGFloat) -> CGVector {
  let a = (ctrlPoly[1]-ctrlPoly[0]) * 3 * pow(1.0-t,2)
  let b = (ctrlPoly[2]-ctrlPoly[1]) * 6*(1.0-t) * t
  let c = (ctrlPoly[3]-ctrlPoly[2]) * pow(3 * t, 2)
  
  return a + b + c
}
    

// evaluates cubic bezier second derivative at t, return point
func bezierQPrimePrime(_ ctrlPoly: [CGVector], _ t: CGFloat) -> CGVector {
  let a = (ctrlPoly[2] - ctrlPoly[1] * CGFloat(2) + ctrlPoly[0]) * 6 * (1.0-t)
  let b = (ctrlPoly[3] - ctrlPoly[2] * CGFloat(2) + ctrlPoly[1]) * 6 * (t)
  return a + b
}
    

