//
//  Extensions.swift
//  MetalTest
//
//  Created by Marcel on 21/07/2022.
//

import Foundation

extension Dictionary where Value: Equatable {
    func someKey(forValue val: Value) -> Key? {
        return first(where: { $1 == val })?.key
    }
}
