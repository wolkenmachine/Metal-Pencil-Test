  //
//  ViewController.swift
//  MetalTest
//
//  Created by Marcel on 20/06/2022.
//

import UIKit
import MetalKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {
  var metalView: MTKView {
    return view as! MTKView
  }
  
  var renderer: Renderer!
  var debugInfo: UITextView!
  var previousFrameTime: Date = Date()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Load GuestureRecognizer
    let multiGestureRecognizer = MultiGestureRecognizer(target: nil, action: nil)
    multiGestureRecognizer.delegate = self
    multiGestureRecognizer.viewRef = self
    metalView.addGestureRecognizer(multiGestureRecognizer)
    
    // Load Renderer
    renderer = Renderer(metalView: metalView)
    renderer.viewRef = self
    
    // Application logic
    precomputeCircle()
    setup()
    
    // Add debug view
    debugInfo = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    debugInfo.text = "FPS: 0"
    debugInfo.font = UIFont.systemFont(ofSize:14)
    debugInfo.center = CGPoint(x: 100, y: 50);
    metalView.addSubview(debugInfo)
  }
  
  // THIS IS WHERE THE MAGIC HAPPEN 👇
  
  // Compute stroke
  var done_strokes: [TapeStroke] = []
  
  var tape_stroke: TapeStroke? = nil
  var string_stroke: StringStroke? = nil
  
  var fingers = 0;
  var fingerDown = CGVector(dx:0,dy:0)
  var fingerDropped = CGVector(dx:0,dy:0)
  
  var pencilDown = CGVector(dx:0,dy:0)
  
  var fingerDownTimer = 0
  
  var mode = "Tape"
  
  func setup(){
  }
  
  // Pencil event handlers
  func onPencilDown(pos: CGPoint, force: CGFloat){
    var down = CGVector(point: pos)
    if mode == "Tape" {
      if (fingerDown - down).length() < 100 {
        tape_stroke = TapeStroke(down)
      }
    } else if mode == "String" {
      if (fingerDown - down).length() < 100 {
        string_stroke = StringStroke(down)
      }
    } else if mode == "InvTape" {
      if (fingerDown - down).length() < 100 {
        tape_stroke = TapeStroke(down)
      }
    }
  }
  
  func onPencilMove(pos: CGPoint, force: CGFloat){
    pencilDown = CGVector(point: pos)
    
    if mode == "Tape" {
      if let tape_stroke = tape_stroke {
        tape_stroke.move_pencil(CGVector(point: pos))
        tape_stroke.move_finger(fingerDown)
      }
    } else if mode == "String" {
      if let string_stroke = string_stroke {
        string_stroke.move_pencil(CGVector(point: pos))
      }
    } else if mode == "InvTape" {
      if let tape_stroke = tape_stroke {
        tape_stroke.move_finger(CGVector(point: pos))
        tape_stroke.move_pencil(fingerDown)
      }
    }

  }
  
  func onPencilPredicted(pos: CGPoint, force: CGFloat){
    onPencilUp(pos: pos, force: force)
  }
  
  func onPencilUp(pos: CGPoint, force: CGFloat){
    
  }
  
  var selected_points: [(Int, Int)] = []
  
  func onTouchDown(pos: CGPoint){
    fingers += 1;
    fingerDown = CGVector(point: pos)
    fingerDropped = CGVector(point: pos)
    fingerDownTimer = 0
    
    if fingers == 5 {
      if mode == "Tape" {
        mode = "String"
      } else if mode == "String" {
        mode = "InvTape"
      } else if mode == "InvTape" {
        mode = "Tape"
      }
    }
    //tape_stroke = TapeStroke(CGVector(point: pos))
  }
  
  func onTouchMove(pos: CGPoint){
    fingerDown = CGVector(point: pos)
    
    if mode == "Tape" {
      if let tape_stroke = tape_stroke {
        tape_stroke.move_finger(CGVector(point: pos))
      }
    } else if mode == "String" {
      if (fingerDown - fingerDropped).length() > 10 {
        if let string_stroke = string_stroke {
          string_stroke.move_finger(CGVector(point: pos))
        }
      }
    } else if mode == "InvTape" {
      if let tape_stroke = tape_stroke {
        tape_stroke.move_pencil(CGVector(point: pos))
      }
    }
  }
  
  func onTouchPredicted(pos: CGPoint){
    onTouchMove(pos: pos)
  }
  
  func onTouchUp(pos: CGPoint){
    
    if let tape_stroke = tape_stroke {
      done_strokes.append(tape_stroke)
    }
    
    tape_stroke = nil
    string_stroke = nil
    fingers -= 1;
  }
  
  // Draw Loop
  func draw(){
    let dt = Date().timeIntervalSince(previousFrameTime)
    let fps = (1000 / dt * 1000).rounded()
    previousFrameTime = Date()
    debugInfo.text = "FPS: \(fps)\nFINGERS: \(fingers)\n\(mode)"
    
    if fingerDownTimer < 200 {
      fingerDownTimer = fingerDownTimer + Int(dt*1000)
    }
    
    // Reset the render buffer
    renderer.clearBuffer()
    
    if let tape_stroke = tape_stroke {
      renderer.addGeometry(geometry: tape_stroke.get_geometry())
      if tape_stroke.trace.count > 1 {
        renderer.addGeometry(geometry: tape_stroke.get_trace_geometry())
      }
    }
    
    if (fingers > 0) {
      if let tape_stroke = tape_stroke {
        
        renderer.addGeometry(geometry: strokeGeometry(points: [
          mode == "Tape" ? fingerDown: pencilDown,
          tape_stroke.start
        ], weight: 1.0, color: [0.5,0.1,0.1,0.1]))
      } else {
        renderer.addGeometry(geometry: circleGeometry(pos: fingerDown, radius: (Float(fingerDownTimer) / 200) * 100, color: [0.5,0.1,0.1,0.1]))
      }
    }
    
    if let string_stroke = string_stroke {
      renderer.addGeometry(geometry: string_stroke.get_geometry())
    }
    
    for s in done_strokes {
      renderer.addGeometry(geometry: s.get_trace_geometry())
    }
    
    
  }
}
