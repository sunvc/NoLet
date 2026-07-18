//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ChannelUserMapUIKitView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/6/24 10:12.

import Combine
import CoreLocation
import Foundation
import MapKit
import SwiftUI
import UIKit

struct ChannelUser: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var active: Bool = false

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    mutating func update(coordinate: CLLocationCoordinate2D, active: Bool? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        if let active { self.active = active }
    }

    enum CodingKeys: CodingKey {
        case id
        case name
        case latitude
        case longitude
    }
}

extension ChannelUser {
    init(
        id: String,
        name: String,
        coordinate: CLLocationCoordinate2D,
        active: Bool = false
    ) {
        self.id = id
        self.name = name.isEmpty ? String(localized: "匿名") : name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.active = active
    }
}

final class ChannelUserAnnotation: NSObject, MKAnnotation {
    let id: String
    var userName: String
    var active: Bool
    dynamic var coordinate: CLLocationCoordinate2D

    init(user: ChannelUser) {
        self.id = user.id
        self.userName = user.name
        self.active = user.active
        self.coordinate = user.coordinate
        super.init()
    }
}

private let mapRegionTolerance = 0.0001
private let normalUserNameVisibilityThreshold = 0.5

private func regionMatches(
    _ lhs: MKCoordinateRegion,
    _ rhs: MKCoordinateRegion
) -> Bool {
    abs(lhs.center.latitude - rhs.center.latitude) < mapRegionTolerance &&
        abs(lhs.center.longitude - rhs.center.longitude) < mapRegionTolerance &&
        abs(lhs.span.latitudeDelta - rhs.span.latitudeDelta) < mapRegionTolerance &&
        abs(lhs.span.longitudeDelta - rhs.span.longitudeDelta) < mapRegionTolerance
}

private func shouldShowNormalUserNames(for region: MKCoordinateRegion) -> Bool {
    max(region.span.latitudeDelta, region.span.longitudeDelta)
        <= normalUserNameVisibilityThreshold
}

struct ChannelUserMapUIKitView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let animateRegionChanges: Bool
    let onlineUsers: [ChannelUser]

    func makeCoordinator() -> Coordinator {
        Coordinator(region: $region)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.pointOfInterestFilter = .excludingAll
        mapView.setRegion(region, animated: false)
        mapView.register(
            ChannelUserAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: ChannelUserAnnotationView.reuseIdentifier
        )

        // 确保包含用户自己
        let usersWithSelf = ensureSelfUser(in: onlineUsers)
        context.coordinator.syncAnnotations(on: mapView, with: usersWithSelf)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // 确保包含用户自己
        let usersWithSelf = ensureSelfUser(in: onlineUsers)
        context.coordinator.syncAnnotations(on: mapView, with: usersWithSelf)
        context.coordinator.updateRegionIfNeeded(
            on: mapView,
            targetRegion: region,
            animated: animateRegionChanges
        )
    }

    // 确保用户列表中包含用户自己
    private func ensureSelfUser(in users: [ChannelUser]) -> [ChannelUser] {
        let userId = Defaults[.id]
        let hasSelf = users.contains { $0.id == userId }

        if !hasSelf {
            let userCoordinate = LocManager.shared.location.coordinate
            let selfUser = ChannelUser(
                id: userId,
                name: String(localized: "本机"),
                coordinate: userCoordinate,
                active: false
            )
            var newUsers = users
            newUsers.insert(selfUser, at: 0)
            return newUsers
        } else {
            var newUsers = users
            if let index = newUsers.firstIndex(where: { $0.id == userId }) {
                let user = newUsers[index]
                let updatedUser = ChannelUser(
                    id: user.id,
                    name: String(localized: "本机"),
                    coordinate: user.coordinate,
                    active: user.active
                )
                newUsers[index] = updatedUser
            }
            return newUsers
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        @Binding private var region: MKCoordinateRegion
        private var isApplyingRegionFromSwiftUI = false

        init(region: Binding<MKCoordinateRegion>) {
            self._region = region
        }

        func syncAnnotations(
            on mapView: MKMapView,
            with users: [ChannelUser]
        ) {
            let shouldShowNames = shouldShowNormalUserNames(for: mapView.region)
            let existingAnnotations = mapView.annotations.compactMap {
                $0 as? ChannelUserAnnotation
            }
            let existingByID = Dictionary(
                uniqueKeysWithValues: existingAnnotations.map { ($0.id, $0) }
            )
            let incomingIDs = Set(users.map(\.id))

            let annotationsToRemove = existingAnnotations.filter {
                !incomingIDs.contains($0.id)
            }
            if !annotationsToRemove.isEmpty {
                mapView.removeAnnotations(annotationsToRemove)
            }

            var annotationsToAdd: [ChannelUserAnnotation] = []

            for user in users {
                if let annotation = existingByID[user.id] {
                    annotation.coordinate = user.coordinate
                    annotation.userName = user.name
                    annotation.active = user.active

                    if let annotationView = mapView.view(for: annotation)
                        as? ChannelUserAnnotationView
                    {
                        annotationView.apply(
                            user: user,
                            shouldShowNormalName: shouldShowNames
                        )
                    }
                } else {
                    annotationsToAdd.append(ChannelUserAnnotation(user: user))
                }
            }

            if !annotationsToAdd.isEmpty {
                let sortedAnnotations = annotationsToAdd.sorted {
                    ($0.active ? 1 : 0) < ($1.active ? 1 : 0)
                }
                mapView.addAnnotations(sortedAnnotations)
            }

            refreshTalkingPriority(on: mapView)
        }

        func updateRegionIfNeeded(
            on mapView: MKMapView,
            targetRegion: MKCoordinateRegion,
            animated: Bool
        ) {
            guard !regionMatches(mapView.region, targetRegion) else { return }
            isApplyingRegionFromSwiftUI = true
            mapView.setRegion(targetRegion, animated: animated)
        }

        private func refreshTalkingPriority(on mapView: MKMapView) {
            let annotationViews = mapView.annotations.compactMap { annotation in
                mapView.view(for: annotation) as? ChannelUserAnnotationView
            }

            let sortedViews = annotationViews.sorted {
                $0.annotationPriorityRank < $1.annotationPriorityRank
            }

            for annotationView in sortedViews {
                annotationView.syncDrawingPriority()
                mapView.bringSubviewToFront(annotationView)
            }
        }

        func mapView(
            _ mapView: MKMapView,
            viewFor annotation: MKAnnotation
        ) -> MKAnnotationView? {
            guard let userAnnotation = annotation as? ChannelUserAnnotation else {
                return nil
            }

            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: ChannelUserAnnotationView.reuseIdentifier,
                for: userAnnotation
            ) as! ChannelUserAnnotationView

            annotationView.apply(
                user: ChannelUser(
                    id: userAnnotation.id,
                    name: userAnnotation.userName,
                    coordinate: userAnnotation.coordinate,
                    active: userAnnotation.active
                ),
                shouldShowNormalName: shouldShowNormalUserNames(for: mapView.region)
            )

            return annotationView
        }

        func mapView(
            _ mapView: MKMapView,
            didAdd views: [MKAnnotationView]
        ) {
            refreshTalkingPriority(on: mapView)
        }

        func mapView(
            _ mapView: MKMapView,
            regionDidChangeAnimated animated: Bool
        ) {
            refreshAnnotationVisibility(on: mapView)
            refreshTalkingPriority(on: mapView)
            if isApplyingRegionFromSwiftUI {
                isApplyingRegionFromSwiftUI = false
                return
            }

            let updatedRegion = mapView.region
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                guard !regionMatches(self.region, updatedRegion) else { return }
                self.region = updatedRegion
            }
        }

        private func refreshAnnotationVisibility(on mapView: MKMapView) {
            let shouldShowNames = shouldShowNormalUserNames(for: mapView.region)

            for annotation in mapView.annotations {
                guard
                    let userAnnotation = annotation as? ChannelUserAnnotation,
                    let annotationView = mapView.view(for: userAnnotation)
                    as? ChannelUserAnnotationView
                else {
                    continue
                }

                annotationView.apply(
                    user: ChannelUser(
                        id: userAnnotation.id,
                        name: userAnnotation.userName,
                        coordinate: userAnnotation.coordinate,
                        active: userAnnotation.active
                    ),
                    shouldShowNormalName: shouldShowNames
                )
            }
        }
    }
}

final class ChannelUserAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "ChannelUserAnnotationView"

    private let talkingContainer = UIView()
    private let pulseContainerView = UIView()
    private let pulseViews = (0..<3).map { _ in UIView() }
    private let iconCircleView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = PaddingLabel()
    private let normalDotView = UIView()
    private let normalNameLabel = PaddingLabel()
    private var isAnimatingPulse = false
    private var showsNormalName = false

    var active = false
    var isSelf = false // 是否是用户自己
    var annotationPriorityRank: Int {
        if active {
            return 3
        }

        return showsNormalName ? 2 : 1
    }

    private var annotationZPriority: MKAnnotationViewZPriority {
        switch annotationPriorityRank {
        case 3:
            return .max
        case 2:
            return .defaultSelected
        default:
            return .defaultUnselected
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        talkingContainer.frame = bounds
        pulseContainerView.frame = CGRect(x: 6, y: 0, width: 40, height: 40)
        normalDotView.frame = CGRect(
            x: (bounds.width - 20) / 2,
            y: 2,
            width: 20,
            height: 20
        )
        normalNameLabel.frame = CGRect(
            x: (bounds.width - 72) / 2,
            y: 26,
            width: 72,
            height: 18
        )

        for pulseView in pulseViews {
            pulseView.frame = CGRect(x: 4, y: 4, width: 32, height: 32)
            pulseView.layer.cornerRadius = 16
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopPulse()
        isAnimatingPulse = false
    }

    func apply(user: ChannelUser, shouldShowNormalName: Bool) {
        active = user.active
        isSelf = user.id == Defaults[.id]
        showsNormalName = shouldShowNormalName && !user.active
        canShowCallout = false
        displayPriority = .required
        clusteringIdentifier = nil
        syncDrawingPriority()

        talkingContainer.isHidden = !user.active
        normalDotView.isHidden = user.active
        normalNameLabel.isHidden = !showsNormalName

        // 设置颜色，自己为橙色，其他为默认颜色
        let primaryColor: UIColor = isSelf ? .systemOrange : .systemGreen
        let secondaryColor: UIColor = isSelf ? .systemOrange : .systemBlue

        // 更新视图颜色
        iconCircleView.backgroundColor = primaryColor
        iconCircleView.layer.shadowColor = primaryColor.cgColor
        nameLabel.backgroundColor = primaryColor.withAlphaComponent(0.92)

        normalDotView.backgroundColor = secondaryColor
        normalDotView.layer.shadowColor = secondaryColor.cgColor
        normalNameLabel.backgroundColor = secondaryColor.withAlphaComponent(0.92)

        for pulseView in pulseViews {
            pulseView.layer.borderColor = primaryColor.withAlphaComponent(0.7).cgColor
        }

        if user.active {
            nameLabel.text = user.name
            centerOffset = CGPoint(x: 0, y: -12)
            bounds = CGRect(x: 0, y: 0, width: 52, height: 64)
            pulseContainerView.isHidden = false
            setNeedsLayout()
            layoutIfNeeded()
            startPulseIfNeeded()
        } else {
            normalNameLabel.text = user.name
            centerOffset = shouldShowNormalName ? CGPoint(x: 0, y: -10) : .zero
            bounds = shouldShowNormalName
                ? CGRect(x: 0, y: 0, width: 72, height: 44)
                : CGRect(x: 0, y: 0, width: 24, height: 24)
            pulseContainerView.isHidden = true
            stopPulse()
        }

        setNeedsLayout()
    }

    func syncDrawingPriority() {
        let zPosition: CGFloat

        switch annotationPriorityRank {
        case 3:
            zPosition = 30000
        case 2:
            zPosition = 500
        default:
            zPosition = 1
        }

        layer.zPosition = zPosition
        talkingContainer.layer.zPosition = zPosition
        pulseContainerView.layer.zPosition = zPosition
        iconCircleView.layer.zPosition = zPosition
        nameLabel.layer.zPosition = zPosition
        normalDotView.layer.zPosition = zPosition
        normalNameLabel.layer.zPosition = zPosition
        zPriority = annotationZPriority
    }

    private func setupView() {
        frame = CGRect(x: 0, y: 0, width: 52, height: 64)
        collisionMode = .circle
        backgroundColor = .clear
        clipsToBounds = false
        layer.masksToBounds = false

        pulseContainerView.backgroundColor = .clear
        pulseContainerView.clipsToBounds = false
        pulseContainerView.isUserInteractionEnabled = false
        pulseContainerView.isHidden = true

        for pulseView in pulseViews {
            pulseView.backgroundColor = .clear
            pulseView.alpha = 1
            pulseView.layer.opacity = 0
            pulseView.layer.borderWidth = 2.5
            pulseView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.7).cgColor
            pulseContainerView.addSubview(pulseView)
        }

        talkingContainer.addSubview(pulseContainerView)

        iconCircleView.frame = CGRect(x: 10, y: 4, width: 32, height: 32)
        iconCircleView.backgroundColor = .systemGreen
        iconCircleView.layer.cornerRadius = 16
        iconCircleView.layer.shadowColor = UIColor.systemGreen.cgColor
        iconCircleView.layer.shadowOpacity = 0.35
        iconCircleView.layer.shadowRadius = 6
        iconCircleView.layer.shadowOffset = .zero
        talkingContainer.addSubview(iconCircleView)

        iconImageView.image = UIImage(systemName: "mic.fill")
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.frame = CGRect(x: 8, y: 8, width: 16, height: 16)
        iconCircleView.addSubview(iconImageView)

        nameLabel.frame = CGRect(x: -10, y: 42, width: 72, height: 18)
        nameLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.92)
        nameLabel.textColor = .white
        nameLabel.font = .systemFont(ofSize: 11, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.layer.cornerRadius = 4
        nameLabel.clipsToBounds = true
        talkingContainer.addSubview(nameLabel)

        addSubview(talkingContainer)

        normalDotView.frame = CGRect(x: 2, y: 2, width: 20, height: 20)
        normalDotView.backgroundColor = .systemBlue
        normalDotView.layer.cornerRadius = 10
        normalDotView.layer.borderWidth = 3
        normalDotView.layer.borderColor = UIColor.white.cgColor
        normalDotView.layer.shadowColor = UIColor.systemBlue.cgColor
        normalDotView.layer.shadowOpacity = 0.25
        normalDotView.layer.shadowRadius = 4
        normalDotView.layer.shadowOffset = .zero
        addSubview(normalDotView)

        normalNameLabel.frame = CGRect(x: 0, y: 26, width: 72, height: 18)
        normalNameLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.92)
        normalNameLabel.textColor = .white
        normalNameLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        normalNameLabel.textAlignment = .center
        normalNameLabel.layer.cornerRadius = 4
        normalNameLabel.clipsToBounds = true
        normalNameLabel.isHidden = true
        addSubview(normalNameLabel)
    }

    private func startPulseIfNeeded() {
        let hasActivePulse = pulseViews.allSatisfy {
            $0.layer.animation(forKey: "pulse") != nil
        }
        guard !hasActivePulse else { return }

        stopPulse()

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.85
        scaleAnimation.toValue = 1.9

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.85
        opacityAnimation.toValue = 0

        for (index, pulseView) in pulseViews.enumerated() {
            pulseView.layer.removeAllAnimations()
            pulseView.layer.opacity = 0
            pulseView.layer.transform = CATransform3DIdentity

            let group = CAAnimationGroup()
            group.animations = [scaleAnimation, opacityAnimation]
            group.duration = 1.8
            group.beginTime = pulseView.layer.convertTime(
                CACurrentMediaTime(),
                from: nil
            ) + Double(index) * 0.28
            group.repeatCount = .infinity
            group.timingFunction = CAMediaTimingFunction(name: .easeOut)
            group.fillMode = .backwards
            group.isRemovedOnCompletion = false

            pulseView.layer.add(group, forKey: "pulse")
        }

        isAnimatingPulse = true
    }

    private func stopPulse() {
        for pulseView in pulseViews {
            pulseView.layer.removeAllAnimations()
            pulseView.layer.opacity = 0
            pulseView.layer.transform = CATransform3DIdentity
        }
        isAnimatingPulse = false
    }
}

final class PaddingLabel: UILabel {
    var contentInsets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}
