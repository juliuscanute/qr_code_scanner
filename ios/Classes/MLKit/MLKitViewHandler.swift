import Foundation
import Flutter
import UIKit
import MLKitVision
import MLKitBarcodeScanning


public class MLKitViewHandler: NSObject, FlutterPlugin {
  
  let textureRegistry: FlutterTextureRegistry
  let channel: FlutterMethodChannel
  
  init(channel: FlutterMethodChannel, textureRegistry: FlutterTextureRegistry) {
    self.textureRegistry = textureRegistry
    self.channel = channel
  }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        // MLKit initalization
        let channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/mlkit", binaryMessenger: registrar.messenger());
        let instance = MLKitViewHandler(channel: channel, textureRegistry: registrar.textures());

        registrar.addMethodCallDelegate(instance, channel: channel)
    }
  
  var reader: MLKitReader? = nil
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let argReader = MapArgumentReader(call.arguments as? [String: Any])
    
    switch call.method{
    case "startMLKit":
      if reader != nil {
        result(FlutterError(code: "ALREADY_RUNNING", message: "Start cannot be called when already running", details: ""))
        return
      }
      
      guard let targetWidth = argReader.int(key: "targetWidth"),
            let targetHeight = argReader.int(key: "targetHeight"),
            let formatStrings = argReader.stringArray(key: "formats") else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing a required argument", details: "Expecting targetWidth, targetHeight, formats, and optionally heartbeatTimeout"))
          return
      }

      let options = BarcodeScannerOptions(formatStrings: formatStrings)
            
      do {
        reader = try MLKitReader(
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          textureRegistry: textureRegistry,
          options: options) { [unowned self] qr in
            self.channel.invokeMethod("qrRead", arguments: qr)
        }
        
        reader!.start();
        
        result([
          "surfaceWidth": reader!.previewSize.height,
          "surfaceHeight": reader!.previewSize.width,
          "surfaceOrientation": 0,
          "textureId": reader!.textureId!
        ])
      } catch MLKitReaderError.noCamera {
        result(FlutterError(code: "CAMERA_ERROR", message: "QrReader couldn't open camera", details: nil))
      } catch {
        result(FlutterError(code: "PERMISSION_DENIED", message: "QrReader initialization threw an exception", details: error.localizedDescription))
      }
    case "stopMLKit":
      reader?.stop();
      reader = nil
      result(nil)
    default : result(FlutterMethodNotImplemented);
    }
  }
}

class MapArgumentReader {
  
  let args: [String: Any]?
  
  init(_ args: [String: Any]?) {
    self.args = args
  }
  
  func string(key: String) -> String? {
    return args?[key] as? String
  }
  
  func int(key: String) -> Int? {
    return (args?[key] as? NSNumber)?.intValue
  }

  func stringArray(key: String) -> [String]? {
    return args?[key] as? [String]
  }
  
}
