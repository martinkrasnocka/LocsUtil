//
//  CsvReader.swift
//  LocsUtil
//
//  Created by Martin Krasnocka on 20/09/2017.
//  Copyright © 2017 Martin Krasnocka. All rights reserved.
//

import Cocoa

class CsvReader: NSObject {
    
    func loadCsvFromFileAtPath(path: String) -> Csv {
        let content = readFromFileToString(filePath: path)
        return csvFromString(data: content)
    }
    
    private func readFromFileToString(filePath: String) -> String {
        do {
            var contents = try String(contentsOfFile: filePath, encoding: .utf8)
            contents = cleanRows(file: contents)
            return contents
        } catch {
            print("File Read Error for file \(filePath)")
            exit(1)
        }
    }

    private func cleanRows(file: String) -> String {
        var cleanFile = file
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\"", with: "\\\"")
        cleanFile = cleanFile.replacingOccurrences(of: "%s", with: "%1$@")
        //        cleanFile = cleanFile.replacingOccurrences(of: ";\n", with: "")
        return cleanFile
    }
    
    
    private func csvFromString(data: String) -> Csv {
        var result: Csv = []
        let rows = data.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ";")
            var updatedColumns = [String]()
            for value in columns {
//                NSLog(columns)
                let escapedQuotes = "\\\"" as NSString
                let escapedQuotesLength = escapedQuotes.length
                if value.hasPrefix(escapedQuotes as String) && value.hasSuffix(escapedQuotes as String) && value.count >= escapedQuotesLength * 2 {
                    let nsStringValue = value as NSString
                    let updatedString = nsStringValue.substring(with: NSMakeRange(escapedQuotesLength, nsStringValue.length - escapedQuotesLength * 2))
                    updatedColumns.append(updatedString)
                } else {
                    updatedColumns.append(value)
                }
            }
            result.append(updatedColumns)
        }
        return result
    }
}
