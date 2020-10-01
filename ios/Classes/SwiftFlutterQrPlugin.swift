import Flutter
import UIKit
import MTBBarcodeScanner

public class SwiftFlutterQrPlugin: NSObject, FlutterPlugin{
  var channel: FlutterMethodChannel
  var factory: QRViewFactory

  public init(with registrar: FlutterPluginRegistrar) {
    self.factory = QRViewFactory(withRegistrar: registrar)
    registrar.register(factory, withId: "net.touchcapture.qr.flutterqr/qrview")
    channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/qrview", binaryMessenger: registrar.messenger())
    super.init()
    channel.setMethodCallHandler(self.onMethodCalled)
  }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.addApplicationDelegate(SwiftFlutterQrPlugin(with: registrar))
  }
    
    func isCameraAvailable(_ success: Bool, _ result: FlutterResult) -> Void {
        if success {
            result(true)
        } else {
            result(false)
        }
    }
    
  public func onMethodCalled(_ call: FlutterMethodCall, result: @escaping FlutterResult){
      switch call.method {
        case "requestPermissions":
            MTBBarcodeScanner.requestCameraPermission(success: {(success:Bool) in self.isCameraAvailable(success, result)})
        default:
            result(FlutterMethodNotImplemented)
        }
  }
  
  public func applicationDidEnterBackground(_ application: UIApplication) {
  }

  public func applicationWillTerminate(_ application: UIApplication) {
  }

}
