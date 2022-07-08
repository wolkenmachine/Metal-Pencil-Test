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
  var drawing_stroke: DrawingStroke? = nil
  var morphable_strokes: [MorphableStroke] = []
  
  
  func setup(){
  }
  
  // Pencil event handlers
  func onPencilDown(pos: CGPoint, force: CGFloat){
    drawing_stroke = DrawingStroke()
    drawing_stroke!.start(pos: pos, force: force)
  }
  
  func onPencilMove(pos: CGPoint, force: CGFloat){
    if let s = drawing_stroke {
      print("pencilmove")
      s.add_point(pos: pos, force: force)
    }
  }
  
  func onPencilPredicted(pos: CGPoint, force: CGFloat){
    if let s = drawing_stroke {
      s.add_predicted_point(pos: pos, force: force)
    }
  }
  
  func onPencilUp(pos: CGPoint, force: CGFloat){
    let new_stroke = MorphableStroke(drawing_stroke!)
    morphable_strokes.append(new_stroke)
    drawing_stroke = nil
  }
  
  func onTouchDown(pos: CGPoint){
  }
  
  func onTouchMove(pos: CGPoint){}
  
  func onTouchPredicted(pos: CGPoint){}
  
  func onTouchUp(pos: CGPoint){}
  
  // Draw Loop
  func draw(){
    let fps = (1000 / (Date().timeIntervalSince(previousFrameTime) * 1000)).rounded()
    previousFrameTime = Date()
    debugInfo.text = "FPS: \(fps)\n"
    
    // Reset the render buffer
    renderer.clearBuffer()
    
    let green: [Float] = [0,1,0,1]
    let blue: [Float] = [0,0,1,1]
    let red: [Float] = [1,0,0,1]
    // Morphable strokes
    for s in morphable_strokes {
      renderer.addStrokeData(s.geometry)
      
      // Keypoints
      for (i, key_point) in s.key_points.enumerated() {
        let color = key_point.corner ? green : red
        
        renderer.addGeometry(circleGeometry(pos: key_point.point, radius: 3.0, color: color))
        
        renderer.addGeometry(lineGeometry(
          a: key_point.point + key_point.tangent_upstream * 5.0,
          b: key_point.point,
          weight: 1.0, color: color
        ))

        renderer.addGeometry(lineGeometry(
          a: key_point.point + key_point.tangent_downstream * 5.0,
          b: key_point.point,
          weight: 1.0, color: color
        ))
      }
      
//      if s.control_points.count > 1 {
//        renderer.addGeometry(lineGeometry(
//          a: s.points[0],
//          b: s.control_points[0],
//          weight: 0.5, color: blue
//        ))
//
//        renderer.addGeometry(lineGeometry(
//          a: s.points.last!,
//          b: s.control_points.last!,
//          weight: 0.5, color: blue
//        ))
//
//        for i in 0..<s.control_points.count-1 {
//          renderer.addGeometry(lineGeometry(
//            a: s.control_points[i],
//            b: s.control_points[i+1],
//            weight: 0.5, color: blue
//          ))
//        }
//      }
      
//      for cp in s.control_points {
//        renderer.addGeometry(circleGeometry(pos: cp, radius: 2.0, color: blue))
//      }
    }
    
    // Drawing stroke
    if let s = drawing_stroke {
      renderer.addStrokeData(s.get_geometry())
    }
    
    // Key points
    
  }
}
