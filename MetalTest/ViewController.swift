  //
//  ViewController.swift
//  MetalTest
//
//  Created by Marcel on 20/06/2022.
//

import UIKit
import MetalKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {
  var metalView: MTKView {
    return view as! MTKView
  }
  
  var renderer: Renderer!
  var debugInfo: UITextView!
  var previousFrameTime: Date = Date()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Load GuestureRecognizer
    let multiGestureRecognizer = MultiGestureRecognizer(target: nil, action: nil)
    multiGestureRecognizer.delegate = self
    multiGestureRecognizer.viewRef = self
    metalView.addGestureRecognizer(multiGestureRecognizer)
    
    // Load Renderer
    renderer = Renderer(metalView: metalView)
    renderer.viewRef = self
    
    // Application logic
    precomputeCircle()
    setup()
    
    // Add debug view
    debugInfo = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    debugInfo.text = "FPS: 0"
    debugInfo.font = UIFont.systemFont(ofSize:14)
    debugInfo.center = CGPoint(x: 100, y: 50);
    metalView.addSubview(debugInfo)
  }
  
  // ----------------------------------
  // THIS IS WHERE THE MAGIC HAPPEN 👇
  // ----------------------------------
  
  // Compute stroke
  var drawing_stroke: DrawingStroke? = nil
  var morphable_strokes: [MorphableStroke] = []
  
  var mode = -1;
  var fingers = 0;
  var dragging_stroke_id = -1;
  var dragging_keypoint_id = -1;
  var second_dragging_keypoint_id = -1;
  var dragging_type = 0;
  
  var pencilPos = CGVector(dx: 100, dy: 100)
  var pencilDownPos = CGVector(dx: 0, dy: 0)
  
  var debug_view = false;
  
  func setup(){
    
    print("triangulating")
    
    let triangles = triangulate([
      CGVector(dx: 0, dy: 0),
      CGVector(dx: 10, dy: 0),
      CGVector(dx: 15, dy: 5),
      CGVector(dx: 10, dy: 10),
      CGVector(dx: 0, dy: 10)
    ])
    
    print("triangles", triangles)
  }
  
  // Pencil event handlers
  func onPencilDown(pos: CGPoint, force: CGFloat){
    pencilDownPos = CGVector(point: pos)
    if fingers == 0 {
      mode = 0;
      drawing_stroke = DrawingStroke()
      drawing_stroke!.start(pos: pos, force: force)
    } else if fingers == 1 && morphable_strokes.count > 0 {
      
      let pos = CGVector(point: pos)
      mode = 1
      // Find closest keypoint
      var closest_s_id = -1;
      var closest_k_id = -1;
      var closest_distance = CGFloat(100);
      var type = -1;
      
      var second_closest_k_id = -1;
      
      for s_id in 0...morphable_strokes.count - 1 {
        let control_points = morphable_strokes[s_id].control_points
        if control_points.count > 0 {
          for k_id in 0...control_points.count - 1 {
            let dist = (control_points[k_id] - pos).length()
            if dist < closest_distance {
              second_closest_k_id = k_id
              
              closest_distance = dist
              closest_s_id = s_id
              closest_k_id = k_id
              type = 1
            }
          }
        }
        
        
        let key_points = morphable_strokes[s_id].key_points
        for k_id in 0...key_points.count - 1 {
          if key_points[k_id].corner {
            let dist = (key_points[k_id].point - pos).length()
            if dist < closest_distance {
              closest_distance = dist
              closest_s_id = s_id
              closest_k_id = k_id
              type = 2
            }
          }
        }
      }
      
      dragging_stroke_id = closest_s_id
      dragging_keypoint_id = closest_k_id
      second_dragging_keypoint_id = second_closest_k_id
      dragging_type = type
      
      print("dragmode", dragging_stroke_id, dragging_keypoint_id)
    }
    
    
  }
  
  func onPencilMove(pos: CGPoint, force: CGFloat){
    pencilPos = CGVector(point: pos)
    
    let delta = pencilPos - pencilDownPos
    
    if mode == 0 {
      if let s = drawing_stroke {
        print("pencilmove")
        s.add_point(pos: pos, force: force)
      }
    } else if mode == 1 && dragging_stroke_id != -1 {
      let stroke = morphable_strokes[dragging_stroke_id]
      if dragging_type == 1 {
        //let mv = stroke.control_points[dragging_keypoint_id] + delta
        stroke.drag_control_point(dragging_keypoint_id, CGVector(point: pos))
        //stroke.drag_control_point(dragging_keypoint_id, CGVector(point: pos))
      } else {
        stroke.drag_key_point(dragging_keypoint_id, CGVector(point: pos))
      }
    }
    
  }
  
  func onPencilPredicted(pos: CGPoint, force: CGFloat){
    if mode == 0 {
      if let s = drawing_stroke {
        s.add_predicted_point(pos: pos, force: force)
      }
    }
  }
  
  func onPencilUp(pos: CGPoint, force: CGFloat){
    if mode == 0 {
      let new_stroke = MorphableStroke(drawing_stroke!)
      morphable_strokes.append(new_stroke)
      drawing_stroke = nil
    } else if mode == 1 && dragging_stroke_id != -1 {
      let stroke = morphable_strokes[dragging_stroke_id]
      stroke.compute_properties()
    }
  }
  
  func onTouchDown(pos: CGPoint){
    fingers += 1;
    
    if(fingers == 4) {
      debug_view = !debug_view
    }
  }
  
  func onTouchMove(pos: CGPoint){}
  
  func onTouchPredicted(pos: CGPoint){}
  
  func onTouchUp(pos: CGPoint){
    fingers -= 1;
  }
  
  // Draw Loop
  func draw(){
    let fps = (1000 / (Date().timeIntervalSince(previousFrameTime) * 1000)).rounded()
    previousFrameTime = Date()
    debugInfo.text = "FPS: \(fps)\nFINGERS: \(fingers)"
    
    // Reset the render buffer
    renderer.clearBuffer()
    
    
    let green: [Float] = [0,1,0,1]
    let blue: [Float] = [0,0,1,1]
    let red: [Float] = [1,0,0,1]

    
    if(mode != -1 ){
      //print(pencilPos)
      //renderer.addGeometry(circleGeometry(pos: pencilPos, radius: 1.0, color: red))
    }
    
    // Morphable strokes
    for s in morphable_strokes {
      renderer.addStrokeData(s.geometry)
      
      // Keypoints
      if debug_view {
        renderer.addGeometry(circleGeometry(pos: pencilPos, radius: 5.0, color: [1,0,0,0.5]))
        
        for (i, key_point) in s.key_points.enumerated() {
          let color = key_point.corner ? green : red
          
          renderer.addGeometry(circleGeometry(pos: key_point.point, radius: 3.0, color: color))
          
          renderer.addGeometry(lineGeometry(
            a: key_point.point + key_point.tangent_upstream * 10.0,
            b: key_point.point,
            weight: 1.0, color: color
          ))

          renderer.addGeometry(lineGeometry(
            a: key_point.point + key_point.tangent_downstream * 10.0,
            b: key_point.point,
            weight: 1.0, color: color
          ))
        }

      
//      if s.control_points.count > 1 {
//        renderer.addGeometry(lineGeometry(
//          a: s.points[0],
//          b: s.control_points[0],
//          weight: 0.5, color: blue
//        ))
//
//        renderer.addGeometry(lineGeometry(
//          a: s.points.last!,
//          b: s.control_points.last!,
//          weight: 0.5, color: blue
//        ))
//
//        for i in 0..<s.control_points.count-1 {
//          renderer.addGeometry(lineGeometry(
//            a: s.control_points[i],
//            b: s.control_points[i+1],
//            weight: 0.5, color: blue
//          ))
//        }
//      }
      

        for cp in s.control_points {
          renderer.addGeometry(circleGeometry(pos: cp, radius: 2.0, color: blue))
        }
        
        for cp in s.chaikin_points {
          renderer.addGeometry(circleGeometry(pos: cp, radius: 1.0, color: red))
        }
      }
    }
    
    // Drawing stroke
    if let s = drawing_stroke {
      renderer.addStrokeData(s.get_geometry())
    }
    
    
    
    
    // Key points
    
  }
}
