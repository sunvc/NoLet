//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - ScanerDocument.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/9/6 07:47.

import SwiftUI
import VisionKit

struct ScanerDocument: UIViewControllerRepresentable {
    var didFinishWithError: (Error) -> Void
    var didCancel: () -> Void
    var didFinish: (VNDocumentCameraScan) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(
        _ uiViewController: VNDocumentCameraViewController,
        context: Context
    ) {}

    @MainActor
    class Coordinator: NSObject, @MainActor VNDocumentCameraViewControllerDelegate {
        var parent: ScanerDocument
        init(parent: ScanerDocument) {
            self.parent = parent
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.didCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            parent.didFinish(scan)
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: any Error
        ) {
            parent.didFinishWithError(error)
        }
    }
}
