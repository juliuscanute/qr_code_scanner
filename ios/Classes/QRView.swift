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
    
    var allowedBarcodeTypes: Array<AVMetadataObject.ObjectType> = []

   var QRCodeTypes = [
        0: AVMetadataObject.ObjectType.aztec,
        1: AVMetadataObject.ObjectType.code128,
        2: AVMetadataObject.ObjectType.code39,
        3: AVMetadataObject.ObjectType.code93,
        4: AVMetadataObject.ObjectType.dataMatrix,
        5: AVMetadataObject.ObjectType.ean13,
        6: AVMetadataObject.ObjectType.ean8,
        7: AVMetadataObject.ObjectType.interleaved2of5,
        8: AVMetadataObject.ObjectType.pdf417,
        9: AVMetadataObject.ObjectType.qr,
        10: AVMetadataObject.ObjectType.upce
       ]
    
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
                try scanner?.startScanning(resultBlock: { [weak self] codes in
                    if let codes = codes {
                        for code in codes {
                            guard let stringValue = code.stringValue else { continue }
                            if self == nil{
                                continue
                            }
                            else if self!.allowedBarcodeTypes.count == 0 || self!.allowedBarcodeTypes.contains(code.type){
                                self?.channel.invokeMethod("onRecognizeQR", arguments: stringValue)
                            }
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
        if let sc: MTBBarcodeScanner = scanner {
            var hasBackCameraVar = false
            var hasFrontCameraVar = false
            let camera = sc.camera
        
            if(camera == MTBCamera(rawValue: 0)){
                hasBackCameraVar = true
                if sc.hasOppositeCamera() {
                    hasFrontCameraVar = true
                }
            }else{
                hasFrontCameraVar = true
                if sc.hasOppositeCamera() {
                    hasBackCameraVar = true
                }
            }
            return result([
                "hasFrontCamera": hasFrontCameraVar,
                "hasBackCamera": hasBackCameraVar,
                "hasFlash": sc.hasTorch(),
                "activeCamera": camera.rawValue
            ])
        }
        return result(FlutterError(code: "404", message: nil, details: nil))
    }
    
    func setBarcodeFormats(_ arguments: Array<Int>, _ result: @escaping FlutterResult){
        do{
            allowedBarcodeTypes.removeAll()
            try arguments.forEach { arg in
                allowedBarcodeTypes.append(try QRCodeTypes[arg]!)
            }
            result(true)
        }catch{
            result(FlutterError(code: "404", message: nil, details: nil))
        }
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch(call.method){
                case "setDimensions":
                    let arguments = call.arguments as! Dictionary<String, Double>
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
                case "setAllowedBarcodeFormats":
                    self?.setBarcodeFormats(call.arguments as! Array<Int>, result)
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
