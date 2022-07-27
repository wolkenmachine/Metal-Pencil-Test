//
//  Graph.swift
//  MetalTest
//
//  Created by Marcel on 22/07/2022.
//

import Foundation

class ConnectivityGraph {
  var nodes: [Int: Set<Int>] = [:]
  
  func add_edge(_ a: Int, _ b: Int) {
    add_node(a)
    add_node(b)
    nodes[a]?.insert(b)
    nodes[b]?.insert(a)
  }
  
  func add_node(_ id: Int) {
    if !nodes.hasKey(id) {
      nodes[id] = Set()
    }
  }
    
  func subtract_graph(_ other: ConnectivityGraph) -> ConnectivityGraph {
    let result_graph = ConnectivityGraph()
    for_each_edge { a, b in
      if !other.has_node(a) || !other.has_node(b) {
        result_graph.add_edge(a, b)
      }
    }
    
    return result_graph
  }
  
  func get_spanning_tree() -> ConnectivityGraph {
    var visted: Set<Int> = Set()
    var tree = ConnectivityGraph()
    
    func recurse(_ root: Int) {
      var neighbours: [Int] = Array(nodes[root]!)
      neighbours.sort(by: { a, b in
        nodes[a]!.count > nodes[b]!.count
      })
      
      var next: [Int] = []
      for n in neighbours {
        if !visted.contains(n) {
          visted.insert(n)
          tree.add_edge(root, n)
          next.append(n)
        }
      }
      for n in next {
        recurse(n)
      }
      
    }
    
    recurse(get_most_connected_node())
    
    return tree
  }
  
  func get_base_cycles_disconnected() -> [[Int]] {
    var graph = self
    //var spanning_trees: [ConnectivityGraph] = []
    
    var cycles: [[Int]] = []
    
    print("## GET DISCONNECTED CYCLES")
    
    while graph.nodes_count() > 0 {
      print("iterate graph")
      dump(graph)
      let spanning_tree = graph.get_spanning_tree()
      let new_graph = graph.subtract_graph(spanning_tree)
      let disconnected_subgraph = graph.subtract_graph(new_graph)
      graph = new_graph
      cycles.append(contentsOf: disconnected_subgraph.get_base_cycles())
    }
    
    return cycles
    
    
  }
  
  // finds base cycles (smallest cycles that can be composed into bigger ones)
 // based on: https://javascript.plainenglish.io/finding-simple-cycles-in-an-undirected-graph-a-javascript-approach-1fa84d2f3218
  func get_base_cycles() -> [[Int]] {
    // Create a spanning tree
    let spanning_tree = get_spanning_tree()
    
    // find edges in graph that are not in spanning tree
    var found_edges: [(Int, Int)] = [];
    for_each_edge { a, b in
      if !spanning_tree.has_edge(a, b) {
        found_edges.append((a, b))
      }
    }
    
    
    // find cycles that connect those edges
    let len = found_edges.count
    var cycles: [[Int]] = []
    
    for i in 0..<len {
      // Find all possible loops from the spanning tree
      var loops = found_edges.map {edge in
        return spanning_tree.get_path_between(edge.0, edge.1)
      }
      
      // Find the shortest loop
      loops.sort(by: { a, b in
        a.count < b.count
      })
      
      // Add the shortest loop to the list of cycles, and include the newly added edge to the spanning tree
      // So we can now use this edge to find shorter cycles
      let shortest_loop = loops.first!
      
      print("shortest loops")
      dump(loops)
      
      if shortest_loop.count > 1 {
        cycles.append(shortest_loop)
        spanning_tree.add_edge(shortest_loop.first!, shortest_loop.last!)
        found_edges.removeAll { (a,b) in
          (a == shortest_loop.first! && b == shortest_loop.last!) || (b == shortest_loop.first! && a == shortest_loop.last!)
        }
      } else {
        found_edges.remove(at: 0) // Skip this one
      }
    }
    
    return cycles
  }
  
  func for_each_edge(_ callback: (Int, Int)->()) {
    var visited: Set<String> = Set()
    
    for a in nodes.keys {
      for b in nodes[a]! {
        if !visited.contains(("\(b)-\(a)")) {
            callback(a,b)
          visited.insert("\(a)-\(b)")
        }
      }
    }
  }
  
  func has_edge(_ a: Int, _ b: Int) -> Bool {
    if let n = nodes[a] {
      return n.contains(b)
    }
    return false
  }
  
  func has_node(_ a: Int) -> Bool {
    if let n = nodes[a] {
      return true
    }
    return false
  }

  func get_path_between(_ a: Int, _ b: Int) -> [Int] {
    
    // Create a queue for doing breadth-first traversal
    var queue = [a]
    var visited: Set<Int> = Set()
    visited.insert(a)
    
    // Prev is a list of pointers from a node to the previous node in the path
    var prev: [Int:Int] = [:]
    
    while queue.count > 0 {
      // Pop first element from queue
      let node = queue.first!
      queue.remove(at: 0)
      let neighbours = nodes[node]
      
      if let neighbours = neighbours {
        for next in neighbours {
          if !visited.contains(next) {
            queue.append(next)
            visited.insert(next)
            prev[next] = node
          }
        }
      }
    }
    
    // Trace through the prev nodes from the back to create the path
    var p = prev[b]
    var path = [b]
    
    // While we haven't reached the start node and a path exists
    while p != a && p != nil {
      path.append(p!)
      p = prev[p!]
    }
    
    // A path exists
    if p == a {
      path.append(a)
      return path
    }
    
    return []
    
  }
  
  
  
  func get_most_connected_node() -> Int {
    let sorted = nodes.keys.sorted { a, b in
      nodes[a]!.count > nodes[b]!.count
    }
                 
    return sorted[0]
  }
  
  func nodes_count() -> Int {
    return nodes.count
  }
}
