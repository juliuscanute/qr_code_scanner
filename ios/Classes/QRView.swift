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
    
    var QRCodeTypes = [
          0: AVMetadataObject.ObjectType.aztec,
          2: AVMetadataObject.ObjectType.code39,
          3: AVMetadataObject.ObjectType.code93,
          4: AVMetadataObject.ObjectType.code128,
          5: AVMetadataObject.ObjectType.dataMatrix,
          6: AVMetadataObject.ObjectType.ean8,
          7: AVMetadataObject.ObjectType.ean13,
          8: AVMetadataObject.ObjectType.interleaved2of5,
          10: AVMetadataObject.ObjectType.pdf417,
          11: AVMetadataObject.ObjectType.qr,
          15: AVMetadataObject.ObjectType.upce
         ]
    
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
                    self?.setDimensions(result,
                                        width: arguments["width"] ?? 0,
                                        height: arguments["height"] ?? 0,
                                        scanArea: arguments["scanArea"] ?? 0,
                                        scanAreaOffset: arguments["scanAreaOffset"] ?? 0)
                case "startScan":
                    self?.startScan(call.arguments as! Array<Int>, result)
                case "flipCamera":
                    self?.flipCamera(result)
                case "toggleFlash":
                    self?.toggleFlash(result)
                case "pauseCamera":
                    self?.pauseCamera(result)
                case "resumeCamera":
                    self?.resumeCamera(result)
                case "getCameraInfo":
                    self?.getCameraInfo(result)
                case "getFlashInfo":
                    self?.getFlashInfo(result)
                case "getSystemFeatures":
                    self?.getSystemFeatures(result)
                default:
                    result(FlutterMethodNotImplemented)
                    return
            }
        })
        return previewView
    }
    
    func setDimensions(_ result: @escaping FlutterResult, width: Double, height: Double, scanArea: Double, scanAreaOffset: Double) -> Void {
        MTBBarcodeScanner.requestCameraPermission(success: { permissionGranted in
            if permissionGranted {
                // First set the size of the preview area.
                self.previewView.frame = CGRect(x: 0, y: 0, width: width, height: height)
                
                // Then set the size of the scan area.
                let midX = self.view().bounds.midX
                let midY = self.view().bounds.midY
                
                // Check if the scanner is already created.
                if let sc: MTBBarcodeScanner = self.scanner {
                    if let previewLayer = sc.previewLayer {
                        previewLayer.frame = self.previewView.bounds;
                    }
                    if (scanArea != 0) {
                        sc.scanRect = CGRect(x: Double(midX) - (scanArea / 2), y: Double(midY) - (scanArea / 2), width: scanArea, height: scanArea)
                        
                        // Set offset if provided.
                        if (scanAreaOffset != 0) {
                            sc.scanRect = sc.scanRect.offsetBy(dx: 0, dy: CGFloat(scanAreaOffset))
                        }
                    }
                } else {
                    // Create a scanner view if it doesn't exist yet.
                    self.scanner = MTBBarcodeScanner(previewView: self.previewView)
                    
                    if (scanArea != 0) {
                        self.scanner?.didStartScanningBlock = {
                            self.scanner?.scanRect = CGRect(x: Double(midX) - (scanArea / 2), y: Double(midY) - (scanArea / 2), width: scanArea, height: scanArea)
                            
                            // Set offset if provided.
                            if (scanAreaOffset != 0) {
                                self.scanner?.scanRect = (self.scanner?.scanRect.offsetBy(dx: 0, dy: CGFloat(scanAreaOffset)))!
                            }
                        }
                    }
                }
                return result(width)
            } else {
                return result(FlutterError(code: "cameraPermission", message: "Permission denied to access the camera", details: nil))
            }
        })
    }
    
    func startScan(_ arguments: Array<Int>, _ result: @escaping FlutterResult) -> Void {
        if (scanner == nil) {
            scanner = MTBBarcodeScanner(previewView: previewView)
        }
        
        
        var allowedBarcodeTypes: Array<AVMetadataObject.ObjectType> = []
        arguments.forEach { arg in
            allowedBarcodeTypes.append( QRCodeTypes[arg]!)
        }

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
                                if allowedBarcodeTypes.count == 0 || allowedBarcodeTypes.contains(code.type) {
                                    self?.channel.invokeMethod("onRecognizeQR", arguments: result)
                                }
                                
                            }
                        }
                    })
                } catch {
                    let error = FlutterError(code: "unknown-error", message: "Unable to start scanning", details: nil)
                    return result(error)
                }
            } else {
                return result(FlutterError(code: "cameraPermission", message: "Permission denied to access the camera", details: nil))
            }
        })
    
    }
    
    func stopScan(_ result: @escaping FlutterResult){
        MTBBarcodeScanner.requestCameraPermission(success: { permissionGranted in
            if permissionGranted {
                if let sc: MTBBarcodeScanner = self.scanner {
                    if sc.isScanning() {
                        sc.stopScanning()
                    }
                }
            } else {
                return result(FlutterError(code: "cameraPermission", message: "Permission denied to access the camera", details: nil))
            }
        })
    }
    
    func getCameraInfo(_ result: @escaping FlutterResult) -> Void {
        if let sc: MTBBarcodeScanner = scanner {
            result(sc.camera.rawValue)
        } else {
            let error = FlutterError(code: "cameraInformationError", message: "Could not get camera information", details: nil)
            result(error)
        }
    }
    
    func flipCamera(_ result: @escaping FlutterResult){
        MTBBarcodeScanner.requestCameraPermission(success: { permissionGranted in
            if permissionGranted {
                if let sc: MTBBarcodeScanner = self.scanner {
                    if sc.hasOppositeCamera() {
                        sc.flipCamera()
                    }
                    return result(sc.camera.rawValue)
                }
                return result(FlutterError(code: "404", message: "No barcode scanner found", details: nil))
            } else {
                return result(FlutterError(code: "cameraPermission", message: "Permission denied to access the camera", details: nil))
            }
        })
    }
    
    func getFlashInfo(_ result: @escaping FlutterResult) -> Void {
        if let sc: MTBBarcodeScanner = scanner {
            result(sc.torchMode.rawValue != 0)
        } else {
            let error = FlutterError(code: "cameraInformationError", message: "Could not get flash information", details: nil)
            result(error)
        }
    }
    
    func toggleFlash(_ result: @escaping FlutterResult){
        MTBBarcodeScanner.requestCameraPermission(success: { permissionGranted in
            if permissionGranted {
                if let sc: MTBBarcodeScanner = self.scanner {
                    if sc.hasTorch() {
                        sc.toggleTorch()
                        return result(sc.torchMode == MTBTorchMode(rawValue: 1))
                    }
                    return result(FlutterError(code: "404", message: "This device doesn\'t support flash", details: nil))
                }
                return result(FlutterError(code: "404", message: "No barcode scanner found", details: nil))
            } else {
                return result(FlutterError(code: "cameraPermission", message: "Permission denied to access the camera", details: nil))
            }
        })
    }
    
    func pauseCamera(_ result: @escaping FlutterResult) {
        MTBBarcodeScanner.requestCameraPermission(success: { permissionGranted in
            if permissionGranted {
                if let sc: MTBBarcodeScanner = self.scanner {
                    if sc.isScanning() {
                        sc.freezeCapture()
                    }
                    return result(true)
                }
                return result(FlutterError(code: "404", message: "No barcode scanner found", details: nil))
            } else {
                return result(FlutterError(code: "cameraPermission", message: "Permission denied to access the camera", details: nil))
            }
        })
    }
    
    func resumeCamera(_ result: @escaping FlutterResult) {
        MTBBarcodeScanner.requestCameraPermission(success: { permissionGranted in
            if permissionGranted {
                if let sc: MTBBarcodeScanner = self.scanner {
                    if !sc.isScanning() {
                        sc.unfreezeCapture()
                    }
                    return result(true)
                }
                return result(FlutterError(code: "404", message: "No barcode scanner found", details: nil))
            } else {
                return result(FlutterError(code: "cameraPermission", message: "Permission denied to access the camera", details: nil))
            }
        })
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

 }
