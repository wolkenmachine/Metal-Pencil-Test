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

struct Shape {
  var verts: [Vertex]
  var indices: [UInt16]
}

let NUMBER_OF_VERTS = 10000;
let MSAA = 4;

class Renderer: NSObject {
  var viewRef: ViewController!
  
  // Metal things
  var device: MTLDevice!
  var commandQueue: MTLCommandQueue!
  var pipelineState: MTLRenderPipelineState!
  var computePipelineState: MTLComputePipelineState!
  
  // Buffers
  var pointBuffer: MTLBuffer!
  var pointVertexBuffer: MTLBuffer!
  
  var vertexBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  
  
  
  // Buffer sizes for rendering
  var vertexBufferSize = 0;
  var indexBufferSize = 0;
  var pointBufferSize = 0;
  
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
    metalView.sampleCount = MSAA
    
  }
  
  private func createBuffers(){
    // Buffer for 10000 verts, and 10000 indexes
    let count = 200000
    vertexBuffer = device.makeBuffer(length: count * MemoryLayout<Vertex>.stride, options: [])
    indexBuffer = device.makeBuffer(length: count*MemoryLayout<UInt16>.size, options: [])
    
    // Compute
    var bytes: [Float] = []
    for i in 0..<10000 {
      bytes.append(Float(i))
    }
    pointBuffer = device.makeBuffer(length: count * MemoryLayout<Vertex>.stride, options: [])
    pointVertexBuffer = device.makeBuffer(length: count * MemoryLayout<Vertex>.stride, options: [])
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
    pipelineDescriptor.rasterSampleCount = MSAA

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
    
    // Compute Pipeline
    
    // Get Compute function
    let geometryGPUFunction = library?.makeFunction(name: "compute_line_geometry")
    
    do {
      computePipelineState = try device.makeComputePipelineState(function: geometryGPUFunction!)
    } catch let error as NSError {
      print("error: \(error.localizedDescription)")
    }
  }
  
  
  // API
  // Reset the buffer
  public func clearBuffer(){
    vertexBufferSize = 0;
    indexBufferSize = 0;
    pointBufferSize = 0;
  }

  // Copy new elements into buffer
  // TODO auto grow buffer size if we overflow
  public func addShapeData(_ shape: Shape) {
    // Copy verts
    let vertexByteOffset = MemoryLayout<Vertex>.stride * vertexBufferSize
    (vertexBuffer.contents() + vertexByteOffset).copyMemory(from: shape.verts, byteCount: shape.verts.count * MemoryLayout<Vertex>.stride)
    
    
    
    // Offset indicies by bufferSize
    let indices = shape.indices.map { $0 + UInt16(vertexBufferSize) }
    
    // Copy indicies
    let indexByteOffset = MemoryLayout<UInt16>.stride * indexBufferSize
    (indexBuffer.contents() + indexByteOffset).copyMemory(from: indices, byteCount: indices.count * MemoryLayout<UInt16>.stride)
    
    
    // Increase buffer sizes
    vertexBufferSize += shape.verts.count
    indexBufferSize += shape.indices.count
  }
  
  public func loadStrokes(data: [Vertex]) {
    pointBuffer.contents().copyMemory(from: data, byteCount: data.count * MemoryLayout<Vertex>.stride)
    pointBufferSize = data.count
  }
  
  public func addStrokeData(_ data: [Vertex]) {
    let byteOffset = MemoryLayout<Vertex>.stride * pointBufferSize
    (pointBuffer.contents() + byteOffset).copyMemory(from: data, byteCount: data.count * MemoryLayout<Vertex>.stride)
    pointBufferSize += data.count
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
    
    viewRef.update()
    
    // Prepare commandBuffer
    let commandBuffer = commandQueue.makeCommandBuffer()!
    
    // Compute Pass
    if(pointBufferSize > 2) {
      let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
      computeCommandEncoder.setComputePipelineState(computePipelineState)
      
      computeCommandEncoder.setBuffer(pointBuffer, offset: 0, index: 0)
      computeCommandEncoder.setBuffer(pointVertexBuffer, offset: 0, index: 1)
      
      let threadsPerGrid = MTLSize(width: pointBufferSize-1, height: 1, depth: 1)
      let maxThreadsPerThreadGroup = computePipelineState.maxTotalThreadsPerThreadgroup
      let threadsPerThreadGroup = MTLSize(width: maxThreadsPerThreadGroup, height: 1, depth: 1)
      computeCommandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
      
      computeCommandEncoder.endEncoding()
    }
    
    
    
    
    // Render Pass
    let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
    commandEncoder.setRenderPipelineState(pipelineState)

    commandEncoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 1)
    
    // Draw calls
    if pointBufferSize>2 {
      commandEncoder.setVertexBuffer(pointVertexBuffer, offset: 0, index: 0)
      commandEncoder.drawPrimitives(type: MTLPrimitiveType.triangleStrip, vertexStart: 0, vertexCount: pointBufferSize*2-2)

    }
    
    if indexBufferSize > 0 {
      commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
      commandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexBufferSize, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
    }
    
    
    commandEncoder.endEncoding()
    
    // Wrap up and commit commandBuffer
    commandBuffer.present(drawable)
    commandBuffer.commit()
    
  }
}
