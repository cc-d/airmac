import Foundation
import CoreWLAN

let securityTypeMap: [Int: String] = [
    CWSecurity.none.rawValue: "None",
    CWSecurity.dynamicWEP.rawValue: "Dynamic WEP",
    CWSecurity.wpaPersonal.rawValue: "WPA Personal",
    CWSecurity.wpaPersonalMixed.rawValue: "WPA Personal Mixed",
    CWSecurity.wpaEnterprise.rawValue: "WPA Enterprise",
    CWSecurity.wpaEnterpriseMixed.rawValue: "WPA Enterprise Mixed",
    CWSecurity.wpa2Personal.rawValue: "WPA2 Personal",
    CWSecurity.wpa2Enterprise.rawValue: "WPA2 Enterprise",
    CWSecurity.wpa3Personal.rawValue: "WPA3 Personal",
    CWSecurity.wpa3Enterprise.rawValue: "WPA3 Enterprise",
    CWSecurity.wpa3Transition.rawValue: "WPA3 Transition"
]

class EncodableCWNetwork: Codable {

    let securityTypes: [Int: String]
    let ssid: String?
    let bssid: String?
    let rssiValue: Int
    let noiseMeasurement: Int
    let channelNumber: Int?
    let channelBand: Int?
    let isIBSS: Bool
    let countryCode: String?

    
    init(network: CWNetwork) {
        
        securityTypes = securityTypeMap
            .filter { network.supportsSecurity(CWSecurity(rawValue: $0.key)!) }
            .mapValues { $0 }
        
        self.ssid = network.ssid
        self.bssid = network.bssid
        self.rssiValue = network.rssiValue
        self.noiseMeasurement = network.noiseMeasurement
        self.channelNumber = network.wlanChannel?.channelNumber
        self.channelBand = network.wlanChannel?.channelBand.rawValue
        self.isIBSS = network.ibss
        self.countryCode = network.countryCode

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ssid, forKey: .ssid)
        try container.encode(bssid, forKey: .bssid)
        try container.encode(rssiValue, forKey: .rssiValue)
        try container.encode(noiseMeasurement, forKey: .noiseMeasurement)
        try container.encode(channelNumber, forKey: .channelNumber)
        try container.encode(channelBand, forKey: .channelBand)
        try container.encode(securityTypes, forKey: .securityTypes)
        try container.encode(isIBSS, forKey: .isIBSS)
        try container.encode(countryCode, forKey: .countryCode)
    }
}


struct WifiProvider {
    // Update the non-JSON formatting to use the general function too
    func parseScanResults(asJSON: Bool) -> String {
        let results = scan() ?? []
        
        if asJSON {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonResults = try encoder.encode(results)
                return String(data: jsonResults, encoding: .utf8) ?? ""
            } catch {
                return "Error encoding to JSON: \(error)"
            }
        } else {
            // Add non-JSON output format
            var output = ""
            for network in results {
    
                output += "\nSSID:           \(network.ssid ?? "Unknown") \n"
                output += "BSSID:          \(network.bssid ?? "Unknown") \n"
                output += "RSSI:           \(network.rssiValue) dBm \n"

                output += "Channel:        \(network.channelNumber ?? -1) \n"
                
                output += "Security:       "
                var securityTypeOut: [String] = Array()
                for securityType in network.securityTypes {
                    securityTypeOut.append(
                        "\(securityType.value) (\(securityType.key))")
                }
                output += securityTypeOut.joined(separator: ", ") + "\n"
                
                output += "Band:           \(network.channelBand ?? -1)\n"
                
                output += "Noise:          \(network.noiseMeasurement) dB\n"
                output += "isIBSS:         \(network.isIBSS)\n"
                output += "countryCode:    \(network.countryCode?.description ?? "Unknown")\n"
            }
            return output
        }
    }
    
    // scan function remains the same
        func scan() -> [EncodableCWNetwork]? {
            
        
        guard let iface = CWWiFiClient.shared().interface() else {
            print("no interface")
            return nil
        }
        do {
            let networks = try iface.scanForNetworks(withName: nil, includeHidden: true)
            return networks.map(
                EncodableCWNetwork.init
            ).sorted {
                ($0.ssid ?? "") < ($1.ssid ?? "")
            }
        } catch {
            print("error \(error)")
            return nil
        }
    }
}
