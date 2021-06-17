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
        let params = args as! Dictionary<String, Double>
        return QRView(withFrame: frame, withRegistrar: registrar!,withId: viewId, params: params)
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec(readerWriter: FlutterStandardReaderWriter())
    }
}
