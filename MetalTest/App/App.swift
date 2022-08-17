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
  
  var color_picker = ColorPicker()
  
  func setup(){
    triangulate_polygon([
      CGVector(dx: 10, dy: 10),
      CGVector(dx: 50, dy: 10),
      CGVector(dx: 50, dy: 50),
      CGVector(dx: 10, dy: 50),
    ])
    
    triangulate_polygon([
      CGVector(dx: 10, dy: 50),
      CGVector(dx: 50, dy: 50),
      CGVector(dx: 50, dy: 10),
      CGVector(dx: 10, dy: 10),
    ])
    
    triangulate_polygon([
      CGVector(dx: 50, dy: 50),
      CGVector(dx: 150, dy: 50),
      CGVector(dx: 50, dy: 200),
      CGVector(dx: 20, dy: 30),
    ])
    
    
    triangulate_polygon([
      CGVector(dx: 772, dy: 316),
      CGVector(dx: 833, dy: 188),
      CGVector(dx: 713, dy: 113),
      CGVector(dx: 606, dy: 237),
    ])
    
    
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
          
          if active_fingers.count == 5 {
            page.undo()
          }
        }
      }
      
      // Pencil interactions
      else if touch.type == .Pencil {
        var pos = touch.pos
          
        // UI Interactions
        var did_ui_interaction = false;
        switch touch.event_type {
          case .Begin:
            did_ui_interaction = color_picker.down_pencil(touch.pos)
          case .End:
            if color_picker.up_pencil(touch.pos) {
              did_ui_interaction = true
              page.add_fill(touch.pos, color_picker.current_color)
            }
          case .Move:
            color_picker.move_pencil(touch.pos)
          case .Predict:
            color_picker.move_pencil(touch.pos)
          default:
            break
        }
        
        if did_ui_interaction {
          break
        }
        
        // Canvas interactions
        if let active_guide = active_guide {
          pos = active_guide.get_closest_point(pos)
        }
        active_pencil = touch.pos
        
        if pseudo_mode.mode == "Draw" {
          switch touch.event_type {
            case .Begin:
            drawing_stroke = DrawingStroke(pos, color_picker.current_color)
            case .Move:
              if let drawing_stroke = drawing_stroke {
                drawing_stroke.add_point(pos)
                if let active_guide = active_guide {
                  active_guide.move_pencil(pos)
                }
              }
            case .Predict:
              if let drawing_stroke = drawing_stroke {
                drawing_stroke.add_predicted_point(pos)
                if let active_guide = active_guide {
                  active_guide.move_pencil(pos)
                }
              }
            case .End:
              if let drawing_stroke = drawing_stroke {
                page.add_stroke(drawing_stroke.points, color: drawing_stroke.color)
              }
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
    
    color_picker.render(renderer)
  }
}
