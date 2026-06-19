//
//  SWIFT: 6.0 - MACOS: 15.7
//  NoLet - PageCurlView.swift
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app

//  Description:

//  History:
//    Created by Neo on 2026/1/21 15:55.
import SwiftUI

struct PageCurlView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal
        )

        let pages = [
            PageVC(text: "第一页第一页第一页第一页第一页第一页第一页"),
            PageVC(text: "第二页第二页第二页第二页第二页第二页第二页第二页"),
            PageVC(text: "第三页第三页第三页第三页第三页第三页第三页第三页第三页"),
            PageVC(text: "第四页第四页第四页第四页第四页第四页第四页第四页第四页"),
        ]

        context.coordinator.pages = pages
        pageVC.dataSource = context.coordinator

        pageVC.setViewControllers(
            [pages.first!],
            direction: .forward,
            animated: false
        )

        return pageVC
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource {
        var pages: [UIViewController] = []

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard
                let index = pages.firstIndex(of: viewController),
                index > 0
            else { return pages[pages.count - 1] }
            return pages[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard
                let index = pages.firstIndex(of: viewController),
                index < pages.count - 1
            else { return pages[0] }
            return pages[index + 1]
        }
    }
}

final class PageVC: UIViewController {
    init(text: String) {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .systemBackground
        view.superview?.layer.shadowColor = .init(gray: 0.3, alpha: 0.3)
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 36, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: padding.top),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding.left),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding.bottom),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding.right),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}

#Preview {
    PageCurlView()
        .ignoresSafeArea()
}
