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
  
  var active_stroke = ActiveStroke()
  var static_guide = StaticGuide()
  
  var dry_ink: [[CGVector]] = []
//  var done_strokes: [TapeStroke] = []
//
//  var tape_stroke: TapeStroke? = nil
//
  var fingers = 0;
//  var fingerDown = CGVector(dx:0,dy:0)
//  var fingerDropped = CGVector(dx:0,dy:0)
//
//  var pencilDown = CGVector(dx:0,dy:0)
//
//  var fingerDownTimer = 0
//
//  var mode = "Tape"
//
  func setup(){
  }
  
  // Pencil event handlers
  func onPencilDown(pos: CGPoint, force: CGFloat){
    let pos = CGVector(point: pos)
    active_stroke.start_stroke()
    active_stroke.move_stroke(pos: pos)
  }
  
  func onPencilMove(pos: CGPoint, force: CGFloat){
    let pos = CGVector(point: pos)
    active_stroke.move_stroke(pos: pos)
  }
  
  func onPencilPredicted(pos: CGPoint, force: CGFloat){
    //onPencilMove(pos: pos, force: force)
  }
  
  func onPencilUp(pos: CGPoint, force: CGFloat){
    let pos = CGVector(point: pos)
    active_stroke.move_stroke(pos: pos)
    let done_stroke = active_stroke.end_stroke()
    dry_ink.append(done_stroke)
  }
  
  var selected_points: [(Int, Int)] = []
  
  func onTouchDown(pos: CGPoint, id: Int){
    let pos = CGVector(point: pos)
    active_stroke.move_control_point(pos: pos, id: id)
    
    static_guide.start_control_point(pos: pos, id: id)
    static_guide.move_control_point(pos: pos, id: id)
  }
  
  func onTouchMove(pos: CGPoint, id: Int){
    let pos = CGVector(point: pos)
    active_stroke.move_control_point(pos: pos, id: id)
    static_guide.move_control_point(pos: pos, id: id)
  }
  
  func onTouchPredicted(pos: CGPoint, id: Int){
    onTouchMove(pos: pos, id: id)
  }
  
  func onTouchUp(pos: CGPoint, id: Int){
    active_stroke.end_control_point(id: id)
    static_guide.end_control_point(id: id)
  }
  
  // Draw Loop
  func draw(){
    let dt = Date().timeIntervalSince(previousFrameTime)
    let fps = (1000 / dt * 1000).rounded()
    previousFrameTime = Date()
    debugInfo.text = "FPS: \(fps)\nMODE:\(active_stroke.mode)"
    
    
    renderer.clearBuffer()
    
    
    
    for ink in dry_ink {
      renderer.addGeometry(geometry: strokeGeometry(points: ink, weight: 1.0, color: [0,0,0,1]))
    }
    
    if(active_stroke.current_trace.count > 1) {
      renderer.addGeometry(geometry: strokeGeometry(points: active_stroke.current_trace, weight: 1.0, color: [0,0,0,1]))
    }
    
    if(active_stroke.mode == "Guide"){
      // Compute guide line
      let offset = (active_stroke.last_pencil - active_stroke.last_control_point) * 1000.0
      
      renderer.addGeometry(geometry: strokeGeometry(points: [
        active_stroke.last_pencil + offset,
        active_stroke.last_pencil - offset,
      ], weight: 1.0, color: [1.0,0,0.5,1.0]))
      
      renderer.addGeometry(geometry: circleGeometry(pos: active_stroke.last_pencil, radius: 3.0, color: [1.0,0,0.5,1.0]))
      renderer.addGeometry(geometry: circleGeometry(pos: active_stroke.last_control_point, radius: 3.0, color: [1.0,0,0.5,1.0]))
    }
    
    if static_guide.active == true {
      //let offset = (static_guide.curve_points[0].1 - static_guide.curve_points[1].1) * 1000.0
      renderer.addGeometry(geometry: strokeGeometry(points: static_guide.line, weight: 1.0, color: [1.0,0,0.5,1.0]))
      
      
      for cp in static_guide.curve_points {
        renderer.addGeometry(geometry: circleGeometry(pos: cp.1, radius: 3.0, color: [1.0,0,0.5,1.0]))
      }
      
//      renderer.addGeometry(geometry: circleGeometry(pos: static_guide.curve_points[1].1, radius: 3.0, color: [1.0,0,0.5,1.0]))
    }
    
    
  }
}
