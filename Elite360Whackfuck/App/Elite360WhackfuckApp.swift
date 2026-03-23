import SwiftUI
import FirebaseCore

@main
struct Elite360WhackfuckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var premiumManager = PremiumManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
                .environmentObject(premiumManager)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Only configure Firebase if GoogleService-Info.plist exists in the bundle
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        } else {
            print("⚠️ GoogleService-Info.plist not found — Firebase is not configured. Add it to the project to enable backend services.")
        }
        PremiumManager.shared.configure()
        return true
    }
}
