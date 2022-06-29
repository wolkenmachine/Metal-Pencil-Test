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
  
  // Stroke stuff
  var active_stroke: Stroke? = nil
  var line_strokes: [LineStroke] = []
  var predicted_points: [CGPoint] = [CGPoint(x:0,y:0)]
  
  
  var line_stroke: LineStroke!
  func setup(){
    
//    var p = CGPoint(x: UIScreen.main.bounds.width / 2 , y: UIScreen.main.bounds.height / 2)
//    var points:[CGPoint] = []
//    for _ in 0...20000 {
//      p.x += CGFloat(Float.random(in: -4.0..<4.0))
//      p.y += CGFloat(Float.random(in: -4.0..<4.0))
//      points.append(p)
//    }
//
//    line_stroke = LineStroke(points: points)
//    renderer.clearBuffer()
//    renderer.addGeometry(geometry: line_stroke.geometry)
  }
  
  // Pencil event handlers
  func onPencilDown(pos: CGPoint){
    active_stroke = Stroke()
    active_stroke!.add_point(point: pos)
    predicted_points = []
  }
  
  func onPencilMove(pos: CGPoint){
    active_stroke!.add_point(point: pos)
  }
  
  func onPencilPredicted(pos: CGPoint){
    predicted_points.append(pos)
  }
  
  func onPencilUp(pos: CGPoint){
    active_stroke!.resample_stroke()
    let new_line_strokes = active_stroke!.split_by_corners()
    line_strokes += new_line_strokes
    active_stroke = nil
  }
  
  
  
  
  var selected_points: [(Int, Int)] = []
  
  func onTouchDown(pos: CGPoint){
    active_stroke = Stroke()
    active_stroke!.add_point(point: pos)
    predicted_points = []
    
    
//    selected_points = []
//
//    let posv = CGVector(point: pos)
//    for (i, stroke) in line_strokes.enumerated() {
//
//      let start = CGVector(point: stroke.points.first!)
//      if (posv - start).length() < 30 {
//        selected_points.append((i, 1))
//        stroke.grab_point()
//      }
//
//      let end = CGVector(point: stroke.points.last!)
//      if (posv - end).length() < 30 {
//        selected_points.append((i, 0))
//        stroke.grab_point()
//      }
//    }
    
  }
  
  func onTouchMove(pos: CGPoint){
    active_stroke!.add_point(point: pos)
//    for sp in selected_points {
//      line_strokes[sp.0].move_corner_to(pos: CGVector(point: pos), handle: sp.1)
//    }
  }
  
  func onTouchPredicted(pos: CGPoint){
  }
  
  func onTouchUp(pos: CGPoint){
    active_stroke!.resample_stroke()
    let new_line_strokes = active_stroke!.split_by_corners()
    line_strokes += new_line_strokes
    active_stroke = nil
    //print("Pencil Up", pos);
    //active_stroke = nil
  }
  
  // Draw Loop
  func draw(){
    let fps = (1000 / (Date().timeIntervalSince(previousFrameTime) * 1000)).rounded()
    previousFrameTime = Date()
    let triangles = renderer.indexBufferSize / 3
    debugInfo.text = "FPS: \(fps) \n TRIANGLES: \(triangles)"
    
    
    // Reset the render buffer
    renderer.clearBuffer()

    // Render strokes
    
    for stroke in line_strokes {
      renderer.addGeometry(geometry: stroke.geometry)
      //renderer.addGeometry(geometry: circleGeometry(pos: stroke.points.first!, radius: 4, color: [1, 0, 0, 1]))
      //renderer.addGeometry(geometry: circleGeometry(pos: stroke.points.last!, radius: 4, color: [1, 0, 0, 1]))
    }
    
    if(active_stroke != nil) {
      renderer.addGeometry(geometry: active_stroke!.geometry)
    }
      
      
//      for point in stroke.corners {
//        renderer.addGeometry(geometry: circleGeometry(pos: point, radius: 5, color: [1, 0, 0, 1]))
//      }
    //}
    
    // Render predicted points
//    if predicted_points.count > 1 {
//      renderer.addGeometry(geometry: strokeGeometry(points: predicted_points, weight: 1, color: [0,0,0,1]))
//      predicted_points = [strokes.last!.points.last!]
//    }
  }
}
