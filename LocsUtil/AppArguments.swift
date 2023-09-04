//
//  AppArguments.swift
//  LocsUtil
//
//  Created by Martin Krasnocka on 25/09/2017.
//  Copyright © 2017 Martin Krasnocka. All rights reserved.
//

import Cocoa

class AppArguments {
    
    var appPath: String!
    var inputFile: String!
    var outputDir: String!
    var configFile: String!
    var platform: String!
    var disablePlurals = false
    
    init?() {
        let args = CommandLine.arguments
        if args.count < 4 || args.count > 6 {
            return nil
        }
        appPath = shell(launchPath: "/bin/pwd", arguments: [])?.replacingOccurrences(of: "\n", with: "")
        
        var argIndex = 1
        platform = args[argIndex].lowercased()
        if platform != "ios" && platform != "android" {
            return nil
        }
        
        argIndex += 1
        if args[argIndex].lowercased() == "disablePlurals".lowercased() {
            disablePlurals = true
            argIndex += 1
        }
        
        inputFile = args[argIndex]
        if !inputFile.hasPrefix("/") {
            // relative path
            inputFile = (appPath as NSString).appendingPathComponent(inputFile)
        }
        
        argIndex += 1
        outputDir = args[argIndex]
        if !outputDir.hasPrefix("/") {
            // relative path
            outputDir = (appPath as NSString).appendingPathComponent(outputDir)
        }
        
        argIndex += 1
        if argIndex < args.count {
            configFile = args[argIndex]
            if !configFile.hasPrefix("/") {
                // relative path
                configFile = (appPath as NSString).appendingPathComponent(configFile)
            }
        }
    }
    
    func shell(launchPath: String, arguments: [String]) -> String? {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)

        return output
    }
    
    static func printNoArgumetsHelp() {
        print("Usage: locsutil <platform> <disablePlurals> <inputXslxFile> <outputDir> <configPlist>\n")
        print("Parameters:\n\tplatform - android / ios")
        print("\n\tdisablePlurals - specify 'disablePlurals' as an argument to disable plurals")
        print("\n\tinputXslxFile - path to XLSX document")
        print("\n\toutputDir - path to output dir")
        print("\n\tconfigPlist - path to configuration plist file (optional)\n")
        print("")
    }
    
    func printArguments() {
        print("Current directory: \(appPath ?? "none")")
        print("Platform: \(platform ?? "none")")
        print("Disable plurals: \(disablePlurals)")
        print("Input file path: \(inputFile ?? "none")")
        print("Output directory: \(outputDir ?? "none")")
        print("Config file: \(configFile ?? "<none>")")
    }
}
