//
//  Pagination.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 22.06.2026.
//

import Foundation

struct Pagination {
    var page: Int
    var hasNext: Bool {
        didSet {
            if hasNext { page += 1 }
        }
    }
    let itemsLimit: Int
    var isFetching: Bool
    let offsetLimit: CGFloat
    init(page: Int = 1,
         hasNext: Bool = true,
         itemsLimit: Int = 15,
         isFetching: Bool = false,
         offsetLimit: CGFloat = 1000) {
        self.page = page
        self.hasNext = hasNext
        self.itemsLimit = itemsLimit
        self.isFetching = isFetching
        self.offsetLimit = offsetLimit
    }
}
