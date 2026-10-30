//
//  Extensions.swift
//  Examples
//
//  Created by Ashton Meuser on 2026-10-30.
//

import NavigationSplitStack

extension Router {
    var fullPath: String {
        "\(sidebar.map { String(describing: $0) }.joined(separator: "→")) | \(detail.map { String(describing: $0) }.joined(separator: "→"))"
    }
}

extension Array {
    mutating func keepFirst(_ maximumCount: Int) {
        precondition(maximumCount >= 0)
        if count > maximumCount {
            removeLast(count - maximumCount)
        }
    }
}
