//
//  NetworkError.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 15.06.2026.
//

import Foundation

enum NetworkError: Error {
    case invalidUrl
    case invalidRequest
    case invalidResponse
    case statusCode(Int)    
    case decodingError(Error)
    case invalidJSONObject
    case jsonEncodingFailed(Error)
    case unknown(Error)
}
