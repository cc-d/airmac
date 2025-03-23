//
//  location.swift
//  airmac
//
//  Created by m on 3/22/25.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }
    

    func requestLocationPermission() {
        // Check if location services are enabled
        let status = locationManager?.authorizationStatus;
        if status?.rawValue ?? 0 != 3 {
            locationManager?.requestWhenInUseAuthorization()
        }
            
       
    }
}
