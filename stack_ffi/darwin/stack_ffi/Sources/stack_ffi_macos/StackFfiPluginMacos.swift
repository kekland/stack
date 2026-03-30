import Foundation
import FlutterMacOS

public class StackFfiPluginMacos: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = StackFfiPluginMacos()
  }
}
