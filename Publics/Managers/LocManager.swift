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

    /// 未定位时的哨兵值 (0,0)。UI/上报侧用 `hasValidLocation` 判定,别把这个当真实坐标发出去。
    @Published var location: CLLocation = .init(latitude: 0, longitude: 0)
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// `location` 是否已被真实定位/兜底覆盖过。仍在 (0,0) 时视为未定位。
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
    }

    func runMonitoringSignificantLocationChanges(start: Bool = false) {

        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
           
            Task { @MainActor in
                if start {
                    await self.requestLocation()
                    self.locationManager.startMonitoringSignificantLocationChanges()
                    _run = true
                } else {
                    self.locationManager.stopMonitoringSignificantLocationChanges()
                    _run = false
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

    /// 触发一次定位。已授权走 CLLocationManager;未授权或还没拿到坐标 (`hasValidLocation == false`)
    /// 时用 IP 地理位置兜底,避免全 App 拿到 (0,0) 哨兵。
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
        self.authorizationStatus = manager.authorizationStatus
    }
}

extension Notification.Name {
    static let locationUpdated = Notification.Name("locationUpdated")
}
