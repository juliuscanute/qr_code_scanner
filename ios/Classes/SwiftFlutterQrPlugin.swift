import Flutter
import UIKit

public class SwiftFlutterQrPlugin: NSObject, FlutterPlugin {

    var factory: QRViewFactory
    
    public init(with registrar: FlutterPluginRegistrar) {
        self.factory = QRViewFactory(withRegistrar: registrar)
    
        registrar.register(factory, withId: "net.touchcapture.qr.flutterqr/qrview")
    }
    
      public static func register(with registrar: FlutterPluginRegistrar) {
          // MLKit initalization
          let channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/mlkit", binaryMessenger: registrar.messenger());
          let instance = MLKitViewHandler(channel: channel, textureRegistry: registrar.textures());

          registrar.addMethodCallDelegate(instance, channel: channel)
          registrar.addApplicationDelegate(SwiftFlutterQrPlugin(with: registrar))
      }
      
      public func applicationDidEnterBackground(_ application: UIApplication) {
          
      }

      public func applicationWillTerminate(_ application: UIApplication) {
          
      }
}
