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
  var multiGestureRecognizer: MultiGestureRecognizer!
  var debugInfo: UITextView!
  var previousFrameTime: Date = Date()
  
  var app: App!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // App
    app = App()
    
    // Load GuestureRecognizer
    multiGestureRecognizer = MultiGestureRecognizer(target: nil, action: nil)
    multiGestureRecognizer.delegate = self
    multiGestureRecognizer.viewRef = self
    metalView.addGestureRecognizer(multiGestureRecognizer)
    
    // Load Renderer
    renderer = Renderer(metalView: metalView)
    renderer.viewRef = self
    
    // Application logic
    app.setup()
    
    // Add debug view
    debugInfo = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    debugInfo.text = "FPS: 0"
    debugInfo.font = UIFont.systemFont(ofSize:14)
    debugInfo.center = CGPoint(x: 100, y: 50);
    metalView.addSubview(debugInfo)
  }
  
  func update(){
    // Update call
    app.update(touches: multiGestureRecognizer.buffer)
    
    // Calculate frame rate
    let dt = Date().timeIntervalSince(previousFrameTime)
    let fps = (1 / dt).rounded()
    previousFrameTime = Date()
    debugInfo.text = "FPS: \(fps)\n"
    
    // Reset drawing buffer and render app
    renderer.clearBuffer()
    app.draw(renderer: self.renderer)
    
    // Clear touches buffer
    multiGestureRecognizer.buffer = []
  }
  
}
