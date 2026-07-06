import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupAppearance()
        return true
    }

    // MARK: - 处理从其他应用传入的文件（后备方案，iOS 13+ 主要由 SceneDelegate 处理）
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("[AppDelegate] 收到传入文件: \(url.lastPathComponent)")
        // 通知 SceneDelegate 处理（如果场景已激活）
        NotificationCenter.default.post(name: .init("OpenInFileReceived"), object: url)
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    private func setupAppearance() {
        UINavigationBar.appearance().tintColor = .systemBlue
        UINavigationBar.appearance().barTintColor = .systemBackground
        UINavigationBar.appearance().isTranslucent = true
        
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
