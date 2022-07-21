//
//  DynamicGuide.swift
//  MetalTest
//
//  Created by Marcel on 21/07/2022.
//

import Foundation
import UIKit

// Guide Protocol
protocol Guide {
  func lift_finger(_ id: TouchId)
  func move_finger(_ id: TouchId, _ pos: CGVector)
  func move_pencil(_ pos: CGVector)
  func get_closest_point(_ pos: CGVector) -> CGVector
  func should_destruct(fingers: [TouchId: CGVector], pencil: CGVector?) -> Bool
  func render(_ renderer: Renderer)
}

let GUIDE_COLOR = Color(230, 7, 126, 150)

class DynamicGuide: Guide {
  var finger_is_down = true
  var finger_id: TouchId
  var finger: CGVector
  var pencil: CGVector
  
  init(finger_id: TouchId, finger_pos: CGVector, pencil_pos: CGVector) {
    self.finger_id = finger_id
    self.finger = finger_pos
    self.pencil = pencil_pos
  }
  
  func lift_finger(_ id: TouchId) {
    if id == finger_id {
      finger_is_down = false
    }
  }
  
  func move_finger(_ id: TouchId, _ pos: CGVector){
    if finger_is_down {
      if id == finger_id {
        finger = pos
      }
    } else {
      if distance(finger, pos) < 100 {
        finger = pos
        finger_id = id
        finger_is_down = true
      }
    }
  }
  
  func move_pencil(_ pos: CGVector){
    self.pencil = pos
  }
  
  func get_closest_point(_ pos: CGVector) -> CGVector {
    return closest_point_on_line(pos, finger, pencil)
  }
  
  func should_destruct(fingers: [TouchId: CGVector], pencil: CGVector?) -> Bool {
    return pencil == nil && fingers[finger_id] == nil
  }
  
  func render(_ renderer: Renderer) {
    let offset = (finger - pencil) * 10000.0
    
    renderer.addShapeData(lineShape(a: finger + offset, b: finger - offset, weight: 1.0, color: GUIDE_COLOR))
    renderer.addShapeData(circleShape(pos: pencil, radius: 4, resolution: 8, color: GUIDE_COLOR))
    renderer.addShapeData(circleShape(pos: finger, radius: 4, resolution: 8, color: GUIDE_COLOR))
  }
}

class StaticGuide: Guide {
  var points: [CGVector] = []
  var curve: [CGVector] = []
  
  var finger_id_to_point_index: [TouchId: Int] = [:]
  
  init(finger_a_id: TouchId,  finger_a: CGVector,  finger_b_id: TouchId,  finger_b: CGVector) {
    points = [finger_a, finger_b]
    finger_id_to_point_index[finger_a_id] = 0
    finger_id_to_point_index[finger_b_id] = 1
    update_curve()
  }
  
  func lift_finger(_ id: TouchId) {
    finger_id_to_point_index[id] = nil
  }
  
  func move_finger(_ id: TouchId, _ pos: CGVector){
    if let index = finger_id_to_point_index[id] {
      points[index] = pos
    } else {
      // If the point is dangling, you're allowed to pick it up
      let i = closest_point_in_collection(points: points, point: pos, min_dist: 50)
      if i > -1 {
        if finger_id_to_point_index.someKey(forValue: i) == nil {
          finger_id_to_point_index[id] = i
        }
      } else {
        if let p = closest_point_on_curve(line: curve, point: pos, min_dist: 40) {
          points.append(p)
        }
      }
    }
    update_curve()
  }
  
  func move_pencil(_ pos: CGVector){
    // Ignore
  }
  
  func update_curve(){
    if points.count == 2 {
      let offset = (points[0] - points[1]) * 10000.0
      curve = [points[0] + offset, points[0] - offset]
    } else {
      let offseta = (points[0] - points[1]) * 10000.0
      let offsetb = (points[points.count-2] - points[points.count-1]) * 10000.0
      curve = [points[0] + offseta] + chaikin_curve(points: points) + [points[points.count-1] - offsetb]
    }
    
  }
  
  func get_closest_point(_ pos: CGVector) -> CGVector {
    if points.count == 2 {
      return closest_point_on_line(pos, points[0], points[1])
    } else {
      let closest = closest_point_on_curve(line: curve, point: pos, min_dist: 1000)
      if let closest = closest {
        return closest
      }
    }
    
    
    return pos
  }
  
  func should_destruct(fingers: [TouchId: CGVector], pencil: CGVector?) -> Bool {
    // TODO
    
    if fingers.count == 5 {
      return true
    }
    return false
  }
  
  func render(_ renderer: Renderer) {
    renderer.addShapeData(polyLineShape(points: curve, weight: 1.0, color: GUIDE_COLOR))
  
    for pt in points {
      renderer.addShapeData(circleShape(pos: pt, radius: 4, resolution: 8, color: GUIDE_COLOR))
    }
  }
}

// INSTANTIATION FUNCTIONS
func instantiate_dynamic_guide(fingers: [TouchId: CGVector], pencil: CGVector?) -> DynamicGuide? {
  if let pencil = pencil {
    for (finger_id, finger_pos) in fingers {
      if distance(finger_pos, pencil) < 100 {
        return DynamicGuide(finger_id: finger_id, finger_pos: finger_pos, pencil_pos: pencil)
      }
    }
  }
  return nil
}

func instantiate_static_guide(fingers: [TouchId: CGVector], pencil: CGVector?) -> StaticGuide? {
  
  // Iterate pairs of fingers
  let ids = Array(fingers.keys)
  for i in 0..<ids.count {
    let a = fingers[ids[i]]!
    for j in i+1..<ids.count {
      let b = fingers[ids[j]]!

      if (a - b).length() < 100 {
        //print("trigger", ids[i], ids[j])
        return StaticGuide(finger_a_id: ids[i], finger_a: a, finger_b_id: ids[j], finger_b: b)
      }
    }
  }
  return nil
}
