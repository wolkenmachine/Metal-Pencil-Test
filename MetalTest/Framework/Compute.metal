//
//  Compute.metal
//  MetalTest
//
//  Created by Marcel on 29/06/2022.
//

#include <metal_stdlib>
using namespace metal;

struct Point {
  float3 position [[ attribute(0) ]];
  float4 color [[ attribute(1) ]];
};


kernel void compute_line_geometry(constant Point *input  [[ buffer(0) ]],
                                  device   Point *output [[ buffer(1) ]],
                                      uint index [[ thread_position_in_grid ]]) {
  Point a = input[index    ];
  Point b = input[index + 1];
  
  float3 diff = normalize(b.position - a.position) * (0.7 + (a.position.z / 3));
  float3 left_offset = float3(a.position.x + diff.y, a.position.y - diff.x, 0);
  float3 right_offset = float3(a.position.x - diff.y, a.position.y + diff.x, 0);
  
  uint out_index = index*2;
  output[out_index] = Point {
    .position = left_offset,
    .color = a.color
  };
  output[out_index+1] = Point {
    .position = right_offset,
    .color = a.color
  };
}



kernel void addition_compute_function(constant float *input1 [[ buffer(0) ]],
                                      constant float *input2 [[ buffer(1) ]],
                                      device   float *result [[ buffer(2) ]],
                                      uint index [[ thread_position_in_grid ]]) {
  result[index] = input1[index] + input2[index];
}
