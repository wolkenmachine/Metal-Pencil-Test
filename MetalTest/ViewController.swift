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
  static let background = MTLClearColor(red: 0.9921568627, green: 0.9882352941, blue: 0.9843137255, alpha: 1.0)
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
  
  var lastPoint = CGVector(dx: 0, dy: 0)
  
  var indexOffset: UInt16 = 2
  // Vertices & Indices
  var verts: [Float] = [
     0,   1, 0,
     0,   0, 0,
     1, 0, 0,
     1, 1, 0,
  ]
  
  var indices: [UInt16] = [
    0, 1, 2,
    2, 3, 1
  ]

  var vertexBuffer: MTLBuffer?
  var indexBuffer: MTLBuffer?
  
  var bufferIndex: Int = 0
  var vertexBuffers: [MTLBuffer] = []
  var indexBuffers: [MTLBuffer] = []
  
  // Constants
  struct Constants {
    var screen_width: Float = Float(UIScreen.main.bounds.width)
    var screen_height: Float = Float(UIScreen.main.bounds.height)
  }
  var constants = Constants()
  
  //var time: Float = 0
  var previousFrameAtTime: Date = Date()

  
  
  let inFlightSemaphore = DispatchSemaphore.init(value: 3)
  
  func newLine(x: CGFloat, y: CGFloat){
    print("new line")
    let newPoint = CGVector(dx: x, dy: y)
    
    verts += [
      Float(newPoint.dx), Float(newPoint.dy), 0,
      Float(newPoint.dx), Float(newPoint.dy), 0,
    ]
    
    // Ignore the first time in the buffer
    //if(indexOffset != 0) {
      indexOffset += 2
    //}
    
    lastPoint = newPoint
  }
  
  func addPoint(x: CGFloat, y: CGFloat, width: CGFloat){
    let newPoint = CGVector(dx: x, dy: y)
    let diff = (newPoint - lastPoint).normalized() * width // line thickness
    let left_offset = newPoint + diff.rotated90clockwise()
    let right_offset = newPoint + diff.rotated90counterclockwise()
    
    verts += [
      Float(right_offset.dx), Float(right_offset.dy), 0,
      Float(left_offset.dx), Float(left_offset.dy), 0,
    ]
    
    
    indices += [
      indexOffset+0, indexOffset+1, indexOffset+2,
      indexOffset+2, indexOffset+3, indexOffset+1
    ]
    
    indexOffset += 2
    
    lastPoint = newPoint
  }
  
  func setPotentialFuturePoint(x: CGFloat, y: CGFloat) {
    // Trick: use the first quad in the system to project forward into the future
    let newPoint = CGVector(dx: x, dy: y)
    let diff = (newPoint - lastPoint).normalized()*0.5 // line thickness
    let left_offset = newPoint + diff.rotated90clockwise()
    let right_offset = newPoint + diff.rotated90counterclockwise()
    
    verts[0] = Float(right_offset.dx)
    verts[1] = Float(right_offset.dy)
    verts[3] = Float(left_offset.dx)
    verts[4] = Float(left_offset.dy)
    
    indices[3] = 0
    indices[4] = 1
    indices[5] = indexOffset+0
    
    indices[0] = indexOffset+0
    indices[1] = indexOffset+1
    indices[2] = 1
  }
  
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
  }
  
  private func buildModel(){
    // TODO: size the buffer in some sane way
//    vertexBuffer = device.makeBuffer(bytes: verts, length: 4096*100, options: [])
//    indexBuffer = device.makeBuffer(bytes: indices, length: 4096*100, options: [])
    
    for _ in 0...3 {
      vertexBuffers.append(device.makeBuffer(bytes: verts, length: 4096*100, options: [])!)
      indexBuffers.append(device.makeBuffer(bytes: indices, length: 4096*100, options: [])!)
    }
  }
  
  private func buildPipelineState(){
    let library = device.makeDefaultLibrary()
    let vertexFunction = library?.makeFunction(name: "vertex_shader")
    let fragmentFunction = library?.makeFunction(name: "fragment_shader")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      
    for i in 0...6 {
      pipelineDescriptor.vertexBuffers[i].mutability = MTLMutability.immutable;
    }
    
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
    // Semaphore for tripple buffering
    inFlightSemaphore.wait()
    
    
    let fps = 1000 / (Date().timeIntervalSince(previousFrameAtTime) * 1000)
    previousFrameAtTime = Date()
    
    //print("frame ",fps, bufferIndex)
    guard let drawable = view.currentDrawable,
          let pipelineState = pipelineState,
//          let indexBuffer = indexBuffer,
//          let vertexBuffer = vertexBuffer,
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
    // Update buffers
    let indexBuffer = indexBuffers[bufferIndex]
    let vertexBuffer = vertexBuffers[bufferIndex]
    vertexBuffer.contents().copyMemory(from: verts, byteCount: verts.count * MemoryLayout<Float>.stride)
    indexBuffer.contents().copyMemory(from: indices, byteCount: indices.count * MemoryLayout<UInt16>.stride)
    bufferIndex += 1
    if bufferIndex == 3 {
      bufferIndex = 0
    }
    
    //print(bufferIndex)
    
    commandEncoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 1)
    
    commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    
    // Push to GPU
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
    
    // Release semaphore
    inFlightSemaphore.signal()
  }
}
