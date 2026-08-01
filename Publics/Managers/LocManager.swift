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

    @Published var location: CLLocation = .init(latitude: 0, longitude: 0)
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var hasValidLocation: Bool {
        let c = location.coordinate
        return c.latitude != 0 || c.longitude != 0
    }

    private var _run: Bool = false

    let locationManager = CLLocationManager()

    private override init() {
        super.init()
        self.locationManager.delegate = self
        self.authorizationStatus = locationManager.authorizationStatus
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.runMonitoringSignificantLocationChanges(true)
    }

    @MainActor
    deinit {
        self.runMonitoringSignificantLocationChanges(false)
    }

    private func runMonitoringSignificantLocationChanges(_ start: Bool = false) {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if start {
                guard !_run else { return }
                _run = true
                Task { @MainActor in
                    await self.requestLocation()
                    self.locationManager.startMonitoringSignificantLocationChanges()
                }
            } else {
                guard _run else { return }
                _run = false
                Task { @MainActor in
                    self.locationManager.stopMonitoringSignificantLocationChanges()
                }
            }
        default:
            if _run {
                _run = false
                Task { @MainActor in
                    self.locationManager.stopMonitoringSignificantLocationChanges()
                }
            }
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

            guard let token = data?.map({ String(format: "%02.2hhx", $0) }).joined() else { return }
            logger.info("Location TOKEN: \(token)")
            callback(token)
        }
    }

    func requestAuthorization() {
        self.locationManager.requestAlwaysAuthorization()
    }

    func requestLocation() async {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
            if !hasValidLocation,
               let local = await CLGeocoderManager.shared.queryLocation()
            {
                await MainActor.run { self.location = local }
            }
        default:
            if !hasValidLocation,
               let local = await CLGeocoderManager.shared.queryLocation()
            {
                await MainActor.run { self.location = local }
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
        let newStatus = manager.authorizationStatus
        self.authorizationStatus = newStatus
        self.runMonitoringSignificantLocationChanges(true)
    }
}

extension Notification.Name {
    static let locationUpdated = Notification.Name("locationUpdated")
}
