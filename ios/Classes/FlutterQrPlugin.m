#import "FlutterQrPlugin.h"
#import <flutter_qr/flutter_qr-Swift.h>
@implementation FlutterQrPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftFlutterQrPlugin registerWithRegistrar:registrar];
}
@end
