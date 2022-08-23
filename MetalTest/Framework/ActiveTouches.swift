//
//  ActiveTouches.swift
//  MetalTest
//
//  Created by Marcel on 18/08/2022.
//

import Foundation
import UIKit

// Collect currently active touches in a datastructure

class ActiveTouches {
  var pencil: CGVector?  = nil
  var fingers: [TouchId: CGVector] = [:]
  
  func update(touches: [TouchEvent]) {
    for touch in touches {
      // Collect active fingers into a dictionary,
      if touch.type == .Finger {
        switch touch.event_type {
          case .End:
            fingers[touch.id] = nil
          default:
            fingers[touch.id] = touch.pos
        }
      } else { // Put active pencil
        switch touch.event_type {
          case .End:
            pencil = nil
          default:
            pencil = touch.pos
        }
      }
    }
  }
}
