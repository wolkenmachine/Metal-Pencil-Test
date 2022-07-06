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
  var predicted_stroke: [Vertex] = []
  var fast_strokes: [FastStroke] = []
  
  var fingers = 0;
  var mode = -1;
  var moving_stroke = -1;
  var moving_point = -1;
  
  func setup(){
  }
  
  // Pencil event handlers
  func onPencilDown(pos: CGPoint, force: CGFloat){
    
    if fingers == 0 {
      let f = FastStroke()
      f.start_stroke(pos: pos, force: force)
      fast_strokes.append(f)
      mode = 0
    } else if fingers >= 1 {
      mode = fingers
      
      var closestStroke = -1;
      var closestPoint = -1;
      var closestDistance = CGFloat(100000);
      
      for (i, s) in fast_strokes.enumerated() {
        for (j, p) in s.key_points.enumerated() {
          let dist = (p - CGVector(point: pos)).length()
          if dist < closestDistance  {
            closestStroke = i
            closestPoint = j
            closestDistance = dist
          }
        }
      }
      moving_stroke = closestStroke
      moving_point = closestPoint
    }
    
  }
  
  func onPencilMove(pos: CGPoint, force: CGFloat){
    if mode == 0 {
      fast_strokes.last!.add_stroke_point(pos: pos, force: force)
    } else if mode == 1 {
      print(moving_stroke);
      fast_strokes[moving_stroke].drag_key_point(index: moving_point, new_pos: CGVector(point: pos))
      fast_strokes[moving_stroke].recompute_geometry()
    } else if mode == 2 {
      fast_strokes[moving_stroke].drag_with_falloff(index: moving_point, new_pos: CGVector(point: pos))
      fast_strokes[moving_stroke].recompute_geometry()
//      for s in fast_strokes {
//        var didchange = false
//        for i in 0..<s.points.count {
//          let cp = s.points[i]
//          let diff = (cp - CGVector(point: pos))
//          let len = diff.lengthSquared()
//          if(len < 2000) {
//            let new_pos = cp + diff * (1 / len) * 5
//            s.points[i] = new_pos
//            didchange = true
//          }
//        }
//        if didchange == true {
//          s.recompute_geometry()
//        }
//      }
    }
      
//      for (i, s) in fast_strokes.enumerated() {
//        var didchange = false
//        for (j, p) in s.key_points.enumerated() {
//
//          let cp = s.points[s.key_point_index[j]]
//
//          let diff = (CGVector(point: pos) - cp)
//          let len = diff.lengthSquared()
//          //if(len < 100) {
//            let new_pos = cp + diff * (1 / len) * 10
//            fast_strokes[i].drag_key_point(index: j, new_pos: new_pos)
//            didchange = true
//          //}
//        }
//        if didchange == true {
//          fast_strokes[i].recompute_geometry()
//        }
//      }
//    }
  }
  
  func onPencilPredicted(pos: CGPoint, force: CGFloat){
    if mode == 0 {
      predicted_stroke.append(Vertex(
        position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
        color: SIMD4<Float>(0,0,0,1)
      ))
    }
    
  }
  
  func onPencilUp(pos: CGPoint, force: CGFloat){
    if mode == 0 {
      fast_strokes.last!.end_stroke(pos: pos, force: force)
      //fast_strokes.last!.compute_key_points()
    } else if mode == 1 {
      //fast_strokes[moving_stroke].compute_key_points()
    }
    for (i, s) in fast_strokes.enumerated() {
      s.compute_key_points()
    }
    mode = -1
  }
  
  var selected_points: [(Int, Int)] = []
  
  func onTouchDown(pos: CGPoint){
    fingers += 1;
  }
  
  func onTouchMove(pos: CGPoint){
//    let index = fast_strokes.last!.get_key_point_index(pos: fast_strokes.last!.key_points.last!)
//    fast_strokes.last!.drag_key_point(index: index, new_pos: CGVector(point: pos))
//    fast_strokes.last!.recompute_geometry()
//    fast_strokes.last!.compute_key_points()
  }
  
  func onTouchPredicted(pos: CGPoint){
  }
  
  func onTouchUp(pos: CGPoint){
    fingers -= 1;
  }
  
  // Draw Loop
  func draw(){
    let fps = (1000 / (Date().timeIntervalSince(previousFrameTime) * 1000)).rounded()
    previousFrameTime = Date()
    debugInfo.text = "FPS: \(fps)\nFINGERS: \(fingers)"
    
    
    // Reset the render buffer
    renderer.clearBuffer()
    for stroke in fast_strokes {
      renderer.addStrokeData(data: stroke.geometry)
      for g in stroke.key_point_geometry {
        renderer.addGeometry(geometry: g)
      }
    }
    
    renderer.addStrokeData(data: predicted_stroke)
    predicted_stroke = []
  }
}
