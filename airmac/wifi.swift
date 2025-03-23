//
//  wifi.swift
//  airmac
//
//  Created by m on 3/22/25.
//

import Foundation
import CoreWLAN


struct EncodableCWNetwork: Encodable {
    enum CodingKeys: String, CodingKey {
        case ssid, bssid, rssiValue, noiseMeasurement
        case channelNumber, channelWidth, channelBand
        case securityType, isIBSS, countryCode
    }
    
    private let network: CWNetwork
    
    init(network: CWNetwork) {
        self.network = network
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(network.ssid, forKey: .ssid)
        try container.encode(network.bssid, forKey: .bssid)
        try container.encode(network.rssiValue, forKey: .rssiValue)
        try container.encode(network.noiseMeasurement, forKey: .noiseMeasurement)
        try container.encode(network.wlanChannel?.channelNumber, forKey: .channelNumber)
    
        try container.encode(network.wlanChannel?.channelBand.rawValue, forKey: .channelBand)
        
        let securityTypes = [
            CWSecurity.none.rawValue,
            CWSecurity.dynamicWEP.rawValue,
            CWSecurity.wpaPersonal.rawValue,
            CWSecurity.wpaPersonalMixed.rawValue,
            CWSecurity.wpaEnterprise.rawValue,
            CWSecurity.wpaEnterpriseMixed.rawValue,
            CWSecurity.wpa2Personal.rawValue,
        
            CWSecurity.wpa2Enterprise.rawValue,
         
            CWSecurity.wpa3Personal.rawValue,
            CWSecurity.wpa3Enterprise.rawValue,
            CWSecurity.wpa3Transition.rawValue
        ].filter { self.network.supportsSecurity(CWSecurity(rawValue: $0)!) }
        
        try container.encode(securityTypes, forKey: .securityType)
        try container.encode(network.ibss, forKey: .isIBSS)
        try container.encode(network.countryCode, forKey: .countryCode)
    }
}

struct EncodableNetworkArray: Encodable {
    let networks: [EncodableCWNetwork]
    init (networks: [EncodableCWNetwork]) {
        self.networks = networks
    }
}



struct WifiItem {
    func scan() -> [CWNetwork]? {
        guard let iface = CWWiFiClient.shared().interface() else {
            print("no interface")
            return nil
        }
        do {
            let networks = try iface.scanForNetworks(withName: nil, includeHidden: true)
            return networks.sorted {
                ($0.ssid ?? "") < ($1.ssid ?? "")
            }
        } catch {
            print("error \(error)")
            return nil
        }
    }
    

    func getScanResults(asJSON: Bool) -> String {
        let results = scan() ?? []
        
        if asJSON {
            do {
                let encodableNetworks = results.map { EncodableCWNetwork(network: $0) }
                let networkArray = EncodableNetworkArray(networks: encodableNetworks)
                let jsonResults = try JSONEncoder().encode(networkArray)
                return String(data: jsonResults, encoding: .utf8) ?? ""
            } catch {
                return "Error encoding to JSON: \(error)"
            }
        } else {
            // Add non-JSON output format
            var output = ""
            results.forEach({
                output += "SSID: \($0.ssid ?? "Unknown"), "
                output += "BSSID: \($0.bssid ?? "Unknown"), "
                output += "RSSI: \($0.rssiValue) dBm, "
                output += "Channel: \($0.wlanChannel?.channelNumber ?? 0)\n"
            })
            return output
        }
    }
}

