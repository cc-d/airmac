import Foundation
import CoreWLAN

// Create a general utility function for security types
func getSecurityTypes(for network: CWNetwork) -> [Int: String] {
    let securityTypes: [Int: String] = [
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

    // Filter out the security types that are supported by the network
    let supportedSecurityTypes = securityTypes.filter { network.supportsSecurity(CWSecurity(rawValue: $0.key)!) }
    
    return supportedSecurityTypes
}

struct EncodableCWNetwork: Encodable {
    
    enum CodingKeys: String, CodingKey {
        case ssid, bssid, rssiValue, noiseMeasurement
        case channelNumber, channelWidth, channelBand
        case securityTypes, description, isIBSS, countryCode
    }
    
    let network: CWNetwork
    
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
        
        // Use the generalized function instead
        try container.encode(getSecurityTypes(for: network), forKey: .securityTypes)
        
        // Encode other properties
        try container.encode(network.ibss, forKey: .isIBSS)
        try container.encode(network.countryCode, forKey: .countryCode)
    }
}

// Rest of your code remains the same
struct EncodableNetworkArray: Encodable {
    let networks: [EncodableCWNetwork]
    init (networks: [EncodableCWNetwork]) {
        self.networks = networks
    }
}

struct WifiItem {
    // Update the non-JSON formatting to use the general function too
    func getScanResults(asJSON: Bool) -> String {
        let results = scan() ?? []
        let networkArray = results.map(EncodableCWNetwork.init)
        
        if asJSON {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted]
                let jsonResults = try encoder.encode(networkArray)
                return String(data: jsonResults, encoding: .utf8) ?? ""
            } catch {
                return "Error encoding to JSON: \(error)"
            }
        } else {
            // Add non-JSON output format
            var output = ""
            for encodableNetwork in networkArray {
                let network = encodableNetwork.network
                output += "\nSSID:           \(network.ssid ?? "Unknown") \n"
                output += "BSSID:          \(network.bssid ?? "Unknown") \n"
                output += "RSSI:           \(network.rssiValue) dBm \n"

                output += "Channel:        "
                if let channelNumber = network.wlanChannel?.channelNumber {
                    output += "\(channelNumber)\n"
                } else {
                    output += "Unknown\n"
                }
                
                output += "Security:       "
                var securityTypeOut: [String] = Array()
                for securityType in getSecurityTypes(for: network) {
                    securityTypeOut.append(
                        "\(securityType.value) (\(securityType.key))")
                }
                output += securityTypeOut.joined(separator: ", ") + "\n"
                
                output += "Band:           "
                if let band = network.wlanChannel?.channelBand {
                    output += "\(band.rawValue)\n"
                } else {
                    output += "Unknown\n"
                }
                
                output += "Noise:          \(network.noiseMeasurement) dB\n"
                output += "isIBSS:         \(network.ibss)\n"
                output += "countryCode:    \(network.countryCode?.description ?? "Unknown")\n"
            }
            return output
        }
    }
    
    // scan function remains the same
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
}
