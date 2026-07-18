//
//  SWIFT: 6.0 - MACOS: 15.7 
//  NoLet - CLGeocoderManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/7/18 20:16.
    
import Contacts
import CoreLocation
import Foundation
import MapKit
import OSLog


final class CLGeocoderManager {
    
    nonisolated let logger = Logger(subsystem: "app.wzs.logger", category: "CLGeocoderManager")
    
    static let shared = CLGeocoderManager()
    
    private init(){}
    
    let geocoder = CLGeocoder()
    
    
    func resolveLocationTitle(for coordinate: CLLocationCoordinate2D) async -> String? {
     
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }

            let candidates = [
                placemark.name,
                placemark.locality,
                placemark.subLocality,
                placemark.administrativeArea,
            ]
            return candidates
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty && $0 != placemark.country })
        } catch {
            logger.debug("Resolve location title failed: \(error.localizedDescription)")
            return nil
        }
    }
    
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
            return String(localized: "未知位置")
        } catch {
            logger.error("Parsing failed: \(error.localizedDescription)")
            return ""
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
