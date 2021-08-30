#import "FlutterQrPlugin.h"

#if __has_include(<qr_code_scanner/qr_code_scanner-Swift.h>)
#import <qr_code_scanner/qr_code_scanner-Swift.h>
#else
#import "qr_code_scanner-Swift.h"
#endif

@implementation FlutterQrPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftFlutterQrPlugin registerWithRegistrar:registrar];
}
@end
