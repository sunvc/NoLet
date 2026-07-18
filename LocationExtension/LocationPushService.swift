//
//  SWIFT: 6.0 - MACOS: 15.7
//  LocationExtension - LocationPushService.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/25 12:04.

import CoreLocation
import OSLog

nonisolated struct MessageParams: Codable, Sendable {
    var title: String?
    var subTitle: String?
    var body: String?
    var location: String?
    var callback: String?

    enum CodingKeys: String, CodingKey {
        case title
        case subTitle
        case body
        case location
    }
}

class LocationPushService: NSObject, CLLocationPushServiceExtension,
    CLLocationManagerDelegate
{
    var completion: (() -> Void)?
    var locationManager: CLLocationManager?
    var params = MessageParams()
    var SUCCESS: Bool = false

    func didReceiveLocationPushPayload(_ payload: [String: Any], completion: @escaping () -> Void) {
        self.completion = completion

        self.params.callback = payload["location"] as? String
        self.params.title = payload["title"] as? String ?? String(localized: "获取位置")
        self.params.subTitle = payload["subtitle"] as? String
        self.params.body = payload["body"] as? String ?? String(localized: "位置信息获取成功")

        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
        self.locationManager!.requestLocation()
    }

    func serviceExtensionWillTerminate() {
        // Called just before the extension will be terminated by the system.
        self.stopLocation()
    }

    // MARK: - CLLocationManagerDelegate methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !SUCCESS else { return }
        guard let location = locations.last else {
            self.stopLocation()
            return
        }
        self.SUCCESS = true
        self.params.location = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        Task {
            var index = 0
            while index < 3 {
                index += 1
                let success = await self.fetchCallback()
                if success {
                    self.stopLocation()
                    return
                }
            }
            self.stopLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.stopLocation()
    }

    func fetchCallback() async -> Bool {
        guard let callback = self.params.callback else {
            return false
        }
        do {
            let res = try await NetworkManager().fetch(
                url: callback,
                method: .POST,
                params: self.params
            )
            return res.check()
        } catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
    }

    func stopLocation() {
        self.locationManager = nil
        self.completion?()
    }
}
