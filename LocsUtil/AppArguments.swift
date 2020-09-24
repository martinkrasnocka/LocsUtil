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
    
    init?() {
        let args = CommandLine.arguments
        if args.count < 3 || args.count > 4 {
            return nil
        }
        
        appPath = shell(launchPath: "/bin/pwd", arguments: [])?.replacingOccurrences(of: "\n", with: "")
        
        inputFile = args[1]
        if !inputFile.hasPrefix("/") {
            // relative path
            inputFile = (appPath as NSString).appendingPathComponent(inputFile)
        }
        
        outputDir = args[2]
        if !outputDir.hasPrefix("/") {
            // relative path
            outputDir = (appPath as NSString).appendingPathComponent(outputDir)
        }
        
        if args.count > 3 {
            configFile = args[3]
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
}
