#if os(iOS)

import Foundation
import Flutter

@objc(StackFfiPluginIos)
public class StackFfiPluginIos: NSObject, FlutterPlugin {
  @objc public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = StackFfiPluginIos()
  }
}

#endif