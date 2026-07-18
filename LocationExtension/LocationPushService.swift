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

    func didReceiveLocationPushPayload(_ payload: [String: Any], completion: @escaping () -> Void) {
        self.completion = completion
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate = self
        self.locationManager!.requestLocation()

        self.params.callback = payload["location"] as? String
        self.params.title = payload["title"] as? String
        self.params.subTitle = payload["subtitle"] as? String
        self.params.body = payload["body"] as? String ?? String(localized: "位置信息获取成功")
    }

    func serviceExtensionWillTerminate() {
        // Called just before the extension will be terminated by the system.
        self.completion?()
    }

    // MARK: - CLLocationManagerDelegate methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task {
            guard let callback = self.params.callback,
                  let location = locations.first else { return }

            self.params.location = "\(location.coordinate.latitude),\(location.coordinate.longitude)"

            do {
                let res = try await NetworkManager().fetch(
                    url: callback,
                    method: .POST,
                    params: self.params
                )

                debugPrint(res.check())
            } catch {
                debugPrint(error.localizedDescription)
            }
            self.completion?()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.completion?()
    }
}
