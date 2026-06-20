//
//  Array.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 19.06.2026.
//

import Foundation

extension Array where Element: Identifiable {
    func toDict(_ dict: inout [Element.ID: Element]) {
        withUnsafeBufferPointer { buffer in
            for i in 0..<buffer.count {
                let element = buffer[i]
                dict[element.id] = element
            }
        }
    }
}
