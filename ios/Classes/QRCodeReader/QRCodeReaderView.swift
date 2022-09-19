//
//  QRCodeScannerView.swift
//  QRCodeReader
//
//  Created by kazuhiro_nanko on 2022/09/16.
//

import SwiftUI
import AVFoundation

struct QRCode {
    let rawValue: String
    let data: NSData
}

struct QRCodeReaderView: UIViewRepresentable {
    typealias UIViewType = CameraPreview
    
    private let supportedBarcodeTypes: [AVMetadataObject.ObjectType] = [.qr]
    private let session = AVCaptureSession()
    private let delegate = QRCodeCameraDelegate()
    private let metadataOutput = AVCaptureMetadataOutput()
    
    private func setupSession() {
        // Find the default video device.
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {            
            // Wrap the video device in a capture device input.
            let input = try AVCaptureDeviceInput(device: videoDevice)
            // If the input can be added, add it to the session.
            if session.canAddInput(input) {
                session.addInput(input)
            }
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                
                metadataOutput.metadataObjectTypes = supportedBarcodeTypes
                metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            }
        } catch {
            // Configuration failed. Handle error.
            delegate.onError(QRCodeReaderError.someReason)
        }
    }
    
    func startSession() {
        session.startRunning()
    }
    
    func stopSession() {
        session.stopRunning()
    }
    
    func makeUIView(context: UIViewRepresentableContext<QRCodeReaderView>) -> QRCodeReaderView.UIViewType {
        let cameraView = CameraPreview(session: session)
        
        // check authorizationStatus.
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraAuthorizationStatus == .authorized {
            setupSession()
            startSession（）
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.sync {
                    if granted {
                        self.setupSession()
                        self.startSession()
                    }
                }
            }
        }
        return cameraView
    }
    
    func updateUIView(_ uiView: CameraPreview, context: UIViewRepresentableContext<QRCodeReaderView>) {
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }
}

// MARK: - static

extension QRCodeReaderView {
    static func disposeSession(_ uiView: CameraPreview, coordinator: ()) {
        uiView.session?.stopRunning()
    }
}

// MARK: - fluent interface

extension QRCodeReaderView {
    func interval(delay: Double) -> QRCodeReaderView {
        delegate.scanInterval = delay
        return self
    }
    
    func found(completion: @escaping (QRCode) -> Void) -> QRCodeReaderView {
        delegate.onResult = { qrcode in
            completion(qrcode)
            startSession()
        }
        return self
    }
    
    func error(completion: @escaping (Error) -> Void) -> QRCodeReaderView {
        delegate.onError = completion
        return self
    }
}

