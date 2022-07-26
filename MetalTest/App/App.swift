//
//  App.swift
//  MetalTest
//
//  Created by Marcel on 21/07/2022.
//

import Foundation
import UIKit

class PseudoMode {
  var mode = "Draw"
  var finger_id = 0
  
  
  func down_finger(_ id: TouchId, _ pos: CGVector){
    if mode == "Draw" {
      if pos.dx < 100 && pos.dy > 720 {
        mode = "Drag"
        finger_id = id
      }
    }
  }
  
  func lift_finger(_ id: TouchId) {
    if(mode == "Drag" && finger_id == id) {
      mode = "Draw"
    }
  }
}

class App {
  var active_pencil: CGVector?  = nil
  var active_fingers: [TouchId: CGVector] = [:]
  
  var drawing_stroke: DrawingStroke? = nil
  var page: Page = Page()
  
  var active_guide: Guide? = nil
  
  var pseudo_mode = PseudoMode()
  
  func setup(){
    
  }
  
  func update(touches: [TouchEvent]){
    // Deal with all the touches
    for touch in touches {
      // Collect active fingers into a dictionary,
      if touch.type == .Finger {
        switch touch.event_type {
          case .End:
            active_fingers[touch.id] = nil
            pseudo_mode.lift_finger(touch.id)
            if let active_guide = active_guide {
              active_guide.lift_finger(touch.id)
            }
          default:
            active_fingers[touch.id] = touch.pos
            if let active_guide = active_guide {
              active_guide.move_finger(touch.id, touch.pos)
            }
        }
        
        if touch.event_type == .Begin {
          pseudo_mode.down_finger(touch.id, touch.pos)
        }
      }
      
      // Pencil interactions
      else if touch.type == .Pencil {
        var pos = touch.pos
        if let active_guide = active_guide {
          pos = active_guide.get_closest_point(pos)
        }
        active_pencil = touch.pos
        
        if pseudo_mode.mode == "Draw" {
          switch touch.event_type {
            case .Begin:
              drawing_stroke = DrawingStroke(pos)
              
            case .Move:
              drawing_stroke!.add_point(pos)
              if let active_guide = active_guide {
                active_guide.move_pencil(pos)
              }
            case .Predict:
              drawing_stroke!.add_predicted_point(pos)
              if let active_guide = active_guide {
                active_guide.move_pencil(pos)
              }
            case .End:
              page.add_stroke(drawing_stroke!.points)
              drawing_stroke = nil
          }
        }
        
        if pseudo_mode.mode == "Drag" {
          switch touch.event_type {
            case .Begin:
              page.down_pencil(touch.pos)
            case .Move:
              page.move_pencil(touch.pos)
            case .Predict:
              page.move_pencil(touch.pos)
            case .End:
              page.up_pencil()
          }
        }
        
        if touch.event_type == .End {
          active_pencil = nil
        }
      }
    }
    
    if pseudo_mode.mode == "Draw" {
      // Instantiate guides
      if active_guide == nil {
        active_guide = instantiate_dynamic_guide(fingers: active_fingers, pencil: active_pencil)
      }
      
      if active_guide == nil {
        active_guide = instantiate_static_guide(fingers: active_fingers, pencil: active_pencil)
      }
    }
    
    if active_guide != nil {
      if active_guide!.should_destruct(fingers: active_fingers, pencil: active_pencil) {
        active_guide = nil
      }
    }
  }
  
  func draw(renderer: Renderer){
    if let drawing_stroke = drawing_stroke {
      renderer.addStrokeData(drawing_stroke.get_stroke_data())
    }
    
    page.render(renderer)
    if pseudo_mode.mode == "Drag" {
      page.render_control_points(renderer)
    }
    
    if let active_guide = active_guide {
      active_guide.render(renderer)
    }
  }
}
