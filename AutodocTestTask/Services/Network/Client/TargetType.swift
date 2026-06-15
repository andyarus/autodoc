//
//  TargetType.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 15.06.2026.
//

import Foundation

protocol TargetType {

    /// The target's base `URL`.
    var baseURL: URL { get }

    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String { get }

    /// The HTTP method used in the request.
    var method: HTTPMethod { get }

    /// Provides stub data for use in testing. Default is `Data()`.
    var sampleData: Data { get }

    /// The type of HTTP task to be performed.
    var task: HTTPTask { get }

    /// The headers to be used in the request.
    var headers: [String: String]? { get }
}

extension TargetType {

    /// Provides stub data for use in testing. Default is `Data()`.
    var sampleData: Data { Data() }
    
    var headers: [String: String]? { nil }
}

extension TargetType {
    var urlRequest: URLRequest? {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        do {
            try encode(&request)
        } catch {
            print(error)
        }
        return request
    }
}

/// Alamofire encode
extension TargetType {
    /// Encode request parameters
    private func encode(_ urlRequest: inout URLRequest) throws {
        switch task {
        case .requestPlain: return
        case .requestParameters(parameters: let parameters, encoding: let encoding):
            guard !parameters.isEmpty else { return }
            switch encoding {
            case .queryString:
                guard let url = urlRequest.url else {
                    throw NetworkError.invalidURL
                }
                
                if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                    urlComponents.percentEncodedQuery = percentEncodedQuery
                    urlRequest.url = urlComponents.url
                }
            case .json:
                guard JSONSerialization.isValidJSONObject(parameters) else {
                    throw NetworkError.invalidJSONObject
                }
                
                do {
                    let data = try JSONSerialization.data(withJSONObject: parameters, options: [])
                    urlRequest.httpBody = data
                } catch {
                    throw NetworkError.jsonEncodingFailed(error)
                }
            }
        }
    }
    
    /// Creates a percent-escaped, URL encoded query string components from the given key-value pair recursively.
    ///
    /// - Parameters:
    ///   - key:   Key of the query component.
    ///   - value: Value of the query component.
    ///
    /// - Returns: The percent-escaped, URL encoded query string components.
    public func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        switch value {
        case let dictionary as [String: Any]:
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        case let array as [Any]:
            for (_, value) in array.enumerated() {
                components += queryComponents(fromKey: key, value: value)
            }
        case let number as NSNumber:
            if String(cString: number.objCType) == "c" {
                components.append((escape(key), escape(number.boolValue ? "true" : "false")))
            } else {
                components.append((escape(key), escape("\(number)")))
            }
        case let bool as Bool:
            components.append((escape(key), escape(bool ? "true" : "false")))
        default:
            components.append((escape(key), escape("\(value)")))
        }
        return components
    }

    /// Creates a percent-escaped string following RFC 3986 for a query string key or value.
    ///
    /// - Parameter string: `String` to be percent-escaped.
    ///
    /// - Returns:          The percent-escaped `String`.
    public func escape(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? string
    }

    private func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
}

/// Represents an HTTP task.
enum HTTPTask {
    /// A request with no additional data.
    case requestPlain

    /// A requests body set with encoded parameters.
    case requestParameters(parameters: [String: Any], encoding: ParameterEncoding)
}

enum ParameterEncoding {
    case queryString // URLEncoding.queryString
    case json // JSONEncoding.default
}

fileprivate extension CharacterSet {
    /// Creates a CharacterSet from RFC 3986 allowed characters.
    ///
    /// RFC 3986 states that the following characters are "reserved" characters.
    ///
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
    /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
    /// should be percent-escaped in the query string.
    static let afURLQueryAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
    }()
}
