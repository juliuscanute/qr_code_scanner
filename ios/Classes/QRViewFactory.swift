//
//  QRViewFactory.swift
//  flutter_qr
//
//  Created by Julius Canute on 21/12/18.
//

import Foundation

public class QRViewFactory: NSObject, FlutterPlatformViewFactory {
    
    var registrar: FlutterPluginRegistrar?
    
    public init(withRegistrar registrar: FlutterPluginRegistrar){
        super.init()
        self.registrar = registrar
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let dictionary =  args as! Dictionary<String, Double>
        return QRView(withFrame: CGRect(x: 0, y: 0, width: dictionary["width"] ?? 0, height: dictionary["height"] ?? 0), withRegistrar: registrar!,withId: viewId)
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec(readerWriter: FlutterStandardReaderWriter())
    }
}
