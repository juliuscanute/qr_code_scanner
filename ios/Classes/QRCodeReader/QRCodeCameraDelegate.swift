//
//  QrCodeCameraDelegate.swift
//  QRCodeReader
//
//  Created by kazuhiro_nanko on 2022/09/16.
//

import Foundation
import AVFoundation
import CoreImage

class QRCodeCameraDelegate: NSObject {
    
    private var lastTime = Date(timeIntervalSince1970: 0)
    var scanInterval: Double = 1.0
    var onResult: (QRCode) -> Void = { _  in }
    var onError: (Error) -> Void = { _  in }

    private func foundBarcode(readableCodeObject: AVMetadataMachineReadableCodeObject) {
        guard let stringValue = readableCodeObject.stringValue else { return }
        guard let descriptor = readableCodeObject.descriptor as? CIQRCodeDescriptor else { return }
        
        let now = Date()
        if now.timeIntervalSince(lastTime) >= scanInterval {
            lastTime = now
            self.onResult(
                .init(rawValue: stringValue, data: descriptor.errorCorrectedPayload as NSData)
            )
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeCameraDelegate: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        for metadata in metadataObjects {
            guard let readableCodeObject = metadata as? AVMetadataMachineReadableCodeObject else {
                continue
            }
            // QRコードのデータかどうかの確認
            if readableCodeObject.type == AVMetadataObject.ObjectType.qr {
                foundBarcode(readableCodeObject: readableCodeObject)
            }
        }
    }
}
