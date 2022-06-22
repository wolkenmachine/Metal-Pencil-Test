//
//  MultiGestureRecognizer.swift
//  MetalTest
//
//  Created by Marcel on 20/06/2022.
//

import UIKit

class MultiGestureRecognizer: UIGestureRecognizer {
  var touches: [String: UITouch] = [:]
  
  var viewRef: ViewController?

  override init(target: Any?, action: Selector?) {
    super.init(target: target, action: action)

    // allows pen + touch input at the same time
    //requiresExclusiveTouchType = false
  }

//  private func touchToDict(touch: UITouch) -> [String: Any] {
//    let location = touch.preciseLocation(in: view)
//    let azimuth = touch.azimuthAngle(in: view)
//
//    var type = "touch"
//
//    if touch.type == .pencil {
//      type = "pencil"
//    } else if touch.type == .stylus {
//      type = "stylus"
//    }
//
//    return [
//      "x": location.x,
//      "y": location.y,
//      "timestamp": touch.timestamp,
//      "altitude": touch.altitudeAngle,
//      "azimuth": azimuth,
//      "radius": touch.majorRadius,
//      "force": touch.force,
//      "type": type,
//    ]
//  }
//
//  private func getTouchKey(touch: UITouch) -> String {
//    let interpolation = "\(touch)"
//    let parts = interpolation.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
//    let touchKey = String(parts[1].dropLast())
//    return touchKey
//  }
//
//  private func multipleTouchesToJSON(type: String, touches: Set<UITouch>, event: UIEvent) {
//    var dict: [String: [Any]] = Dictionary()
//
//    if type == "began" {
//      for touch in touches {
//        let key = getTouchKey(touch: touch)
//        self.touches[key] = touch
//      }
//    }
//
//    for touch in touches {
//      let key = getTouchKey(touch: touch)
//      dict[key] = []
//
//      if let coalesced = event.coalescedTouches(for: touch) {
//        for touch in coalesced {
//          dict[key]?.append(touchToDict(touch: touch))
//        }
//      } else {
//        dict[key]?.append(touchToDict(touch: touch))
//      }
//
//      if let predicted = event.predictedTouches(for: touch) {
//        for predictedTouch in predicted {
//          dict[key]?.append(touchToDict(touch: predictedTouch))
//        }
//      }
//    }
//
//    if type == "cancelled" || type == "ended" {
//      for touch in touches {
//        let key = getTouchKey(touch: touch)
//        self.touches.removeValue(forKey: key)
//      }
//    }
//
//    dump(dict)
//    //viewRef?.constants.x =
//    //let json = try? JSONSerialization.data(withJSONObject: dict, options: [])
//    //let jsonString = String(data: json!, encoding: String.Encoding.utf8)
//
//    //webView?.evaluateJavaScript("window.nativeEvent && window.nativeEvent(\"" + type + "\", " + jsonString! + ")", completionHandler: nil)
//  }

  public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    //print("touchesBegan")
    //multipleTouchesToJSON(type: "began", touches: touches, event: event)
    for touch in touches {
      let location = touch.preciseLocation(in: view)
      viewRef?.newLine(x: location.x, y: location.y)
    }
  }

  public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    print("touchedMoved")
    
    for touch in touches {
      let location = touch.preciseLocation(in: view)
      //viewRef?.addPoint(x: location.x, y: location.y)
      
      if let coalesced = event.coalescedTouches(for: touch) {
        for touch in coalesced {
          let location = touch.preciseLocation(in: view)
          
          viewRef?.addPoint(x: location.x, y: location.y, width: touch.force)
          print("coalesced")
        }
      }

      if let predicted = event.predictedTouches(for: touch) {
        for touch in predicted {
          let location = touch.preciseLocation(in: view)
          viewRef?.setPotentialFuturePoint(x: location.x, y: location.y)
          print("predicted")
        }
      }
    }
  }

  public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    //print("touchesCancelled")
    //multipleTouchesToJSON(type: "cancelled", touches: touches, event: event)
  }

  public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    //print("touchesEnded")
    for touch in touches {
      let location = touch.preciseLocation(in: view)
      viewRef?.addPoint(x: location.x, y: location.y, width: 1)
    }
  }
}
