//
//  ParsingHelper.swift
//  LocsUtil
//
//  Created by Martin Krasnocka on 07/06/2023.
//  Copyright © 2023 Martin Krasnocka. All rights reserved.
//

import Foundation

func readColumnWithId(_ columnId: String, xlsx: XlsxFile) -> [String] {
    var result = [String]()
    for (index, row) in xlsx.enumerated() {
        if index == 0 {
            continue
        }
        let value = row[columnId] ?? ""
        result.append(cleanValue(input: value))
    }
    return result
}

func cleanValue(input: String) -> String {
    var output = input
    output = output.replacingOccurrences(of: "\"", with: "\\\"")
    
    var i = 1
    while let range = output.range(of: "%s", options: .regularExpression) {
        output = output.replacingCharacters(in: range, with: String(format: "%%%d$@", i))
        i += 1
    }
    
    for i in 1..<10 {
        output = output.replacingOccurrences(of: String(format: "%%%d$s", i), with: String(format: "%%%d$@", i))
    }
    
    output = output.replacingOccurrences(of: "(%.1f%)%", with: "%@")
    output = output.replacingOccurrences(of: "%.1f %", with: "%@")
    
    return output
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
