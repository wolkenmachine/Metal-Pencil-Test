//
//  MultiGestureRecognizer.swift
//  MetalTest
//
//  Created by Marcel on 20/06/2022.
//

import UIKit

typealias TouchId = Int

enum TouchEventType {
  case Begin
  case Move
  case Predict
  case End
}

enum TouchType {
  case Pencil
  case Finger
}

struct TouchEvent {
  let id: TouchId
  let type: TouchType
  let event_type: TouchEventType
  let pos: CGVector
  let force: CGFloat?
}

class MultiGestureRecognizer: UIGestureRecognizer {
  var buffer: [TouchEvent] = []
  
  var viewRef: ViewController!

  override init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)

    // allows pen + touch input at the same time
    requiresExclusiveTouchType = false
  }
  
  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    
    for touch in touches {
      let pos = CGVector(point: touch.preciseLocation(in: view))
      let id = Int(bitPattern: Unmanaged.passUnretained(touch).toOpaque())
      
      if touch.type == .pencil {
        buffer.append(TouchEvent(id: id, type: TouchType.Pencil, event_type: TouchEventType.Begin, pos: pos, force: touch.force))
      } else {
        buffer.append(TouchEvent(id: id, type: TouchType.Finger, event_type: TouchEventType.Begin, pos: pos, force: nil))
      }
    }
  }

  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    for touch in touches {
      let id = Int(bitPattern: Unmanaged.passUnretained(touch).toOpaque())
      
      if let coalesced = event.coalescedTouches(for: touch) {
        for touch in coalesced {
          let pos = CGVector(point: touch.preciseLocation(in: view))
          if touch.type == .pencil {
            buffer.append(TouchEvent(id: id, type: TouchType.Pencil, event_type: TouchEventType.Move, pos: pos, force: touch.force))
          } else {
            buffer.append(TouchEvent(id: id, type: TouchType.Finger, event_type: TouchEventType.Move, pos: pos, force: nil))
          }
        }
      }

      if let predicted = event.predictedTouches(for: touch) {
        for touch in predicted {
          let pos = CGVector(point: touch.preciseLocation(in: view))
          if touch.type == .pencil {
            buffer.append(TouchEvent(id: id, type: TouchType.Pencil, event_type: TouchEventType.Predict, pos: pos, force: touch.force))
          } else {
            buffer.append(TouchEvent(id: id, type: TouchType.Finger, event_type: TouchEventType.Predict, pos: pos, force: nil))
          }
        }
      }
    }
  }

  public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    for touch in touches {
      let id = Int(bitPattern: Unmanaged.passUnretained(touch).toOpaque())
      let pos = CGVector(point: touch.preciseLocation(in: view))
      if touch.type == .pencil {
        buffer.append(TouchEvent(id: id, type: TouchType.Pencil, event_type: TouchEventType.End, pos: pos, force: touch.force))
      } else {
        buffer.append(TouchEvent(id: id, type: TouchType.Finger, event_type: TouchEventType.End, pos: pos, force: nil))
      }
    }
  }

  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    for touch in touches {
      let id = Int(bitPattern: Unmanaged.passUnretained(touch).toOpaque())
      let pos = CGVector(point: touch.preciseLocation(in: view))
      if touch.type == .pencil {
        buffer.append(TouchEvent(id: id, type: TouchType.Pencil, event_type: TouchEventType.End, pos: pos, force: touch.force))
      } else {
        buffer.append(TouchEvent(id: id, type: TouchType.Finger, event_type: TouchEventType.End, pos: pos, force: nil))
      }
    }
  }
}
