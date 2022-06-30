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
  var compute_stroke: [Vertex] = []
  var predicted_stroke: [Vertex] = []
  
  
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
  func onPencilDown(pos: CGPoint, force: CGFloat){
    compute_stroke.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,0)
    ))
    compute_stroke.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,1)
    ))
    
//    active_stroke = Stroke()
//    active_stroke!.add_point(point: pos)
//    predicted_points = []
  }
  
  func onPencilMove(pos: CGPoint, force: CGFloat){
    compute_stroke.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,1)
    ))
  }
  
  func onPencilPredicted(pos: CGPoint, force: CGFloat){
    predicted_stroke.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,1)
    ))
  }
  
  func onPencilUp(pos: CGPoint, force: CGFloat){
    compute_stroke.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,1)
    ))
    compute_stroke.append(Vertex(
      position: SIMD3<Float>(Float(pos.x), Float(pos.y), Float(force)),
      color: SIMD4<Float>(0,0,0,0)
    ))
//    active_stroke!.resample_stroke()
//    let new_line_strokes = active_stroke!.split_by_corners()
//    line_strokes += new_line_strokes
//    active_stroke = nil
  }
  
  var selected_points: [(Int, Int)] = []
  
  func onTouchDown(pos: CGPoint){
    
  }
  
  func onTouchMove(pos: CGPoint){
//    for i in 0..<compute_stroke.count {
//      let point = compute_stroke[i].position
//      let diff = (CGVector(dx: CGFloat(point[0]), dy: CGFloat(point[1])) - CGVector(point: pos)).normalized()
//      compute_stroke[i].position[0] -= Float(diff.dx)
//      compute_stroke[i].position[1] -= Float(diff.dy)
//    }
  }
  
  func onTouchPredicted(pos: CGPoint){
  }
  
  func onTouchUp(pos: CGPoint){

  }
  
  // Draw Loop
  func draw(){
    let fps = (1000 / (Date().timeIntervalSince(previousFrameTime) * 1000)).rounded()
    previousFrameTime = Date()
    let triangles = (compute_stroke.count-1)*2
    debugInfo.text = "FPS: \(fps)\nTRIANGLES: \(triangles)"
    
    
    // Reset the render buffer
    //renderer.clearBuffer()
    
    renderer.loadStrokes(data: compute_stroke + predicted_stroke)
    predicted_stroke = []
//    // Render strokes
//
//    for stroke in line_strokes {
//      renderer.addGeometry(geometry: stroke.geometry)
//      //renderer.addGeometry(geometry: circleGeometry(pos: stroke.points.first!, radius: 4, color: [1, 0, 0, 1]))
//      //renderer.addGeometry(geometry: circleGeometry(pos: stroke.points.last!, radius: 4, color: [1, 0, 0, 1]))
//    }
//
//    if(active_stroke != nil) {
//      renderer.addGeometry(geometry: active_stroke!.geometry)
//    }
      
      
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
