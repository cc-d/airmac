//
//  airmacApp.swift
//  airmac
//
//  Created by m on 3/22/25.
//

import Foundation

@main
struct AirMacTool {
    
    static func main() {
        let wifi: WifiProvider = WifiProvider()
        let arguments = CommandLine.arguments
        
        // Handle help flag
        if arguments.contains("-h") || arguments.contains("--help") {
            printHelp()
            exit(0)
        }
        
        // Process command-line arguments
        let useJSON = arguments.contains("-j") || arguments.contains("--json")
        
        let results = wifi.parseScanResults(asJSON: useJSON)
        print(results)
    
    
    }
    
    static func printHelp() {
        print("""
        AirMac WiFi Scanner
        Usage: airmac [options]
        
        Options:
          -j, --json     Output in JSON format
          -h, --help     Show this help message
        """)
    }
}
