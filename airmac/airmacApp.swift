//
//  airmacApp.swift
//  airmac
//
//  Created by m on 3/22/25.
//
import CoreWLAN
import CoreLocation
import Foundation


struct WifiItem {
    func scan() -> [CWNetwork]? {
        guard let iface = CWWiFiClient.shared().interface() else {
            print("no interface")
            return nil
        }
        do {
            
            
            let networks = try iface.scanForNetworks(withName: nil, includeHidden: true)
            print(networks)
            return networks.sorted {
                ($0.ssid ?? "") < ($1.ssid ?? "")
            }
        } catch {
            print("error \(error)")
            return nil
        }
       
    }
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }
    

    func requestLocationPermission() {
        // Check if location services are enabled
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.requestWhenInUseAuthorization() // Or requestAlwaysAuthorization
        }
    }
}


struct airmac {
    let wifi: WifiItem = WifiItem()
    func run() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        print(wifi.scan() ?? [])
    }
    
}


@main
struct Main {
    static func main() {
        let app = airmac()
        app.run()
    }
}
