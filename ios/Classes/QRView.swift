//
//  QRView.swift
//  flutter_qr
//
//  Created by Julius Canute on 21/12/18.
//

import Foundation
import MTBBarcodeScanner

public class QRView:NSObject,FlutterPlatformView {
    var previewView: UIView!
    var scanner: MTBBarcodeScanner?
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    
    public init(withFrame frame: CGRect, registrar: FlutterPluginRegistrar, viewId: Int64){
        
        self.registrar = registrar
        previewView = UIView(frame: frame)
        
        channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/qrview_\(viewId)", binaryMessenger: registrar.messenger())
        super.init()
        
        channel.setMethodCallHandler(onMethodCall)
    }
    
    deinit {
        scanner?.stopScanning()
    }
    
    public func view() -> UIView {
        return previewView
    }
    
    func onMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch(call.method){
            case "startScan":
                let arguments = call.arguments as! Dictionary<String, Double>
                self.startScan(arguments, result)
            case "updateSettings":
                guard let settings = call.arguments else {
                  return
                }
                self.updateCameraSettings(settings as! [String : Any], result)
            case "flipCamera":
                self.flipCamera()
            case "toggleFlash":
                self.toggleFlash()
            case "pauseCamera":
                self.pauseCamera()
            case "resumeCamera":
                self.resumeCamera()
            default:
                result(FlutterMethodNotImplemented)
            return
        }
    }
    
    func startScan(_ args: [String: Any],_ result: @escaping FlutterResult) -> Void {
        let width = args["width"] as! Double
        let height = args["height"] as! Double
        let cameraFacing = MTBCamera.init(rawValue: UInt(Int(args["cameraFacing"] as! Double))) ?? MTBCamera.back
        previewView.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        scanner = MTBBarcodeScanner(previewView: previewView)
        
        MTBBarcodeScanner.requestCameraPermission(success: { permissionGranted in
            if permissionGranted {
                do {
                    try self.scanner?.startScanning(with: cameraFacing, resultBlock: { [weak self] codes in
                        if let codes = codes {
                            for code in codes {
                                guard let stringValue = code.stringValue else { continue }
                                self?.channel.invokeMethod("onRecognizeQR", arguments: stringValue)
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
    
    func updateCameraSettings(_ settings: [String: Any],_ result: @escaping FlutterResult){
        let cameraFacing = MTBCamera.init(rawValue: UInt(settings["cameraFacing"] as! Int)) ?? MTBCamera.back
        scanner?.stopScanning()
        
        do {
            try self.scanner?.startScanning(with: cameraFacing,resultBlock: { [weak self] codes in
                if let codes = codes {
                    for code in codes {
                        guard let stringValue = code.stringValue else { continue }
                        self?.channel.invokeMethod("onRecognizeQR", arguments: stringValue)
                    }
                }
            })
        } catch {
            let error = FlutterError(code: "unknown-error", message: "Unable to start scanning", details: nil)
            result(error)
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
