//
//  MultiGestureRecognizer.swift
//  MetalTest
//
//  Created by Marcel on 20/06/2022.
//

import UIKit

class MultiGestureRecognizer: UIGestureRecognizer {
  var touches: [String: UITouch] = [:]
  
  var viewRef: ViewController!

  override init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)

    // allows pen + touch input at the same time
    requiresExclusiveTouchType = false
  }

  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    //multipleTouchesToJSON(type: "began", touches: touches, event: event)
    for touch in touches {
      let location = touch.preciseLocation(in: view)
      if touch.type == .pencil {
        viewRef.onPencilDown(pos: location)
      }
    }
  }

  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    for touch in touches {
      //let location = touch.preciseLocation(in: view)
      
      if let coalesced = event.coalescedTouches(for: touch) {
        for touch in coalesced {
          let location = touch.preciseLocation(in: view)
          if touch.type == .pencil {
            viewRef.onPencilMove(pos: location)
          }
        }
      }

      if let predicted = event.predictedTouches(for: touch) {
        for touch in predicted {
          let location = touch.preciseLocation(in: view)
          if touch.type == .pencil {
            viewRef.onPencilPredicted(pos: location)
          }
        }
      }
    }
  }

//  public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
//    print("touchesCancelled")
//    //multipleTouchesToJSON(type: "cancelled", touches: touches, event: event)
//  }

  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    for touch in touches {
      let location = touch.preciseLocation(in: view)
      if touch.type == .pencil {
        viewRef.onPencilUp(pos: location)
      }
    }
  }
}
