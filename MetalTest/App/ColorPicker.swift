//
//  ColorPicker.swift
//  MetalTest
//
//  Created by Marcel on 27/07/2022.
//

import Foundation
import UIKit

class ColorPicker {
  let colors: [Color]
  
  var current_color: Color
  
  var active: Bool
  var did_pick: Bool
  var down_pencil: CGVector?
  var dragging_color: CGVector?
  
  init() {
    colors = [
      Color(0,18,25),
      Color(44,150,210),
      Color(148,210,189),
      Color(236,156,0),
      Color(213,39,28),
    ]
    current_color = colors[0]
    active = false
    did_pick = true
    dragging_color = nil
    down_pencil = nil
  }
  
  func render(_ renderer: Renderer){
    if active {
      for (i, color) in colors.enumerated() {
        renderer.addShapeData(circleShape(pos: CGVector(dx: 1160, dy: 800 - i * 50), radius: 20.0, resolution: 16, color: color))
      }
    } else {
      if let dragging_color = dragging_color {
        renderer.addShapeData(circleShape(pos: dragging_color, radius: 20.0, resolution: 16, color: current_color))
      } else {
        renderer.addShapeData(circleShape(pos: CGVector(dx: 1160, dy: 800), radius: 20.0, resolution: 16, color: current_color))
      }
      
    }
  }
  
  func down_pencil(_ pos: CGVector) -> Bool {
    if active == false {
      if distance(CGVector(dx: 1160, dy: 800), pos) < 30 {
        active = true
        did_pick = false
        return true
      }
    } else {
      for (i, color) in colors.enumerated() {
        let color_pos = CGVector(dx: 1160, dy: 800 - i * 50)
        if distance(color_pos, pos) < 25 {
          current_color = color
          did_pick = true
          down_pencil = color_pos
        }
      }
      
      return true
    }
    return false
  }
  
  func move_pencil(_ pos: CGVector) {
    if let down_pencil = down_pencil {
      if distance(down_pencil, pos) > 20 {
        dragging_color = pos
        active = false
        did_pick = true
      }
    }
    
  }
  
  func up_pencil(_ pos: CGVector) -> Bool {    
    if did_pick {
      did_pick = false
      active = false
      down_pencil = nil
      dragging_color = nil
      return true
    }
  
    return false
  }
  
  
}
