//
//  NewsTarget.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 15.06.2026.
//

import Foundation

enum NewsTarget: TargetType {
    case news(pagination: Pagination)
}

extension NewsTarget {
    var baseURL: URL {
        return URL(string: Settings.baseUrlApi)!
    }
    
    var path: String {
        switch self {
        case .news(let pagination):
            "news/\(pagination.page)/\(pagination.itemsLimit)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .news: .get
        }
    }
    
    var task: HTTPTask {
        switch self {
        case .news: .requestPlain
        }
    }
}
