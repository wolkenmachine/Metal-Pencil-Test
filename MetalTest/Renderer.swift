//
//  Renderer.swift
//  MetalTest
//
//  Created by Marcel on 20/06/2022.
//

import MetalKit

struct Vertex {
  var position: SIMD3<Float>
  var color: SIMD4<Float>
}

struct Geometry {
  var verts: [Vertex]
  var indices: [UInt16]
}

let NUMBER_OF_VERTS = 10000;

class Renderer: NSObject {
  var viewRef: ViewController!
  
  // Metal things
  var device: MTLDevice!
  var commandQueue: MTLCommandQueue!
  var pipelineState: MTLRenderPipelineState!
  
  // Buffers
  var vertexBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  
  // Buffer sizes for rendering
  var vertexBufferSize = 0;
  var indexBufferSize = 0;
  
  // Screen size
  struct Constants {
    var screen_width: Float = Float(UIScreen.main.bounds.width)
    var screen_height: Float = Float(UIScreen.main.bounds.height)
  }
  var constants = Constants()
  
  // Init function
  init(metalView: MTKView) {
    super.init()
    
    device = MTLCreateSystemDefaultDevice()
    commandQueue = device.makeCommandQueue()
    metalView.device = device
    metalView.delegate = self
    
    createBuffers()
    createPipelineState()
   
    // Default settings
    metalView.preferredFramesPerSecond = 120
    metalView.clearColor = MTLClearColor(red: 0.9921568627, green: 0.9882352941, blue: 0.9843137255, alpha: 1.0) // Off white
    
  }
  
  private func createBuffers(){
    // Buffer for 10000 verts, and 10000 indexes
    let count = 100000
    vertexBuffer = device.makeBuffer(length: count * MemoryLayout<Vertex>.stride, options: [])
    indexBuffer = device.makeBuffer(length: count*MemoryLayout<UInt16>.size, options: [])
  }

  private func createPipelineState(){
    // Load shaders
    let library = device.makeDefaultLibrary()
    let vertexFunction = library?.makeFunction(name: "vertex_shader")
    let fragmentFunction = library?.makeFunction(name: "fragment_shader")

    // Setup a pipeline descriptor
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm // Default pixel format

    // Create vertex descriptor
    let vertexDescriptor = MTLVertexDescriptor()
    vertexDescriptor.attributes[0].format = .float3
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0
    
    vertexDescriptor.attributes[1].format = .float4
    vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
    vertexDescriptor.attributes[1].bufferIndex = 0
    
    vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
    
    pipelineDescriptor.vertexDescriptor = vertexDescriptor
    
    // Settings for alpha blending
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled           = true;
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation           = MTLBlendOperation.add
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation         = MTLBlendOperation.add;
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactor.sourceAlpha;
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactor.sourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactor.oneMinusSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
    
    do {
      pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch let error as NSError {
      print("error: \(error.localizedDescription)")
    }
  }
  
  
  // API
  // Reset the buffer
  public func clearBuffer(){
    vertexBufferSize = 0;
    indexBufferSize = 0;
  }

  // Copy new elements into buffer
  // TODO auto grow buffer size if we overflow
  public func addGeometry(geometry: Geometry) {
    
    // Copy verts
    let vertexByteOffset = MemoryLayout<Vertex>.stride * vertexBufferSize
    (vertexBuffer.contents() + vertexByteOffset).copyMemory(from: geometry.verts, byteCount: geometry.verts.count * MemoryLayout<Vertex>.stride)
    
    
    
    // Offset indicies by bufferSize
    let indices = geometry.indices.map { $0 + UInt16(vertexBufferSize) }
    
    // Copy indicies
    let indexByteOffset = MemoryLayout<UInt16>.stride * indexBufferSize
    (indexBuffer.contents() + indexByteOffset).copyMemory(from: indices, byteCount: indices.count * MemoryLayout<UInt16>.stride)
    
    
    // Increase buffer sizes
    vertexBufferSize += geometry.verts.count
    indexBufferSize += geometry.indices.count
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
    
    viewRef.draw()
    
    // Prepare commandBuffer
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
    commandEncoder.setRenderPipelineState(pipelineState)

    // Draw calls
    if indexBufferSize>0 {
      commandEncoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 1)
      commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferSize, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }
    
    // Wrap up and commit commandBuffer
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
    
  }
}
