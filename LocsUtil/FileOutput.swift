//
//  FileManager.swift
//  LocsUtil
//
//  Created by Martin Krasnocka on 31/03/2023.
//  Copyright © 2023 Martin Krasnocka. All rights reserved.
//

import Foundation

func saveToLocalizableStringsFile(outputDir: String, lang: String, outputString: String) {
    do {
        let path = outputDir + "/" + lang.lowercased() + ".lproj"
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        
        let filePath = path + "/Localizable.strings"
        print("Writing output file: " + filePath)
        try outputString.write(toFile: filePath, atomically: true, encoding: .utf8)
    } catch {
        print("unable to save Localizable.strings file")
        exit(1)
    }
}

func saveToInfoPlistFile(outputDir: String, lang: String, plistsOutputStrings: [String : Any]) {
    for plistName in plistsOutputStrings.keys {
        do {
            let plistOutputString = plistsOutputStrings[plistName] as! NSString
            let path = outputDir + "/" + lang.lowercased() + ".lproj"
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

func saveToLocalizableStringsDictFile(outputDir: String, lang: String, pluralsFile: String) {
    do {
        let path = outputDir + "/" + lang.lowercased() + ".lproj"
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        
        let filePath = path + "/Localizable.stringsdict"
        print("Writing output file: " + filePath)
        try pluralsFile.write(toFile: filePath, atomically: true, encoding: .utf8)
    } catch {
        print("unable to save Localizable.stringsdict file")
        exit(1)
    }
}
