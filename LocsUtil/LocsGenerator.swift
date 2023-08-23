//
//  LocsGenerator.swift
//  LocsUtil
//
//  Created by Martin Krasnocka on 20/09/2017.
//  Copyright © 2017 Martin Krasnocka. All rights reserved.
//

import Cocoa

typealias Csv = [[String]]
typealias XlsxFile = [[String: String]]

class LocsGenerator: NSObject {

//    var csvReader: CsvReader
    var xlsxReader: XlsxReader
    let langRowIndex = 0 // Language definitions - row index in XSLSX document
    let keyColumnId = "A" // Key definitions - column index in XSLSX document
    let version = "2.49"
    
    override init() {
//        csvReader = CsvReader()
        xlsxReader = XlsxReader()
    }
    
    func generate(args: AppArguments!) {
        print("LocsUtil version: \(version). Homepage: https://github.com/martinkrasnocka/LocsUtil\n")
        
        if args == nil {
            args.printNoArgumetsHelp()
            return
        }
        args.printArguments()
        
        let nowDate = Date()
        
        let xlsxContent = xlsxReader.loadXlsxFromFile(atPath: args.inputFile) as? XlsxFile
        guard let xlsx = xlsxContent else {
            print("unable to parse inputFile file")
            exit(1)
        }
        
        let langColumnsDict = xlsx[langRowIndex]
        let locKeys = readColumnWithId(keyColumnId, xlsx: xlsx)
        
        var config: NSDictionary? = nil
        if args.configFile != nil {
            config = NSDictionary(contentsOfFile: args.configFile)
        }
        
        for (columnId, lang) in langColumnsDict {
            if lang.count == 0 {
                // empty column
                continue
            }
            if columnId == "A" {
                continue
            }
            if columnId == keyColumnId {
                // column with translation keys
                continue
            }
            
            let langValues = readColumnWithId(columnId, xlsx: xlsx)
            let outputString = NSMutableString()
            
            var plistsOutputStrings = Dictionary<String, Any>()
            for plistName in config?.allKeys ?? [] {
                plistsOutputStrings[plistName as! String] = NSMutableString()
            }
            
            var pluralKeyValues = [String: String]()
            
            for keyIndex in 0..<locKeys.count {
                let keyString = locKeys[keyIndex]
                let valueString = langValues[keyIndex]
                
                // skip empty lines
                guard keyString.count > 0 || valueString.count > 0 else {
                    continue
                }
                
                if keyString.isPluralKey() && !valueString.isEmpty {
                    pluralKeyValues[keyString] = valueString
                }
                appendLineToOutput(keyString: keyString, valueString: valueString, defaultOutput: outputString, plistOutputs: plistsOutputStrings, config: config)
            }
            
            saveToLocalizableStringsFile(outputDir: args.outputDir, lang: lang, outputString: outputString as String)
            saveToInfoPlistFile(outputDir: args.outputDir, lang: lang, plistsOutputStrings: plistsOutputStrings)
            if let pluralsFile = generatePluralsFile(pluralKeyValues: pluralKeyValues) {
                saveToLocalizableStringsDictFile(outputDir: args.outputDir, lang: lang, pluralsFile: pluralsFile)
            }
        }
        print("Finished in " + String(format: "%.2f", -nowDate.timeIntervalSinceNow) + " seconds.")
    }
    
    private func appendLineToOutput(keyString: String, valueString: String, defaultOutput: NSMutableString, plistOutputs: Dictionary<String, Any>, config: NSDictionary?) {
        var addedToPlist = false
        for plistName in config?.allKeys ?? [] {
            let plistConfig = config!.object(forKey: plistName) as! NSDictionary
            for key in plistConfig.allKeys {
                if (key as! String) == keyString {
                    let line = String(format:"\"%@\" = \"%@\";\n\n", plistConfig.object(forKey: key) as! String, valueString)
                    (plistOutputs[(plistName as! String)] as! NSMutableString).append(line)
                    addedToPlist = true
                }
            }
        }
        if !addedToPlist {
            if valueString.count > 0 {
                let line = String(format:"\"%@\" = \"%@\";\n\n", keyString, valueString)
                defaultOutput.append(line)
            }
        }
    }
}
