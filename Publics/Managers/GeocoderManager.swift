//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - GeocoderManager.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/25 19:21.

import Contacts
import MapKit

nonisolated class GeocoderManager {
    private let geocoder = CLGeocoder()

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
