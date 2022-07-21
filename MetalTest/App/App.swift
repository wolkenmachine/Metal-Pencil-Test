//
//  App.swift
//  MetalTest
//
//  Created by Marcel on 21/07/2022.
//

import Foundation
import UIKit

class App {
  var active_pencil: CGVector?  = nil
  var active_fingers: [TouchId: CGVector] = [:]
  
  var drawing_stroke: DrawingStroke? = nil
  var page: Page = Page()
  
  var active_guide: Guide? = nil
  
  
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
            if let active_guide = active_guide {
              active_guide.lift_finger(touch.id)
            }
          default:
            active_fingers[touch.id] = touch.pos
            if let active_guide = active_guide {
              active_guide.move_finger(touch.id, touch.pos)
            }
        }
      }
      
      // Pencil interactions
      else if touch.type == .Pencil {
        var pos = touch.pos
        if let active_guide = active_guide {
          pos = active_guide.get_closest_point(pos)
        }
        
        switch touch.event_type {
          case .Begin:
            active_pencil = touch.pos
            drawing_stroke = DrawingStroke(pos)
          case .Move:
            active_pencil = touch.pos
            drawing_stroke!.add_point(pos)
            if let active_guide = active_guide {
              active_guide.move_pencil(pos)
            }
          case .Predict:
            active_pencil = pos
            drawing_stroke!.add_predicted_point(pos)
            if let active_guide = active_guide {
              active_guide.move_pencil(pos)
            }
          case .End:
            page.add_stroke(drawing_stroke!.points)
            drawing_stroke = nil
            active_pencil = nil
        }
      }
    }
    
    // Instantiate guides
    if active_guide == nil {
      active_guide = instantiate_dynamic_guide(fingers: active_fingers, pencil: active_pencil)
    }
    
    if active_guide == nil {
      active_guide = instantiate_static_guide(fingers: active_fingers, pencil: active_pencil)
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
    
    if page.strokes.count > 0 {
      renderer.addStrokeData(page.get_stroke_data())
    }
    
    if let active_guide = active_guide {
      active_guide.render(renderer)
    }
  }
}
