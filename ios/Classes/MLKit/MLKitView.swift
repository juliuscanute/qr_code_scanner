import Foundation
import AVFoundation
import MLKitVision
import MLKitBarcodeScanning
import os.log

extension BarcodeScannerOptions {
    convenience init(formatStrings: [String]) {
        let formats = formatStrings.map { (format) -> BarcodeFormat? in
            switch format  {
            case "ALL_FORMATS":
                return .all
            case "AZTEC":
                return .aztec
            case "CODE_128":
                return .code128
            case "CODE_39":
                return .code39
            case "CODE_93":
                return .code93
            case "CODABAR":
                return .codaBar
            case "DATA_MATRIX":
                return .dataMatrix
            case "EAN_13":
                return .EAN13
            case "EAN_8":
                return .EAN8
            case "ITF":
                return .ITF
            case "PDF417":
                return .PDF417
            case "QR_CODE":
                return .qrCode
            case "UPC_A":
                return .UPCA
            case "UPC_E":
                return .UPCE
            default:
                return nil
            }
        }.reduce([]) { (result, format) -> BarcodeFormat in
            guard let format = format else {
                return result
            }
            return result.union(format)
        }
        
        self.init(formats: formats)
    }
}

class OrientationHandler {
    
    var lastKnownOrientation: UIDeviceOrientation!
    
    init() {
        setLastOrientation(UIDevice.current.orientation, defaultOrientation: .portrait)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIDeviceOrientationDidChange, object: nil, queue: nil, using: orientationDidChange(_:))
    }
    
    func setLastOrientation(_ deviceOrientation: UIDeviceOrientation, defaultOrientation: UIDeviceOrientation?) {
        
        // set last device orientation but only if it is recognized
        switch deviceOrientation {
        case .unknown, .faceUp, .faceDown:
            lastKnownOrientation = defaultOrientation ?? lastKnownOrientation
            break
        default:
            lastKnownOrientation = deviceOrientation
        }
    }
    
    func orientationDidChange(_ notification: Notification) {
        let deviceOrientation = UIDevice.current.orientation
        
        setLastOrientation(deviceOrientation, defaultOrientation: nil)
    }
    
    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

enum MLKitReaderError: Error {
    case noCamera
}

class MLKitReader: NSObject {
    let targetWidth: Int
    let targetHeight: Int
    let textureRegistry: FlutterTextureRegistry
    let isProcessing = Atomic<Bool>(false)
    
    var captureDevice: AVCaptureDevice!
    var captureSession: AVCaptureSession!
    var previewSize: CMVideoDimensions!
    var textureId: Int64!
    var pixelBuffer : CVPixelBuffer?
    let barcodeDetector: BarcodeScanner
    let cameraPosition = AVCaptureDevice.Position.back
    let qrCallback: (_:[String:Any]) -> Void
    
    init(targetWidth: Int, targetHeight: Int, textureRegistry: FlutterTextureRegistry, options: BarcodeScannerOptions, qrCallback: @escaping (_:[String:Any]) -> Void) throws {
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
        self.textureRegistry = textureRegistry
        self.qrCallback = qrCallback
        
        self.barcodeDetector = BarcodeScanner.barcodeScanner()
        
        super.init()
        
        captureSession = AVCaptureSession()
        
        if #available(iOS 10.0, *) {
            captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: cameraPosition)
        } else {
            for device in AVCaptureDevice.devices(for: AVMediaType.video) {
                if device.position == cameraPosition {
                    captureDevice = device
                    break
                }
            }
        }
        
        if captureDevice == nil {
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
            
            guard captureDevice != nil else {
                throw MLKitReaderError.noCamera
            }
        }
        
        let input = try AVCaptureDeviceInput.init(device: captureDevice)
        previewSize = CMVideoFormatDescriptionGetDimensions(captureDevice.activeFormat.formatDescription)
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        
        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
        output.setSampleBufferDelegate(self, queue: queue)
        
        captureSession.addInput(input)
        captureSession.addOutput(output)
    }
    
    func start() {
        captureSession.startRunning()
        self.textureId = textureRegistry.register(self)
    }
    
    func stop() {
        captureSession.stopRunning()
        pixelBuffer = nil
        textureRegistry.unregisterTexture(textureId)
        textureId = nil
    }
}

extension MLKitReader : FlutterTexture {
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if(pixelBuffer == nil){
            return nil
        }
        return  .passRetained(pixelBuffer!)
    }
}

extension MLKitReader: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        textureRegistry.textureFrameAvailable(self.textureId)
        
        guard !isProcessing.swap(true) else {
            return
        }
        
        let image = VisionImage(buffer: sampleBuffer)
        image.orientation = imageOrientation(
            deviceOrientation: UIDevice.current.orientation,
            defaultOrientation: .portrait
        )
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            self.barcodeDetector.process(image) { features, error in
                self.isProcessing.value = false
                
                guard error == nil else {
                    if #available(iOS 10.0, *) {
                        os_log("Error decoding barcode %@", error!.localizedDescription)
                    } else {
                        // Fallback on earlier versions
                        NSLog("Error decoding barcode %@", error!.localizedDescription)
                    }
                    return
                }
                
                guard let barcodes = features, !barcodes.isEmpty else {
                  return
                }
                
                for barcode in barcodes {
                    
                    // Barcode info
                    let valueType  = barcode.valueType
                
                    let format = barcode.format.rawValue

                    // Barcode values
                    let displayValue = barcode.displayValue ?? ""
                    let rawValue = barcode.rawValue ?? ""
                    
                    // TODO: Other barcode types
//                    let rawData : String = String(barcode.rawData.)
//
//                     Position
//                    let cornerPoints : String = String(barcode.cornerPoints)
//                    let frame : String = String(barcode.frame)
//
//                    // Type specific values
//                    switch valueType {
//                    case .contactInfo:
//                    case .email:
//                    case .ISBN:
//                    case .phone:
//                    case .product:
//                    case .SMS:
//                        let message = barcode.sms!.message
//                        let phoneNumber = barcode.sms!.phoneNumber
//                    case .text:
//                    case .URL:
//                        let title = barcode.url!.title
//                        let url = barcode.url!.url
//                    case .wiFi:
//                        let ssid = barcode.wifi?.ssid
//                        let password = barcode.wifi?.password
//                        let encryptionType = barcode.wifi?.type
//                    case .geographicCoordinates:
//                    case .calendarEvent:
//                    case .driversLicense:
//                    case .unknown:
//                    default:
//                        break
//                    }
                    let result = ["valueType": valueType, "format": format, "displayValue": displayValue, "rawValue": rawValue] as [String : Any]
                    self.qrCallback(result)
                    
                }
            }
        }
    }
    
    
    func imageOrientation(
        deviceOrientation: UIDeviceOrientation,
        defaultOrientation: UIDeviceOrientation
    ) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return cameraPosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return cameraPosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return cameraPosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return cameraPosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        @unknown default:
            return imageOrientation(deviceOrientation: defaultOrientation, defaultOrientation: .portrait)
        }
    }
    
}
