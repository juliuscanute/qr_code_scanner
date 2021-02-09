## 0.3.3
#### Bug fixes
* Fixed updateDimensions not being called causing zoom on iOS. (#250)
* Fixed Android permission callback not working. (#251) (#252)
* Fixed null-pointers after declining permission on Android.

## 0.3.2
#### Bug fixes
* Fixed null-pointer when no overlay provided on iOS. (#245)
* Fixed camera not stopping (green dot on iOS 14) when navigating to other page. (#240)

## 0.3.1
#### Bug fixes
* Fixed permission callback on iOS & Android.
* Fixed camera facing not working on Android.
* Fixed scanArea not being honored on Android.
* Updated ShapeBorder to QrScannerOverlayShape.

## 0.3.0
#### Breaking change
Its not necessary anymore to wrap the QRView in a SizeChangedLayoutNotifier because this is handled inside the plugin.
#### New Features
* Added possibility to set allowed barcodes. (#135)
* Added possibility to check what features are supported by device. (hasFlash, hasBackCamera, hasFrontCamera) (#135)
* Added possibility to check if flash is on. (#135)
* Added possibility to check which camera is active. (#135)
* All functions are now async so you can await them. (#135)

See the updated example on how to implement these features.
#### Bug fixes
* Fixed permission handling in Android.
* Native functions now returns results so exceptions can be thrown when an error occurs.

## 0.2.1
* Fixed critical bug where scanner wouldn't open when no scan overlay was configured.

## 0.2.0
#### Breaking change
* The plugin now returns Barcode object instead of QR String. This object includes the type of code, the code itself and on Android devices the raw bytes. (#63)
#### New Features
* Added possibility to provide scanArea on iOS. (#165)
#### Bug fixes
* Fixed preview going black after hot reload. (#76)
* Fixed nullpointer when plugin binding order isn't correct. (#181)
* Fixed permission being asked on startup (#185)

## 0.1.0
* Changed Android minSDKversion from 24 to 21 (#170)
* Fix preview size after iPad rotation (#125)
* Implemented Android Embedding V2 (#132)
* Added cutout bottom offset (#115)
* Fix Android ActivityLifecycleCallbacks (#166)
* Fix some other small bugs

## 0.0.14
* Fix disposing camera on iOS 14 (#113)

## 0.0.13
* Fix misalignment when QRView doesn't start from the top left (#45)
* Fix crash on iOS when scanning returns nil (#69, #72)
* Fix ArithmeticException on Android (#43)

## 0.0.12
* Add optional parameter to use a camera overlay.
* Simplify controller, expose scanDataStream.
* Fix for Android flash toggle.
* Add ability to pause/resume the camera.
* Thanks! to Luis Thein for all the above contributions.

## 0.0.11
* android build break fix

## 0.0.10
* update README.md

## 0.0.9
* update README.md

## 0.0.8
* migrated Android project to androidx (by Felipe César)
* migrated iOS to Swift 5 (by Felipe César)

## 0.0.7
* flash light support added

## 0.0.6
* camera flip added

## 0.0.5
* preview stretching after change screen orientation fix

## 0.0.4
* fix black screen orientation/unlock/focus

## 0.0.3
* iOS library reference fix
* Android pause/resume fix

## 0.0.2
* Added documentation to cover how to use the plugin.

## 0.0.1
* QR Code scanner embedded inside flutter.
