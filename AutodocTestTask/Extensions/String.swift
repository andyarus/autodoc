//
//  String.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 22.06.2026.
//

import Foundation

extension String {
    static func localized(_ keyAndValue: String.LocalizationValue) -> String {
        return String(localized: keyAndValue)
    }
}
