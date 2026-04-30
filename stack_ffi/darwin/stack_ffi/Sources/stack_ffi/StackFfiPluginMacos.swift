#if os(macOS)

import Foundation
import FlutterMacOS

@objc(StackFfiPluginMacos)
public class StackFfiPluginMacos: NSObject, FlutterPlugin {
  @objc public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = StackFfiPluginMacos()
  }
}

#endif