//
//  LocsComparison.swift
//  LocsUtil
//
//  Created by Martin Krasnocka on 07/06/2023.
//  Copyright © 2023 Martin Krasnocka. All rights reserved.
//

import Foundation

class LocsComparison: NSObject {
    var xlsxReader1: XlsxReader
    var xlsxReader2: XlsxReader
    let langRowIndex1 = 0 // Language definitions - row index in XSLSX document
    let keyColumnId1 = "A" // Key definitions - column index in XSLSX document
    let langRowIndex2 = 0 // Language definitions - row index in XSLSX document
    let keyColumnId2 = "A" // Key definitions - column index in XSLSX document
    
    let version = "1.00"
    
    override init() {
        xlsxReader1 = XlsxReader()
        xlsxReader2 = XlsxReader()
    }
    
    func generate(args: AppArguments!) {
        print("LocsUtil version: \(version). Homepage: https://github.com/martinkrasnocka/LocsUtil\n")
        
        if args == nil {
            args.printNoArgumetsHelp()
            return
        }
        args.printArguments()
        
        let nowDate = Date()
        
        let xlsxContent1 = xlsxReader1.loadXlsxFromFile(atPath: args.inputFile) as? XlsxFile
        guard let xlsx1 = xlsxContent1 else {
            print("unable to parse inputFile file1")
            exit(1)
        }
        let xlsxContent2 = xlsxReader2.loadXlsxFromFile(atPath: args.inputFile.replacingOccurrences(of: ".xlsx", with: "2.xlsx")) as? XlsxFile
        guard let xlsx2 = xlsxContent2 else {
            print("unable to parse inputFile file2")
            exit(1)
        }
        print("")
        
        let langColumnsDict1 = xlsx1[langRowIndex1]
        let locKeys1 = readColumnWithId(keyColumnId1, xlsx: xlsx1)
        
        let langColumnsDict2 = xlsx2[langRowIndex2]
        let locKeys2 = readColumnWithId(keyColumnId2, xlsx: xlsx2)
        
        let allLangs1 = langColumnsDict1.map { (key: String, value: String) in
            value
        }
        let allLangs2 = langColumnsDict2.map { (key: String, value: String) in
            value
        }
        printDifferences(allLangs1, allLangs2, caption: "Languages")
//        printDifferences(locKeys1, locKeys2, caption: "Translation keys")
        
        
//        let values1 = readColumnWithId("B", xlsx: xlsx1)
//
//        let values2 = readColumnWithId("B", xlsx: xlsx2)
//        printDifferences(values1, values2, caption: "EN")
        
        var allValues1 = [String: [String: String]]() // en: [key: value]
        var allValues2 = [String: [String: String]]() // en: [key: value]
        
        for (columnId, lang) in langColumnsDict1 {
            if lang.count == 0 {
                // empty column
                continue
            }
            if columnId == keyColumnId1 {
                // column with translation keys
                continue
            }

            let langValues1 = readColumnWithId(columnId, xlsx: xlsx1)
            
            var keyValueDict1 = [String: String]()
            for keyIndex1 in 0..<locKeys1.count {
                let keyString1 = locKeys1[keyIndex1]
                let valueString1 = langValues1[keyIndex1]
                
                // skip empty lines
                guard keyString1.count > 0 || valueString1.count > 0 else {
                    continue
                }
                keyValueDict1[keyString1] = valueString1
            }
            allValues1[lang] = keyValueDict1
        }
        for (columnId, lang) in langColumnsDict2 {
            if lang.count == 0 {
                // empty column
                continue
            }
            if columnId == keyColumnId2 {
                // column with translation keys
                continue
            }
            
            let langValues2 = readColumnWithId(columnId, xlsx: xlsx2)
            
            var keyValueDict2 = [String: String]()
            for keyIndex2 in 0..<locKeys2.count {
                let keyString2 = locKeys2[keyIndex2]
                let valueString2 = langValues2[keyIndex2]
                
                // skip empty lines
                guard keyString2.count > 0 || valueString2.count > 0 else {
                    continue
                }
                keyValueDict2[keyString2] = valueString2
            }
            allValues2[lang] = keyValueDict2
        }
        
        for lang in allLangs1 {
            let keyValues1 = allValues1[lang]
            let keyValues2 = allValues2[lang]
            
            guard let keyValues1, let keyValues2 else {
                continue
            }
            var keysMissingTranslations = [String]()
            for key1 in keyValues1.keys {
                let value1 = keyValues1[key1] ?? ""
                let value2 = keyValues2[key1] ?? ""
                if value2.isEmpty {
//                    print("\(lang): \(key1): not translated")
                } else if value1 != value2 {
//                    print("\(lang): \(key1): \(value1) != \(value2)")
                }
                
                if value1.isEmpty {
                    if (!keysMissingTranslations.contains(key1)) {
                        keysMissingTranslations.append(key1)
                    }
                }
            }
            print("Keys missing translations: \(keysMissingTranslations)")
        }
        
        
        print("Finished in " + String(format: "%.2f", -nowDate.timeIntervalSinceNow) + " seconds.")
    }
    
    func printDifferences(_ list1: [String], _ list2: [String], caption: String) {
        if list1.sorted() == list2.sorted() {
            return
        }
        
        var result1 = [String]()
        for item1 in list1 {
            if !list2.contains(item1) {
                result1.append(item1)
            }
        }
        var result2 = [String]()
        for item2 in list2 {
            if !list1.contains(item2) {
                result2.append(item2)
            }
        }
        if !result1.isEmpty {
            print("\(caption): items not found in the new translation sheet: \(result1)")
        }
        if !result2.isEmpty {
            print("\(caption): items not used in our sheet: \(result2)")
        }
    }
}
