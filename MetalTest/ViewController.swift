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
    setup()
  }
  
  // THIS IS WHERE THE MAGIC HAPPEN 👇
  
  
  var selected_ball = -1
  
  struct Ball {
    var position: CGPoint
    var color: [Float]
  }
  var balls: [Ball] = []
  
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
    //print("Pencil Down", pos);
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
  
  func onPencilMove(pos: CGPoint){
    //print("Pencil Move", pos);
    if selected_ball > -1 {
      balls[selected_ball].position = pos
    }
  }
  
  func onPencilPredicted(pos: CGPoint){
    //print("Pencil Predicted", pos);
    //quadpos = pos
    if selected_ball > -1 {
      balls[selected_ball].position = pos
    }
  }
  
  func onPencilUp(pos: CGPoint){
    //print("Pencil Up", pos);
  }
  
  // Touch event handlers
  func onTouchDown(pos: CGPoint){
    //print("Pencil Down", pos);
  }
  
  func onTouchMove(pos: CGPoint){
    //print("Pencil Move", pos);
  }
  
  func onTouchPredicted(pos: CGPoint){
    //print("Pencil Predicted", pos);
  }
  
  func onTouchUp(pos: CGPoint){
    //print("Pencil Up", pos);
  }
  
  // Draw Loop
  func draw(){
    renderer.clearBuffer()
    
    
    
    // Render a circle

    var i_offset = 0
    for ball in balls {
      var verts: [Vertex] = []
      var indices: [UInt16] = []
      
      let x = Float(ball.position.x)
      let y = Float(ball.position.y)
      
      // Draw anti_alisassed circle
      let base_color = SIMD4<Float>(ball.color[0], ball.color[1], ball.color[2], 1)
      let transparent_color = SIMD4<Float>(ball.color[0], ball.color[1], ball.color[2], 0)
      //let transparent_color = SIMD4<Float>(ball.color.red, ball.color.green, ball.color.blue, 0)
      
      verts.append(Vertex(position: SIMD3<Float>(x, y, 0), color: base_color))
      
      let factor = (Float.pi*2)/32
      for i in 0...31 {
        verts.append(Vertex(position: SIMD3<Float>(x + cos(Float(i)*factor)*40 , y + sin(Float(i)*factor)*40, 0), color: base_color))
      }
      
      for i in 0...31 {
        verts.append(Vertex(position: SIMD3<Float>(x + cos(Float(i)*factor)*40.5 , y + sin(Float(i)*factor)*40.5, 0), color: transparent_color))
      }
      
      for i in 0...31 {
        indices.append(UInt16(i_offset))
        indices.append(UInt16((i%32)+1+i_offset))
        indices.append(UInt16((i+1)%32+1+i_offset))
      }
      
      for i in 0...31 {
          indices.append(UInt16((i%32)   + 1+i_offset))
          indices.append(UInt16((i+1)%32 + 1+i_offset))
          indices.append(UInt16((i%32)   + 33+i_offset))
        
          indices.append(UInt16((i%32)   + 33+i_offset))
          indices.append(UInt16((i+1)%32 + 33+i_offset))
          indices.append(UInt16((i+1)%32 + 1+i_offset))
      }
      
      i_offset += 65
      
      renderer.addElements(v: verts, i: indices)
    }
  
    
//    renderer.addElements(
//      v: [
//        Vertex(position: SIMD3<Float>(x - 50 , y + 50, 0), color: SIMD4<Float>(1, 0, 0, 1)),
//        Vertex(position: SIMD3<Float>(x - 50 , y - 50, 0), color: SIMD4<Float>(0, 1, 0, 1)),
//        Vertex(position: SIMD3<Float>(x + 50 , y - 50, 0), color: SIMD4<Float>(0, 0, 1, 0)),
//        Vertex(position: SIMD3<Float>(x + 50 , y + 50, 0), color: SIMD4<Float>(1, 0, 1, 0)),
//      ],
//      i: [
//        0, 1, 2,
//        2, 3, 0
//      ])
  }
}
