//
//  ViewController.swift
//  MetalTest
//
//  Created by Marcel on 20/06/2022.
//

import UIKit
import MetalKit

// Background color
enum Colors {
  static let background = MTLClearColor(red: 0.0, green: 0.4, blue: 0.2, alpha: 1.0)
}

struct Vertex {
  
}


class ViewController: UIViewController, UIGestureRecognizerDelegate {
  var metalView: MTKView {
    return view as! MTKView
  }
  
  var device: MTLDevice!
  var commandQueue: MTLCommandQueue!
  var pipelineState: MTLRenderPipelineState?
  
  // Vertices & Indices
  let verts: [Float] = [
    -0.01,  0.01, 0,
    -0.01, -0.01, 0,
     0.01, -0.01, 0,
     0.01,  0.01, 0,
  ]
  
  let indices: [UInt16] = [
    0, 1, 2,
    2, 3, 0
  ]

  var vertexBuffer: MTLBuffer?
  var indexBuffer: MTLBuffer?
  
  // Constants
  struct Constants {
    var x: Float = 0.0
    var y: Float = 0.0
  }
  var constants = Constants()
  
  var time: Float = 0
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    metalView.device = MTLCreateSystemDefaultDevice()
    device = metalView.device
    
    metalView.clearColor = Colors.background
    metalView.delegate = self
    commandQueue = device.makeCommandQueue()
    
    buildModel()
    buildPipelineState()
    
    let multiGestureRecognizer = MultiGestureRecognizer(target: nil, action: nil)
    multiGestureRecognizer.delegate = self
    multiGestureRecognizer.viewRef = self
    metalView.addGestureRecognizer(multiGestureRecognizer)
    
    metalView.preferredFramesPerSecond = 120
    //metalView.enableSetNeedsDisplay = false
    //metalView.CAMetalLayer.displaySyncEnabled = false
  }
  
  private func buildModel(){
    vertexBuffer = device.makeBuffer(bytes: verts, length: verts.count * MemoryLayout<Float>.size, options: [])
    indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size, options: [])
  }
  
  private func buildPipelineState(){
    let library = device.makeDefaultLibrary()
    let vertexFunction = library?.makeFunction(name: "vertex_shader")
    let fragmentFunction = library?.makeFunction(name: "fragment_shader")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    
    do {
      pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error as NSError {
      print("error: \(error.localizedDescription)")
    }
  }
}


extension ViewController: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
  
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable,
          let pipelineState = pipelineState,
          let indexBuffer = indexBuffer,
          let descriptor = view.currentRenderPassDescriptor else {
            return
          }
    
    // Animate
//    time += 1 / Float(view.preferredFramesPerSecond)
//    constants.x = abs(sin(time)/2)
//    constants.y = abs(cos(time)/2)
    
    // Run the draw calls
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
    commandEncoder.setRenderPipelineState(pipelineState)
    
    // Actual draw calls
    commandEncoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 1)
    
    commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    
    // Push to GPU
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
    
  }
}
