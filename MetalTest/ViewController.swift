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
  }
  
  // THIS IS WHERE THE MAGIC HAPPEN 👇
  var selected_ball = -1
  
  struct Ball {
    var position: CGPoint
    var color: [Float]
  }
  var balls: [Ball] = []
  
  var strokes: [[CGPoint]] = []
  var predicted_points: [CGPoint] = [CGPoint(x:0,y:0)]
  
  let stroke_color: [Float] = [0,0,0,1]
  
  var stroke_width: Float = 1.0
  
  func setup(){
    for i in 0...10 {
      balls.append(Ball(
        position: CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: CGFloat.random(in: 0...UIScreen.main.bounds.height)),
        color: [Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1), 1]
      ))
    }
  }
  
  // Pencil event handlers
  func onPencilDown(pos: CGPoint){
    strokes.append([pos])
    predicted_points = []
  }
  
  func onPencilMove(pos: CGPoint){
    strokes[strokes.count-1].append(pos)
  }
  
  func onPencilPredicted(pos: CGPoint){
    predicted_points.append(pos)
  }
  
  func onPencilUp(pos: CGPoint){
    //print("Pencil Up", pos);
  }
  
  // Touch event handlers
  func onTouchDown(pos: CGPoint){
    let pos_vec = CGVector(point: pos)
    selected_ball = -1
    for (index, ball) in balls.enumerated() {
      let diff = CGVector(point: ball.position) - pos_vec
      let distance = diff.length()
      if distance < 40 {
        selected_ball = index
      }
    }
  }
  
  func onTouchMove(pos: CGPoint){
    if selected_ball > -1 {
      balls[selected_ball].position = pos
    }
  }
  
  func onTouchPredicted(pos: CGPoint){
    if selected_ball > -1 {
      balls[selected_ball].position = pos
    } else {
      stroke_width = (Float(pos.y) / Float(UIScreen.main.bounds.width)) * 5.0
    }
  }
  
  func onTouchUp(pos: CGPoint){
    //print("Pencil Up", pos);
  }
  
  // Draw Loop
  func draw(){
    // Reset the render buffer
    renderer.clearBuffer()
    
    // Render a bunch of circles
    for ball in balls {
      renderer.addGeometry(geometry: circleGeometry(pos: ball.position, radius: 40, color: ball.color))
    }
  
    // Render strokes
    for stroke in strokes {
      renderer.addGeometry(geometry: strokeGeometry(points: stroke, weight: stroke_width, color: stroke_color))
    }
    
    // Render predicted points
    if predicted_points.count > 1 {
      renderer.addGeometry(geometry: strokeGeometry(points: predicted_points, weight: stroke_width, color: stroke_color))
      predicted_points = [strokes.last!.last!]
    }
    
  }
}
