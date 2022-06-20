//
//  Shader.metal
//  MetalTest
//
//  Created by Marcel on 20/06/2022.
//

#include <metal_stdlib>
using namespace metal;

struct Constants {
  float x;
  float y;
};

vertex float4 vertex_shader(const device packed_float3 *vertices [[ buffer(0) ]],
                            constant Constants &constants [[buffer(1)]],
                            uint vertexId [[ vertex_id ]]) {
  
  float4 position = float4(vertices[vertexId], 1);
  position.x += constants.x;
  position.y += constants.y;
  return position;
}

fragment half4 fragment_shader() {
  return half4(1, 0, 0, 1); // Return red color
}
