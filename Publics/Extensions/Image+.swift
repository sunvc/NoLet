//
//  Image+.swift
//  NoLet
//
//  Author:        Copyright (c) 2024 QingHe. All rights reserved.
//  Document:      https://wiki.wzs.app
//  E-mail:        to@wzs.app
//
//  History:
//    Created by Neo on 2025/6/5.
//
import Photos
import PhotosUI
import SwiftUI



struct ImagePickerRepresentable: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onResult: (Result<UIImage, Error>) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // 协调器：处理 UIKit 的代理回调
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerRepresentable

        init(_ parent: ImagePickerRepresentable) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false

            guard let provider = results.first?.itemProvider else {
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    if let error = error {
                        Task { @MainActor in
                            self?.parent.onResult(.failure(error))
                        }
                    } else if let uiImage = object as? UIImage {
                        Task { @MainActor in
                            self?.parent.onResult(.success(uiImage))
                        }
                    }
                }
            } else {
                parent.onResult(.failure(NSError(
                    domain: "ImageImporter",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "无法加载该格式的图片"]
                )))
            }
        }
    }
}

