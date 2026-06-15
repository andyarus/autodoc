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

struct News: Decodable {
    let id: Int
    let title: String?
    let fullUrl: String?
    let titleImageUrl: String?
}
