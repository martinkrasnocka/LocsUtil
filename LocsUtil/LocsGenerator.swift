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
    let version = "2.45"
    
    override init() {
//        csvReader = CsvReader()
        xlsxReader = XlsxReader()
    }
    
    var locKeys = [String]()
    
    func generate(args: AppArguments!) {
        
        print("LocsUtil version: \(version). Homepage: https://github.com/martinkrasnocka/LocsUtil\n")
        
        if args == nil {
            print("Usage: locsutil <inputXslxFile> <outputDir> <configPlist>\n")
            print("Parameters:\n\n\tinputXslxFile - path to XLSX document")
            print("\n\toutputDir - path to output dir")
            print("\n\tconfigPlist - path to configuration plist file (optional)\n")
            print("")
            return
        }
        
        print("Current directory: \(args.appPath ?? "none")")
        print("Input file path: \(args.inputFile ?? "none")")
        print("Output directory: \(args.outputDir ?? "none")")
        print("Config file: \(args.configFile ?? "<none>")")
        
        let nowDate = Date()
        
        let xlsxContent = xlsxReader.loadXlsxFromFile(atPath: args.inputFile) as? XlsxFile
        guard let xlsx = xlsxContent else {
            print("unable to parse inputFile file")
            exit(1)
        }
        
        let langColumnsDict = xlsx[langRowIndex]
        locKeys = readColumnWithId(keyColumnId, xlsx: xlsx)
        
        var config: NSDictionary? = nil
        if args.configFile != nil {
            config = NSDictionary(contentsOfFile: args.configFile)
        }
//        let androidSpecificKeys = config.value(forKey: "android_specific_keys") as? [String]
//        let iosSpecificLocalizations = config.value(forKey: "ios_specific_localizations") as? NSDictionary
        
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
            
//            let androidSpecificString = NSMutableString()
            for keyIndex in 0..<locKeys.count {
                let keyString = locKeys[keyIndex]
                let valueString = langValues[keyIndex]
                if keyString.count > 0 || valueString.count > 0 {
                    
                    appendLineToSpecificOutput(keyString: keyString, valueString: valueString, defaultOutput: outputString, plistOutputs: plistsOutputStrings, config: config)
                    
//                    let line = String(format:"\"%@\" = \"%@\";\n\n", keyString, valueString)
//                    if androidSpecificKeys?.contains(keyString) {
//                        androidSpecificString.append(line)
//                    } else {
                    
                
                    
//                        outputString.append(line)
//                    }
                }
            }
            
//            // iOS specific localizations
//            if let iOSSpecLocs = iosSpecificLocalizations?.value(forKey: lang.lowercased()) as? Dictionary<String, String> {
//                outputString.append("\n /* iOS specific strings */\n\n")
//                for keyValue in iOSSpecLocs {
//                    let line = String(format:"\"%@\" = \"%@\";\n\n", keyValue.key, keyValue.value)
//                    outputString.append(line)
//                }
//            }
            
            
//            // Android specific localizations
//            outputString.append("\n /* Android specific strings */\n\n")
//            outputString.append(androidSpecificString as String)
            
            do {
                let path = args.outputDir + "/" + lang.lowercased() + ".lproj"
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                
                let filePath = path + "/Localizable.strings"
                print("Writing output file: " + filePath)
                try outputString.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8.rawValue)
            } catch {
                print("unable to save Localizable.strings file")
                exit(1)
            }
            
            for plistName in plistsOutputStrings.keys {
                do {
                    let plistOutputString = plistsOutputStrings[plistName] as! NSString
                    let path = args.outputDir + "/" + lang.lowercased() + ".lproj"
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                    
                    let filePath = path + "/\(plistName).strings"
                    print("Writing output file: " + filePath)
                    try plistOutputString.write(toFile: filePath, atomically: true, encoding: String.Encoding.utf8.rawValue)
                } catch {
                    print("unable to save file \(plistName).strings")
                    exit(1)
                }
            }

        }
        print("Finished in " + String(format: "%.2f", -nowDate.timeIntervalSinceNow) + " seconds.")
    }
    
    private func appendLineToSpecificOutput(keyString: String, valueString: String, defaultOutput: NSMutableString, plistOutputs: Dictionary<String, Any>, config: NSDictionary?) {
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

    private func cleanValue(input: String) -> String {
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
        
        return output
    }
}
