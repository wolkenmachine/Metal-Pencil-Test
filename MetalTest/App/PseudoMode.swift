//
//  PseudoMode.swift
//  MetalTest
//
//  Created by Marcel on 18/08/2022.
//

import Foundation
import UIKit

// System that keeps track of the current Pseudomode

enum PseudoMode {
  case Draw
  case Drag
}

class PseudoModeManager {
  var mode = PseudoMode.Draw
  var finger_id = 0
  
  
  func down_finger(_ id: TouchId, _ pos: CGVector){
    if mode == PseudoMode.Draw {
      if pos.dx < 100 && pos.dy > 720 {
        mode = PseudoMode.Drag
        finger_id = id
      }
    }
  }
  
  func lift_finger(_ id: TouchId) {
    if(mode == PseudoMode.Drag && finger_id == id) {
      mode = PseudoMode.Draw
    }
  }
}
