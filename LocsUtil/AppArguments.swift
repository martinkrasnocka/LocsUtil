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
        if args.count != 4 {
            return nil
        }
        
        let appFullPath = args[0] as NSString
        appPath = appFullPath.deletingLastPathComponent
        
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
        
        configFile = args[3]
        if !configFile.hasPrefix("/") {
            // relative path
            configFile = (appPath as NSString).appendingPathComponent(configFile)
        }
    }
}
