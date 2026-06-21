//
//  NetworkClient.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 14.06.2026.
//

import Foundation

protocol NetworkClientProtocol {
    func request<T: Decodable>(_ target: TargetType) async throws -> T
}

final class NetworkClient: NetworkClientProtocol {
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func request<T: Decodable>(_ target: TargetType) async throws -> T {
        guard let request = target.urlRequest else {
            throw NetworkError.invalidRequest
        }
        
#if DEBUG
        print(request)
#endif
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.statusCode(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}
