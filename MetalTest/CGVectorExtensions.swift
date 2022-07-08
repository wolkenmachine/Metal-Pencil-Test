//
//  CGVectorExtensions.swift
//  Untangle
//
//  Created by Marcel on 13/04/2022.
//
// Copy pasta from: https://github.com/raywenderlich/SKTUtils/blob/master/SKTUtils/CGVector%2BExtensions.swift

import CoreGraphics

public extension CGVector {
  /**
   * Creates a new CGVector given a CGPoint.
   */
  init(point: CGPoint) {
    self.init(dx: point.x, dy: point.y)
  }
  
  /**
   * Given an angle in radians, creates a vector of length 1.0 and returns the
   * result as a new CGVector. An angle of 0 is assumed to point to the right.
   */
  init(angle: CGFloat) {
    self.init(dx: cos(angle), dy: sin(angle))
  }

  /**
   * Adds (dx, dy) to the vector.
   */
  mutating func offset(dx: CGFloat, dy: CGFloat) -> CGVector {
    self.dx += dx
    self.dy += dy
    return self
  }

  /**
   * Returns the length (magnitude) of the vector described by the CGVector.
   */
  func length() -> CGFloat {
    return sqrt(dx*dx + dy*dy)
  }

  /**
   * Returns the squared length of the vector described by the CGVector.
   */
  func lengthSquared() -> CGFloat {
    return dx*dx + dy*dy
  }

  /**
   * Normalizes the vector described by the CGVector to length 1.0 and returns
   * the result as a new CGVector.
  */
  func normalized() -> CGVector {
    let len = length()
    return len>0 ? self / len : CGVector.zero
  }

  /**
   * Normalizes the vector described by the CGVector to length 1.0.
   */
  mutating func normalize() -> CGVector {
    self = normalized()
    return self
  }

  /**
   * Calculates the distance between two CGVectors. Pythagoras!
   */
  func distanceTo(_ vector: CGVector) -> CGFloat {
    return (self - vector).length()
  }

  /**
   * Returns the angle in radians of the vector described by the CGVector.
   * The range of the angle is -π to π; an angle of 0 points to the right.
   */
  func angle() -> CGFloat {
    return atan2(dy, dx)
  }
  
  func angleBetween(_ other: CGVector) -> CGFloat {
    let len_a = self.length()
    let len_b = other.length()
    
    
    let angle = acos((dot(self, other)) / (len_a * len_b))
    return angle
  }
  
  /**
   * Returns a vector that is rotated 90 degrees clockwise
   */
  func rotated90clockwise() -> CGVector {
    return CGVector(dx: self.dy, dy: -self.dx)
  }
  
  /**
   * Returns a vector that is rotated 90 degrees clockwise
   */
  func rotated90counterclockwise() -> CGVector {
    return CGVector(dx: -self.dy, dy: self.dx)
  }
  
  func rotated(angle: CGFloat) -> CGVector {
    let c = cos(angle)
    let s = sin(angle)
    return CGVector(dx: self.dx*c - self.dy*s, dy: self.dx*s + self.dy*c)
  }

}

/**
 * Adds two CGVector values and returns the result as a new CGVector.
 */
public func + (left: CGVector, right: CGVector) -> CGVector {
  return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
}

/**
 * Increments a CGVector with the value of another.
 */
public func += (left: inout CGVector, right: CGVector) {
  left = left + right
}

/**
 * Subtracts two CGVector values and returns the result as a new CGVector.
 */
public func - (left: CGVector, right: CGVector) -> CGVector {
  return CGVector(dx: left.dx - right.dx, dy: left.dy - right.dy)
}

/**
 * Decrements a CGVector with the value of another.
 */
public func -= (left: inout CGVector, right: CGVector) {
  left = left - right
}

/**
 * Multiplies two CGVector values and returns the result as a new CGVector.
 */
public func * (left: CGVector, right: CGVector) -> CGVector {
  return CGVector(dx: left.dx * right.dx, dy: left.dy * right.dy)
}

/**
 * Multiplies a CGVector with another.
 */
public func *= (left: inout CGVector, right: CGVector) {
  left = left * right
}

/**
 * Multiplies the x and y fields of a CGVector with the same scalar value and
 * returns the result as a new CGVector.
 */
public func * (vector: CGVector, scalar: CGFloat) -> CGVector {
  return CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
}

/**
 * Multiplies the x and y fields of a CGVector with the same scalar value.
 */
public func *= (vector: inout CGVector, scalar: CGFloat) {
  vector = vector * scalar
}

/**
 * Divides two CGVector values and returns the result as a new CGVector.
 */
public func / (left: CGVector, right: CGVector) -> CGVector {
  return CGVector(dx: left.dx / right.dx, dy: left.dy / right.dy)
}

/**
 * Divides a CGVector by another.
 */
public func /= (left: inout CGVector, right: CGVector) {
  left = left / right
}

/**
 * Divides the dx and dy fields of a CGVector by the same scalar value and
 * returns the result as a new CGVector.
 */
public func / (vector: CGVector, scalar: CGFloat) -> CGVector {
  return CGVector(dx: vector.dx / scalar, dy: vector.dy / scalar)
}

/**
 * Divides the dx and dy fields of a CGVector by the same scalar value.
 */
public func /= (vector: inout CGVector, scalar: CGFloat) {
  vector = vector / scalar
}

/**
 * Performs a linear interpolation between two CGVector values.
 */
public func lerp(start: CGVector, end: CGVector, t: CGFloat) -> CGVector {
  return start + (end - start) * t
}

public func dot(_ a: CGVector, _ b: CGVector) -> CGFloat {
  return a.dx * b.dx + a.dy * b.dy
}

public func line_line_intersection(_ a: CGVector, _ b: CGVector, _ c: CGVector, _ d: CGVector) -> CGVector? {
  
  let x1 = a.dx
  let y1 = a.dy
  let x2 = b.dx
  let y2 = b.dy
  let x3 = c.dx
  let y3 = c.dy
  let x4 = d.dx
  let y4 = d.dy
  
  let x12 = x1 - x2;
  let x34 = x3 - x4;
  let y12 = y1 - y2;
  let y34 = y3 - y4;

  let div = x12 * y34 - y12 * x34;

  if (abs(div) < 0.2) {
    return nil;
  }
  else {
    // Intersection
    let a = x1 * y2 - y1 * x2;
    let b = x3 * y4 - y3 * x4;

    let x = (a * x34 - b * x12) / div;
    let y = (a * y34 - b * y12) / div;

    return CGVector(dx: x, dy: y);
  }
}

//public func cross(_ a: CGVector, _ b: CGVector) -> CGFloat {
//  
//}
