//
//  LocationService.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/9.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation
import MapKit

protocol LocationServiceDelegate: class {
    func dataSourceDidUpdate()
    func didGetUserFriendlyAddress(_ address: LocationService.UserFriendlyAddress)
}

class LocationService: NSObject {
    
    struct UserFriendlyAddress {
        var country: String?
        var subAdministrativeArea: String?
        var locality: String?
        var name: String?
    }
    
    weak var delegate: LocationServiceDelegate?
    
    private var locationManager: CLLocationManager?
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
    }
    
    func getCurrentLocation(completion: ((_ result: Result<CLPlacemark?, Error>) -> Void)?) {
        let geocoder = CLGeocoder()
        
        switch CLLocationManager.authorizationStatus() {
         case .notDetermined:
            print(".notDetermined")
             // Request when-in-use authorization initially
//             locationManager.requestWhenInUseAuthorization()
         case .restricted, .denied:
             // Disable location features
             print("Fail permission to get current location of user")
         case .authorizedWhenInUse:
             // Enable basic location features
            print(".authorizedWhenInUse")
        case .authorizedAlways:
             // Enable any of your app's location features
             print(".authorizedAlways")
        }
        
        // TODO: - Should test the asking flow.
        locationManager?.requestWhenInUseAuthorization()
        
        guard let currentLocation = locationManager?.location else {
            print("[failed]")
            return
        }
        geocoder.reverseGeocodeLocation(currentLocation) { [weak self] (placemarks: [CLPlacemark]?, error: Error?) in
            if let error = error {
                completion?(.failure(error))
            } else {
                if let placemark = placemarks?.first, let address = self?.getUserFriendlyLocation(from: placemark) {
                    self?.delegate?.didGetUserFriendlyAddress(address)
                }
                completion?(.success(placemarks?.first))
            }
        }
    }
    
    private func getUserFriendlyLocation(from placemark: CLPlacemark) -> UserFriendlyAddress {
        let country = placemark.country
        let subAdministrativeArea = placemark.subAdministrativeArea
        let locality = placemark.locality
        let name = placemark.name
        
        let address = UserFriendlyAddress(country: country, subAdministrativeArea: subAdministrativeArea, locality: locality, name: name)
        return address
    }
    
    
}
