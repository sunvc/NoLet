//
//  SFSafariView.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//
//  History:
//    Created by Neo 2024/10/8.
//

import SafariServices
import SwiftUI
import UIKit

class NoLetSafariViewController: SFSafariViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    deinit {
        Task {
            await SFSafariViewController.DataStore.default.clearWebsiteData()
        }
    }
}

struct SFSafariView: UIViewControllerRepresentable {
    let url: URL
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let sfVC = NoLetSafariViewController(url: url)
        sfVC.delegate = context.coordinator
        return sfVC
    }

    func updateUIViewController(_: SFSafariViewController, context _: Context) {
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var onDismiss: (() -> Void)?

        init(onDismiss: (() -> Void)?) {
            self.onDismiss = onDismiss
        }

        // Delegate method to handle dismissal
        func safariViewControllerDidFinish(_: SFSafariViewController) {
            onDismiss?()
        }
    }
}
