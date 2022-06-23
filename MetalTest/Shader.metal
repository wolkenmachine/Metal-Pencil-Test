//
//  Shader.metal
//  MetalTest
//
//  Created by Marcel on 20/06/2022.
//

#include <metal_stdlib>
using namespace metal;

struct Constants {
  float screen_width;
  float screen_height;
};

struct VertexIn {
  float3 position [[ attribute(0) ]];
  float4 color [[ attribute(1) ]];
};

struct VertexOut {
  float4 position [[ position ]];
  float4 color;
};

vertex VertexOut vertex_shader(const VertexIn vertexIn [[ stage_in ]],
                               constant Constants &constants [[buffer(1)]]) {
  
  float4 position = float4(vertexIn.position.x, vertexIn.position.y, 0, 1);
  //float4 position = vertexIn.position;
  position.x = (position.x / constants.screen_width)* 2 - 1;
  position.y = -((position.y / constants.screen_height)* 2 - 1);
  
  VertexOut vertexOut;
  vertexOut.position = position;
  vertexOut.color = vertexIn.color;
  
  return vertexOut;
}

fragment half4 fragment_shader(VertexOut vertexIn [[ stage_in ]]) {
  //return half4(0.1490196078, 0.137254902, 0.1333333333, 1); // Return off black
  return half4(vertexIn.color.r, vertexIn.color.g, vertexIn.color.b, vertexIn.color.a);
}
