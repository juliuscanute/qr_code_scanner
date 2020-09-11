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
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64){
        self.registrar = registrar
        previewView = UIView(frame: frame)
        channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/qrview_\(id)", binaryMessenger: registrar.messenger())
    }
    
    func isCameraAvailable(success: Bool) -> Void {
        if success {
            do {
                NSLog("firing permission")
                self.channel.invokeMethod("onPermissionSet", arguments: true)
                NSLog("permission fired")
                try scanner?.startScanning(resultBlock: { codes in
                    if let codes = codes {
                        for code in codes {
                            guard let stringValue = code.stringValue else { continue }
                            self.channel.invokeMethod("onRecognizeQR", arguments: stringValue)
                        }
                    }
                })
            } catch {
                NSLog("Unable to start scanning")
            }
        } else {
            self.channel.invokeMethod("onPermissionSet", arguments: false)
        }
    }
    
    func showNativeAlertDialog(_ result: @escaping FlutterResult) -> Void {
        UIAlertView(title: "Scanning Unavailable", message: "This app does not have permission to access the camera", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "Ok").show()
        return result(true)
    }
    
    func getSystemFeatures(_ result: @escaping FlutterResult) -> Void {
        NSLog("in get system features")
        if let sc: MTBBarcodeScanner = scanner {
            var hasBackCameraVar = false
            var hasFrontCameraVar = false
            let camera = sc.camera
            var camera_id = 1
        
            if(camera == MTBCamera(rawValue: 0)){
                camera_id = 0
                hasBackCameraVar = true
                if sc.hasOppositeCamera() {
                    hasFrontCameraVar = true
                }
            }else{
                hasFrontCameraVar = false
                if sc.hasOppositeCamera() {
                    hasBackCameraVar = true
                }
            }
            NSLog("returning get system features")
            return result([
                "hasFrontCamera": hasFrontCameraVar,
                "hasBackCamera": hasBackCameraVar,
                "hasFlash": sc.hasTorch(),
                "activeCamera": camera_id
            ])
        }
        NSLog("scanner not avaible")
        return result(FlutterError(code: "404", message: nil, details: nil))
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch(call.method){
                case "setDimensions":
                    var arguments = call.arguments as! Dictionary<String, Double>
                    self?.setDimensions(width: arguments["width"] ?? 0,height: arguments["height"] ?? 0)
                case "flipCamera":
                    self?.flipCamera(result)
                case "toggleFlash":
                    self?.toggleFlash(result)
                case "pauseCamera":
                    self?.pauseCamera(result)
                case "resumeCamera":
                    self?.resumeCamera(result)
                case "showNativeAlertDialog":
                    self?.showNativeAlertDialog(result)
                case "getSystemFeatures":
                    self?.getSystemFeatures(result)
                default:
                    result(FlutterMethodNotImplemented)
                    return
            }
        })
        return previewView
    }
    
    func setDimensions(width: Double, height: Double) -> Void {
       previewView.frame = CGRect(x: 0, y: 0, width: width, height: height)
       scanner = MTBBarcodeScanner(previewView: previewView)
       MTBBarcodeScanner.requestCameraPermission(success: isCameraAvailable)
    }
    
    func flipCamera(_ result: @escaping FlutterResult){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.hasOppositeCamera() {
                sc.flipCamera()
            }
            return result(sc.camera.rawValue)
        }
        return result(FlutterError(code: "404", message: "No barcode scanner found", details: nil))
    }
    
    func toggleFlash(_ result: @escaping FlutterResult){
        if let sc: MTBBarcodeScanner = scanner {
            if sc.hasTorch() {
                sc.toggleTorch()
                return result(sc.torchMode == MTBTorchMode(rawValue: 1))
            }
            return result(FlutterError(code: "404", message: "This device doesn\'t support flash", details: nil))
        }
        return result(FlutterError(code: "404", message: "No barcode scanner found", details: nil))
    }
    
    func pauseCamera(_ result: @escaping FlutterResult) {
        if let sc: MTBBarcodeScanner = scanner {
            if sc.isScanning() {
                sc.freezeCapture()
            }
            return result(true)
        }
        return result(FlutterError(code: "404", message: "No barcode scanner found", details: nil))
    }
    
    func resumeCamera(_ result: @escaping FlutterResult) {
        if let sc: MTBBarcodeScanner = scanner {
            if !sc.isScanning() {
                sc.unfreezeCapture()
            }
            return result(true)
        }
        return result(FlutterError(code: "404", message: "No barcode scanner found", details: nil))
    }
}
