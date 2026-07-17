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

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private override init() {
        super.init()
        self.locationManager.delegate = self
        self.authorizationStatus = locationManager.authorizationStatus
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    nonisolated static func openMap(latitude: Double, longitude: Double, destinationName: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = destinationName
        mapItem.openInMaps(launchOptions: [:])
    }

    func startMonitoringLocationPushes() async -> String?{
        do {
            let data = try await self.locationManager.startMonitoringLocationPushes()
            let token = data.map { String(format: "%02.2hhx", $0) }.joined()
            logger.info("位置TOKEN: \(token)")
            return token
        } catch {
            logger.error("\(error.localizedDescription)")
            return nil
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
            if let local = await LocManager.shared.queryLocation(),
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
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失败: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
    }
}

extension LocManager {
    func getFormattedAddress(latitude: Double, longitude: Double) async -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first,
               let postalAddress = placemark.postalAddress
            {
                let fullAddress = CNPostalAddressFormatter.string(
                    from: postalAddress,
                    style: .mailingAddress
                )
                return fullAddress.replacingOccurrences(of: "\n", with: " ")
            }
            return "未知位置"
        } catch {
            return "解析失败: \(error.localizedDescription)"
        }
    }

    func queryLocation() async -> CLLocation? {
        guard let data = await self.queryIpAndAddress(),
              let localStr = data.location.split(separator: "\t").first,
              let local = await self.getCoordinate(from: String(localStr))
        else {
            return nil
        }
        logger.info("大概地址: \(localStr)-[\(local.latitude):\(local.longitude)]")
        return CLLocation(
            latitude: local.latitude,
            longitude: local.longitude
        )
    }

    func getCoordinate(from addressString: String) async -> CLLocationCoordinate2D? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(addressString)
            guard let location = placemarks.first?.location else {
                throw NSError(
                    domain: "GeocoderError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "找不到该地址对应的地标信息"]
                )
            }
            return location.coordinate
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }

    private func queryIpAndAddress() async -> UserSessionInfo? {
        do {
            let network = NetworkManager()
            let res: UserSessionInfo? = try await network.fetch(
                url: "http://ip.360.cn/IPShare/info",
                headers: ["referer": "http://ip.360.cn/"]
            )
            return res
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }

    private nonisolated struct UserSessionInfo: Codable, Sendable {
        let greetHeader: String
        let nickname: String
        let ip: String
        let location: String
        let locClient: String

        enum CodingKeys: String, CodingKey {
            case greetHeader = "greetheader"
            case nickname
            case ip
            case location
            case locClient = "loc_client"
        }
    }
}

extension String {
    func location() -> (Double, Double)? {
        let localStrs = self.split(separator: ",").compactMap { String($0) }
        guard localStrs.count == 2,
              let latitude = Double(localStrs[0]),
              let longitude = Double(localStrs[1])
        else { return nil }

        return (latitude, longitude)
    }
}
