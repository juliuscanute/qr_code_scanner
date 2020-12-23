//
//  QRView.swift
//  flutter_qr
//
//  Created by Julius Canute on 21/12/18.
//

import Foundation
import MTBBarcodeScanner

public class QRView:NSObject,FlutterPlatformView {
    @IBOutlet var previewView: UIView!
    var scanner: MTBBarcodeScanner?
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var cameraFacing: MTBCamera
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64, params: Dictionary<String, Any>){
        self.registrar = registrar
        previewView = UIView(frame: frame)
        cameraFacing = MTBCamera.init(rawValue: UInt(Int(params["cameraFacing"] as! Double))) ?? MTBCamera.back
        channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/qrview_\(id)", binaryMessenger: registrar.messenger())
    }
    
    deinit {
        scanner?.stopScanning()
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch(call.method){
                case "setDimensions":
                    let arguments = call.arguments as! Dictionary<String, Double>
                    self?.setDimensions(width: arguments["width"] ?? 0, height: arguments["height"] ?? 0, scanArea: arguments["scanArea"] ?? 0)
                case "startScan":
                    self?.startScan(result)
                case "flipCamera":
                    self?.flipCamera()
                case "toggleFlash":
                    self?.toggleFlash()
                case "pauseCamera":
                    self?.pauseCamera()
                case "resumeCamera":
                    self?.resumeCamera()
                default:
                    result(FlutterMethodNotImplemented)
                    return
            }
        })
        return previewView
    }
    
    func setDimensions(width: Double, height: Double, scanArea: Double) -> Void {
        previewView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        let midX = self.view().bounds.midX
        let midY = self.view().bounds.midY
        if let sc: MTBBarcodeScanner = scanner {
            if let previewLayer = sc.previewLayer {
                previewLayer.frame = previewView.bounds;
            }
        } else {
            scanner = MTBBarcodeScanner(previewView: previewView)
            
            if (scanArea != 0) {
                scanner?.didStartScanningBlock = {
                    self.scanner?.scanRect = CGRect(x: Double(midX) - (scanArea / 2), y: Double(midY) - (scanArea / 2), width: scanArea, height: scanArea)
                }
            }
        }
    }
    
    func startScan(_ result: @escaping FlutterResult) -> Void {
        scanner = MTBBarcodeScanner(previewView: previewView)
        
        MTBBarcodeScanner.requestCameraPermission(success: { permissionGranted in
            if permissionGranted {
                do {
                    try self.scanner?.startScanning(with: self.cameraFacing, resultBlock: { [weak self] codes in
                        if let codes = codes {
                            for code in codes {
                                var typeString: String;
                                switch(code.type) {
                                    case AVMetadataObject.ObjectType.aztec:
                                       typeString = "AZTEC"
                                    case AVMetadataObject.ObjectType.code39:
                                        typeString = "CODE_39"
                                    case AVMetadataObject.ObjectType.code93:
                                        typeString = "CODE_93"
                                    case AVMetadataObject.ObjectType.code128:
                                        typeString = "CODE_128"
                                    case AVMetadataObject.ObjectType.dataMatrix:
                                        typeString = "DATA_MATRIX"
                                    case AVMetadataObject.ObjectType.ean8:
                                        typeString = "EAN_8"
                                    case AVMetadataObject.ObjectType.ean13:
                                        typeString = "EAN_13"
                                    case AVMetadataObject.ObjectType.itf14:
                                        typeString = "ITF"
                                    case AVMetadataObject.ObjectType.pdf417:
                                        typeString = "PDF_417"
                                    case AVMetadataObject.ObjectType.qr:
                                        typeString = "QR_CODE"
                                    case AVMetadataObject.ObjectType.upce:
                                        typeString = "UPC_E"
                                    default:
                                        return
                                }
                                guard let stringValue = code.stringValue else { continue }
                                let result = ["code": stringValue, "type": typeString]
                                self?.channel.invokeMethod("onRecognizeQR", arguments: result)
                            }
                        }
                    })
                } catch {
                    let error = FlutterError(code: "unknown-error", message: "Unable to start scanning", details: nil)
                    result(error)
                }
            } else {
                let error = FlutterError(code: "cameraPermission", message: "Permission denied to access the camera", details: nil)
                result(error)
            }
        })
    }
    
    func stopScan(){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.isScanning() {
                sc.stopScanning()
            }
        }
    }
    
    func flipCamera(){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.hasOppositeCamera() {
                sc.flipCamera()
            }
        }
    }
    
    func toggleFlash(){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.hasTorch() {
                sc.toggleTorch()
            }
        }
    }
    
    func pauseCamera() {
        if let sc: MTBBarcodeScanner = scanner {
            if sc.isScanning() {
                sc.freezeCapture()
            }
        }
    }
    
    func resumeCamera() {
        if let sc: MTBBarcodeScanner = scanner {
            if !sc.isScanning() {
                sc.unfreezeCapture()
            }
        }
    }
}
