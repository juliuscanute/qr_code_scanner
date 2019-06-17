import Flutter
import UIKit

public class SwiftFlutterQrPlugin: NSObject, FlutterPlugin {

  var factory: QRViewFactory
  public init(with registrar: FlutterPluginRegistrar) {
    self.factory = QRViewFactory(withRegistrar: registrar)
    registrar.register(factory, withId: "net.touchcapture.qr.flutterqr/qrview")
  }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.addApplicationDelegate(SwiftFlutterQrPlugin(with: registrar))
  }
  
  public func applicationDidEnterBackground(_ application: UIApplication) {
  }

  public func applicationWillTerminate(_ application: UIApplication) {
  }

}
