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
  var active_touches: ActiveTouches!
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
    
    active_touches = ActiveTouches()
    
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
    active_touches.update(touches: multiGestureRecognizer.buffer)
    app.update(touch_events: multiGestureRecognizer.buffer, active_touches: active_touches)
    
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
