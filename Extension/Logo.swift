//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - Logo.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2025/11/29 18:21.
import Foundation
import SwiftUI

struct AssistantIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.49982 * width, y: 0.57525 * height))
        path.addCurve(
            to: CGPoint(x: 0.51852 * width, y: 0.56445 * height),
            control1: CGPoint(x: 0.50935 * width, y: 0.57525 * height),
            control2: CGPoint(x: 0.51556 * width, y: 0.57165 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.52297 * width, y: 0.51598 * height),
            control1: CGPoint(x: 0.52148 * width, y: 0.55726 * height),
            control2: CGPoint(x: 0.52297 * width, y: 0.5411 * height)
        )
        path.addLine(to: CGPoint(x: 0.52297 * width, y: 0.26198 * height))
        path.addCurve(
            to: CGPoint(x: 0.51902 * width, y: 0.21082 * height),
            control1: CGPoint(x: 0.52297 * width, y: 0.23474 * height),
            control2: CGPoint(x: 0.52163 * width, y: 0.21767 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.50046 * width, y: 0.20052 * height),
            control1: CGPoint(x: 0.5164 * width, y: 0.20398 * height),
            control2: CGPoint(x: 0.5102 * width, y: 0.20052 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.48162 * width, y: 0.21146 * height),
            control1: CGPoint(x: 0.49072 * width, y: 0.20052 * height),
            control2: CGPoint(x: 0.48465 * width, y: 0.20419 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.47703 * width, y: 0.26198 * height),
            control1: CGPoint(x: 0.47859 * width, y: 0.21873 * height),
            control2: CGPoint(x: 0.47703 * width, y: 0.23559 * height)
        )
        path.addLine(to: CGPoint(x: 0.47703 * width, y: 0.51217 * height))
        path.addCurve(
            to: CGPoint(x: 0.48134 * width, y: 0.56601 * height),
            control1: CGPoint(x: 0.47703 * width, y: 0.54195 * height),
            control2: CGPoint(x: 0.47844 * width, y: 0.55987 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.49989 * width, y: 0.57518 * height),
            control1: CGPoint(x: 0.48416 * width, y: 0.57214 * height),
            control2: CGPoint(x: 0.49037 * width, y: 0.57518 * height)
        )
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.50004 * width, y: 0.05701 * height))
        path.addCurve(
            to: CGPoint(x: 0.02942 * width, y: 0.50004 * height),
            control1: CGPoint(x: 0.2401 * width, y: 0.05701 * height),
            control2: CGPoint(x: 0.02942 * width, y: 0.25534 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.16722 * width, y: 0.81331 * height),
            control1: CGPoint(x: 0.02942 * width, y: 0.62238 * height),
            control2: CGPoint(x: 0.08213 * width, y: 0.73315 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.14683 * width, y: 0.90157 * height),
            control1: CGPoint(x: 0.20518 * width, y: 0.85247 * height),
            control2: CGPoint(x: 0.17272 * width, y: 0.87977 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.12968 * width, y: 0.94306 * height),
            control1: CGPoint(x: 0.12799 * width, y: 0.91752 * height),
            control2: CGPoint(x: 0.11254 * width, y: 0.9305 * height)
        )
        path.addLine(to: CGPoint(x: 0.50004 * width, y: 0.94306 * height))
        path.addCurve(
            to: CGPoint(x: 0.97065 * width, y: 0.50011 * height),
            control1: CGPoint(x: 0.75997 * width, y: 0.94306 * height),
            control2: CGPoint(x: 0.97065 * width, y: 0.7448 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.50004 * width, y: 0.05701 * height),
            control1: CGPoint(x: 0.97065 * width, y: 0.25542 * height),
            control2: CGPoint(x: 0.7599 * width, y: 0.05701 * height)
        )
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.34911 * width, y: 0.30509 * height))
        path.addCurve(
            to: CGPoint(x: 0.36132 * width, y: 0.19932 * height),
            control1: CGPoint(x: 0.34911 * width, y: 0.25803 * height),
            control2: CGPoint(x: 0.35321 * width, y: 0.22275 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.40979 * width, y: 0.14295 * height),
            control1: CGPoint(x: 0.36943 * width, y: 0.1759 * height),
            control2: CGPoint(x: 0.38559 * width, y: 0.15706 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.49771 * width, y: 0.12171 * height),
            control1: CGPoint(x: 0.43399 * width, y: 0.12877 * height),
            control2: CGPoint(x: 0.46328 * width, y: 0.12171 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.57306 * width, y: 0.13646 * height),
            control1: CGPoint(x: 0.52579 * width, y: 0.12171 * height),
            control2: CGPoint(x: 0.55091 * width, y: 0.12665 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.6228 * width, y: 0.17244 * height),
            control1: CGPoint(x: 0.59522 * width, y: 0.14626 * height),
            control2: CGPoint(x: 0.6118 * width, y: 0.15826 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.6451 * width, y: 0.22028 * height),
            control1: CGPoint(x: 0.63381 * width, y: 0.18662 * height),
            control2: CGPoint(x: 0.64122 * width, y: 0.2025 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.65096 * width, y: 0.30516 * height),
            control1: CGPoint(x: 0.64898 * width, y: 0.23799 * height),
            control2: CGPoint(x: 0.65096 * width, y: 0.26628 * height)
        )
        path.addLine(to: CGPoint(x: 0.65096 * width, y: 0.47619 * height))
        path.addCurve(
            to: CGPoint(x: 0.64461 * width, y: 0.56107 * height),
            control1: CGPoint(x: 0.65096 * width, y: 0.51506 * height),
            control2: CGPoint(x: 0.64884 * width, y: 0.54336 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.61829 * width, y: 0.61081 * height),
            control1: CGPoint(x: 0.64037 * width, y: 0.57878 * height),
            control2: CGPoint(x: 0.63162 * width, y: 0.59536 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.57017 * width, y: 0.64404 * height),
            control1: CGPoint(x: 0.60495 * width, y: 0.62619 * height),
            control2: CGPoint(x: 0.58894 * width, y: 0.63734 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.50716 * width, y: 0.6542 * height),
            control1: CGPoint(x: 0.5514 * width, y: 0.65081 * height),
            control2: CGPoint(x: 0.53037 * width, y: 0.6542 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.43082 * width, y: 0.64362 * height),
            control1: CGPoint(x: 0.47654 * width, y: 0.6542 * height),
            control2: CGPoint(x: 0.45107 * width, y: 0.65067 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.38235 * width, y: 0.61053 * height),
            control1: CGPoint(x: 0.41057 * width, y: 0.63656 * height),
            control2: CGPoint(x: 0.39441 * width, y: 0.62549 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.35666 * width, y: 0.56318 * height),
            control1: CGPoint(x: 0.37028 * width, y: 0.59557 * height),
            control2: CGPoint(x: 0.36174 * width, y: 0.57976 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.34904 * width, y: 0.48416 * height),
            control1: CGPoint(x: 0.35158 * width, y: 0.5466 * height),
            control2: CGPoint(x: 0.34904 * width, y: 0.52029 * height)
        )
        path.addLine(to: CGPoint(x: 0.34904 * width, y: 0.30523 * height))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.78191 * width, y: 0.61913 * height))
        path.addCurve(
            to: CGPoint(x: 0.71643 * width, y: 0.71636 * height),
            control1: CGPoint(x: 0.76639 * width, y: 0.65575 * height),
            control2: CGPoint(x: 0.74458 * width, y: 0.68814 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.61921 * width, y: 0.78191 * height),
            control1: CGPoint(x: 0.68856 * width, y: 0.7443 * height),
            control2: CGPoint(x: 0.65554 * width, y: 0.7666 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.50011 * width, y: 0.80597 * height),
            control1: CGPoint(x: 0.58153 * width, y: 0.79793 * height),
            control2: CGPoint(x: 0.54103 * width, y: 0.80611 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.38108 * width, y: 0.78191 * height),
            control1: CGPoint(x: 0.45869 * width, y: 0.80597 * height),
            control2: CGPoint(x: 0.4189 * width, y: 0.79793 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.28385 * width, y: 0.71636 * height),
            control1: CGPoint(x: 0.34446 * width, y: 0.76639 * height),
            control2: CGPoint(x: 0.31207 * width, y: 0.74458 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.2183 * width, y: 0.61913 * height),
            control1: CGPoint(x: 0.25563 * width, y: 0.68814 * height),
            control2: CGPoint(x: 0.23382 * width, y: 0.65575 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.24328 * width, y: 0.55747 * height),
            control1: CGPoint(x: 0.20814 * width, y: 0.59522 * height),
            control2: CGPoint(x: 0.21936 * width, y: 0.56756 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.30495 * width, y: 0.58245 * height),
            control1: CGPoint(x: 0.2672 * width, y: 0.54731 * height),
            control2: CGPoint(x: 0.29486 * width, y: 0.55853 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.35038 * width, y: 0.6499 * height),
            control1: CGPoint(x: 0.31553 * width, y: 0.60763 * height),
            control2: CGPoint(x: 0.33098 * width, y: 0.63057 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.50018 * width, y: 0.71185 * height),
            control1: CGPoint(x: 0.38961 * width, y: 0.69033 * height),
            control2: CGPoint(x: 0.44387 * width, y: 0.71276 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.6499 * width, y: 0.6499 * height),
            control1: CGPoint(x: 0.55648 * width, y: 0.71276 * height),
            control2: CGPoint(x: 0.61067 * width, y: 0.69033 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.69541 * width, y: 0.58252 * height),
            control1: CGPoint(x: 0.6693 * width, y: 0.63064 * height),
            control2: CGPoint(x: 0.68475 * width, y: 0.6077 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.73301 * width, y: 0.55309 * height),
            control1: CGPoint(x: 0.70169 * width, y: 0.56664 * height),
            control2: CGPoint(x: 0.71608 * width, y: 0.55535 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.77697 * width, y: 0.57165 * height),
            control1: CGPoint(x: 0.74995 * width, y: 0.55084 * height),
            control2: CGPoint(x: 0.76681 * width, y: 0.55796 * height)
        )
        path.addCurve(
            to: CGPoint(x: 0.78205 * width, y: 0.61913 * height),
            control1: CGPoint(x: 0.7872 * width, y: 0.58534 * height),
            control2: CGPoint(x: 0.78911 * width, y: 0.60354 * height)
        )
        path.closeSubpath()
        return path
    }
}


