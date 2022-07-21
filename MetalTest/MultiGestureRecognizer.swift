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
    
    for touch in touches {
      let location = touch.preciseLocation(in: view)
      let id = Int(bitPattern: Unmanaged.passUnretained(touch).toOpaque())
      
      if touch.type == .pencil {
        viewRef.onPencilDown(pos: location, force: touch.force)
      } else {
        viewRef.onTouchDown(pos: location, id: id)
      }
    }
  }

  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    for touch in touches {
      let id = Int(bitPattern: Unmanaged.passUnretained(touch).toOpaque())
      
      if let coalesced = event.coalescedTouches(for: touch) {
        for touch in coalesced {
          let location = touch.preciseLocation(in: view)
          if touch.type == .pencil {
            viewRef.onPencilMove(pos: location, force: touch.force)
          } else {
            viewRef.onTouchMove(pos: location, id: id)
          }
        }
      }

      if let predicted = event.predictedTouches(for: touch) {
        for touch in predicted {
          let location = touch.preciseLocation(in: view)
          if touch.type == .pencil {
            viewRef.onPencilPredicted(pos: location, force: touch.force)
          } else {
            viewRef.onTouchPredicted(pos: location, id: id)
          }
        }
      }
    }
  }

  public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    for touch in touches {
      let id = Int(bitPattern: Unmanaged.passUnretained(touch).toOpaque())
      let location = touch.preciseLocation(in: view)
      if touch.type == .pencil {
        viewRef.onPencilUp(pos: location, force: touch.force)
      } else {
        viewRef.onTouchUp(pos: location, id: id)
      }
    }
  }

  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    for touch in touches {
      let id = Int(bitPattern: Unmanaged.passUnretained(touch).toOpaque())
      let location = touch.preciseLocation(in: view)
      if touch.type == .pencil {
        viewRef.onPencilUp(pos: location, force: touch.force)
      } else {
        viewRef.onTouchUp(pos: location, id: id)
      }
    }
  }
}
