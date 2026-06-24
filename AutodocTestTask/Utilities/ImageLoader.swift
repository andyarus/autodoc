//
//  ImageLoader.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 17.06.2026.
//

import UIKit

enum ImageLoaderError: Error {
    case invalidData
    case pointlessRetry
    case unknown
}

actor ImageLoader {
    static let shared = ImageLoader()
    
    private let cache = NSCache<NSString, UIImage>()
    private var runningTasks: [NSString: Task<UIImage?, Error>] = [:]
    
    private init() {
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB limit
    }
    
    /// Create Task so that it gets a cached image or image from the running task later
    func prefetchImage(from urlString: String, retries: Int = 3) async {
        _ = try? await loadImage(from: urlString, retries: retries, needsPreparing: true)
    }
    
    func cancel(for urlString: String) async {
        let urlString = urlString as NSString
        guard let task = runningTasks[urlString],
            !task.isCancelled else { return }
        task.cancel()
        runningTasks.removeValue(forKey: urlString)
    }
    
    func loadImage(from urlString: String,
                   retries: Int = 3,
                   needsPreparing: Bool = false) async throws -> UIImage? {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidUrl
        }
        
        let urlString = urlString as NSString
        
        if let cachedImage = cache.object(forKey: urlString) {
            return cachedImage
        }
        
        if let task = runningTasks[urlString] {
            return try await task.value
        }
        
        let task = Task<UIImage?, Error> {
            var attempt = 0
            while attempt < retries {
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NetworkError.invalidResponse
                    }
                    
                    /// It's pointless to do a retry
                    if 400...405 ~= httpResponse.statusCode {
                        throw ImageLoaderError.pointlessRetry
                    }
                    
                    guard var image = UIImage(data: data) else {
                        throw ImageLoaderError.invalidData
                    }
                    
                    if needsPreparing {
                        image = image.preparingForDisplay() ?? image
                    }
                    
                    cache.setObject(image, forKey: urlString)
                    
                    return image
                } catch {
                    guard (error as? ImageLoaderError) != ImageLoaderError.pointlessRetry,
                          attempt < retries else { throw error }
                    attempt += 1
                    try await Task.sleep(for: .seconds(seconds(for: attempt)))
                }
            }
            throw ImageLoaderError.unknown
        }
        
        runningTasks[urlString] = task
        
        defer {
            runningTasks.removeValue(forKey: urlString)
        }
        
        return try await task.value
    }
    
    /// Retry seconds policy
    private func seconds(for attempt: Int) -> Int8 {
        switch attempt {
        case 2: 5
        case 3: 15
        default: 1
        }
    }
}
