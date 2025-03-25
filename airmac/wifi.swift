import Foundation
import CoreWLAN

class EncodableCWNetwork: CWNetwork, Encodable {
    enum CodingKeys: String, CodingKey {
        case ssid, bssid, rssiValue, noiseMeasurement
        case channelNumber, channelWidth, channelBand
        case securityTypes, description, isIBSS, countryCode
    }
    
    let securityTypes: [Int: String]

    init(network: CWNetwork) {
        securityTypes = securityTypeMap
            .filter { network.supportsSecurity(CWSecurity(rawValue: $0.key)!) }
            .mapValues { $0 }
        
        super.init()
        
        let mirror = Mirror(reflecting: network)
        for child in mirror.children {
            if let key = child.label {
                setValue(child.value, forKey: key)
            }
        }
        

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ssid, forKey: .ssid)
        try container.encode(bssid, forKey: .bssid)
        try container.encode(rssiValue, forKey: .rssiValue)
        try container.encode(noiseMeasurement, forKey: .noiseMeasurement)
        try container.encode(wlanChannel?.channelNumber, forKey: .channelNumber)
        try container.encode(wlanChannel?.channelBand.rawValue, forKey: .channelBand)
        try container.encode(securityTypes, forKey: .securityTypes)
        try container.encode(ibss, forKey: .isIBSS)
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
                encoder.outputFormatting = [.prettyPrinted]
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

                output += "Channel:        "
                if let channelNumber = network.wlanChannel?.channelNumber {
                    output += "\(channelNumber)\n"
                } else {
                    output += "Unknown\n"
                }
                
                output += "Security:       "
                var securityTypeOut: [String] = Array()
                for securityType in network.securityTypes {
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
        func scan() -> [EncodableCWNetwork]? {
            
        
        guard let iface = CWWiFiClient.shared().interface() else {
            print("no interface")
            return nil
        }
        do {
            let networks = try iface.scanForNetworks(withName: nil, includeHidden: true)
            return networks.map{
                EncodableCWNetwork.init(network: $0)
            }.sorted {
                ($0.ssid ?? "") < ($1.ssid ?? "")
            }
        } catch {
            print("error \(error)")
            return nil
        }
    }
}
