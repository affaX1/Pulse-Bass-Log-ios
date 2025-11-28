import AdServices
import AppTrackingTransparency
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let attChannel = FlutterMethodChannel(
        name: "app_logic/att_token",
        binaryMessenger: controller.binaryMessenger
      )

      attChannel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "getAttributionToken" else {
          result(FlutterMethodNotImplemented)
          return
        }
        self?.handleAttributionToken(result: result)
      }
    }

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  private func handleAttributionToken(result: @escaping FlutterResult) {
    guard #available(iOS 14.3, *) else {
      result("")
      return
    }

    do {
      let token = try AAAttribution.attributionToken()
      result(token)
    } catch {
      result(
        FlutterError(
          code: "att-token-error",
          message: "Failed to fetch attribution token",
          details: error.localizedDescription
        )
      )
    }
  }
}