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
  
  // Data to render
  //var verts = [Vertex](repeating: Vertex(position: SIMD3<Float>(0 , 0, 0), color: SIMD4<Float>(0, 0, 0, 0)), count: NUMBER_OF_VERTS)
  var verts: [Vertex] = [
    Vertex(position: SIMD3<Float>(50 , 200, 0), color: SIMD4<Float>(1, 0, 0, 1)),
    Vertex(position: SIMD3<Float>(50 , 50 , 0), color: SIMD4<Float>(0, 1, 0, 1)),
    Vertex(position: SIMD3<Float>(200, 50 , 0), color: SIMD4<Float>(0, 0, 1, 0)),
    Vertex(position: SIMD3<Float>(200, 200, 0), color: SIMD4<Float>(1, 0, 1, 0)),
  ]

  var indices: [UInt16] = [
    0, 1, 2,
    2, 3, 0
  ]
  
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
  
  // Load
  private func createBuffers(){
    // TODO: size the buffer in some sane, non random way
    //MemoryLayout<Vertex>.stride * verts.count
    vertexBuffer = device.makeBuffer(bytes: verts, length: 4096*1000, options: [])
    
    //MemoryLayout<UInt16>.size
    indexBuffer = device.makeBuffer(bytes: indices, length: 4096*1000, options: [])
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
  public func clearBuffer(){
    verts = []
    indices = []
  }

  public func addElements(v: [Vertex], i: [UInt16]) {
    verts += v
    indices += i
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
    
    // Copy updates into buffer
//    let vertexPoints = vertexBuffer.contents().bindMemory(to: Vertex.self, capacity: verts.count)
//    vertexPoints.assign(from: &verts, count: verts.count)
//
//    let indexPoints = indexBuffer.contents().bindMemory(to: UInt16.self, capacity: indices.count)
//    indexPoints.assign(from: &indices, count: indices.count)
    
    vertexBuffer.contents().copyMemory(from: verts, byteCount: verts.count * MemoryLayout<Vertex>.stride)
    indexBuffer.contents().copyMemory(from: indices, byteCount: indices.count * MemoryLayout<UInt16>.stride)
    
    // Prepare commandBuffer
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
    commandEncoder.setRenderPipelineState(pipelineState)

    // Draw calls
    if indices.count>0 {
      commandEncoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 1)
      commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }
    
    // Wrap up and commit commandBuffer
    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
    
  }
}
