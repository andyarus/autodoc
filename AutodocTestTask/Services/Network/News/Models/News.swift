//
//  News.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 15.06.2026.
//

import Foundation

struct NewsResponse: Decodable {
    let news: [News]
    let totalCount: Int?
}

struct News: Identifiable, Decodable {
    let id: Int
    let title: String?
    let fullUrl: String?
    let titleImageUrl: String?
    var hasImage: Bool { titleImageUrl != nil }
}
