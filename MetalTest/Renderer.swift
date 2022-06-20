//
//  Renderer.swift
//  MetalTest
//
//  Created by Marcel on 20/06/2022.
//

import MetalKit

class Renderer: NSObject {
  var device: MTLDevice!
  var commandQueue: MTLCommandQueue!
  
  init(device: MTLDevice) {
    self.device = device
    commandQueue = device.makeCommandQueue()
    super.init()
  }
}

extension Renderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
  
  // This function is called every frame
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable,
          let descriptor = view.currentRenderPassDescriptor else {
            return
          }
    
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
    
    
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
    
  }
}
