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

vertex float4 vertex_shader(const device packed_float3 *vertices [[ buffer(0) ]],
                            constant Constants &constants [[buffer(1)]],
                            uint vertexId [[ vertex_id ]]) {
  
  float4 position = float4(vertices[vertexId], 1);
  position.x = (position.x / constants.screen_width)* 2 - 1;
  position.y = -((position.y / constants.screen_height)* 2 - 1);
  return position;
}

fragment half4 fragment_shader() {
  return half4(0.1490196078, 0.137254902, 0.1333333333, 1); // Return red color
}
