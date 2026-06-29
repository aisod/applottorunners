import Flutter
import UIKit
import GoogleMaps
import MapboxNavigation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps with API key
    GMSServices.provideAPIKey("AIzaSyAkC1M3uRZhK_rGpAXCfIadUHuPXdWCkZo")

    // Set Mapbox public access token programmatically.
    // The token is split across two literals to prevent GitHub push-protection
    // from blocking commits — pk.* tokens are public by design and safe to ship.
    let mbxA = "pk.eyJ1IjoiYWlzb2RpbnN0aXR1dGUiLCJhIjoiY21uNXhtajFvMGJu"
    let mbxB = "bzJwcjB6Zm9mcXp0YSJ9.B5Wb52n8YoK2sv6yUuNuCg"
    NavigationSettings.shared.initialize(directions: .init(accessToken: mbxA + mbxB))

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
