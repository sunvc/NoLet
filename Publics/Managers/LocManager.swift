//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - LocManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/7/16 21:51.

import Contacts
import CoreLocation
import Foundation
import MapKit

final class LocManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocManager()

    @Published var location: CLLocation = .init(latitude: 31.1435, longitude: 121.6570)
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    let locationManager = CLLocationManager()

    private override init() {
        super.init()
        self.locationManager.delegate = self
        self.authorizationStatus = locationManager.authorizationStatus
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func runMonitoringSignificantLocationChanges(start: Bool = false) {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            Task { @MainActor in
                if start {
                    await self.requestLocation()
                    self.locationManager.startMonitoringSignificantLocationChanges()
                } else {
                    self.locationManager.stopMonitoringSignificantLocationChanges()
                }
            }
        default:
            break
        }
    }

    nonisolated static func openMap(latitude: Double, longitude: Double, destinationName: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = destinationName
        mapItem.openInMaps(launchOptions: [:])
    }

    func startMonitoringLocationPushes(callback: @escaping @Sendable (String) -> Void) {
        self.locationManager.startMonitoringLocationPushes { data, error in
            if let error = error {
                logger.error("\(error.localizedDescription)")
                return
            }

            guard let data = data else { return }
            let token = data.map { String(format: "%02.2hhx", $0) }.joined()
            logger.info("Location TOKEN: \(token)")
            callback(token)
        }
    }

    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    func requestLocation() async {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            if let local = await CLGeocoderManager.shared.queryLocation(),
               self.location.coordinate.latitude == .zero ||
               self.location.coordinate.longitude == .zero
            {
                self.location = local
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let lastLocation = locations.last {
                self.location = lastLocation
            }
            NotificationCenter.default.post(
                name: .locationUpdated,
                object: nil
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Positioning failure: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
    }
}

extension Notification.Name {
    static let locationUpdated = Notification.Name("locationUpdated")
}
