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
import UIKit
import SwiftUI




class NoLetSafariViewController: SFSafariViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
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
	var onDismiss: (() -> Void)? // 闭包处理关闭事件

	func makeUIViewController(context: Context) -> SFSafariViewController {
		let sfVC = NoLetSafariViewController(url: url)
		sfVC.delegate = context.coordinator // 设置委托
		return sfVC
	}

	func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
		// 不需要更新
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
		func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
			onDismiss?() // 调用闭包处理关闭
		}
	}
}
