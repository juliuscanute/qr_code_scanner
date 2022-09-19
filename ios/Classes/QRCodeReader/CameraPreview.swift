//
//  CameraPreview.swift
//  QRCodeReader
//
//  Created by kazuhiro_nanko on 2022/09/16.
//

import UIKit
import AVFoundation

class CameraPreview: UIView {

    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    private(set) var session: AVCaptureSession?
    weak var delegate: QRCodeCameraDelegate?

    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        self.session = session
        setup(session: session)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(session: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        backgroundColor = UIColor.blue
        previewLayer!.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer!)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = self.bounds
    }
}
