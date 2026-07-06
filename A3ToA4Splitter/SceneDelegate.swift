import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let mainViewController = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        
        // 处理冷启动时通过 Open In 传入的文件
        if !connectionOptions.urlContexts.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.handleOpenURLContexts(connectionOptions.urlContexts)
            }
        }
    }

    // MARK: - 处理从其他应用传入的文件（Open In / 分享到本应用）
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleOpenURLContexts(URLContexts)
    }
    
    private func handleOpenURLContexts(_ URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        print("[SceneDelegate] 收到传入文件: \(url.lastPathComponent), 路径: \(url.path)")
        
        // 处理安全范围 URL
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        
        // 检查文件是否可读
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            print("[SceneDelegate] 错误: 文件不可读")
            showAlert(title: "导入失败", message: "无法读取该文件")
            return
        }
        
        // 复制文件到应用目录
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        
        do {
            let savedURL = try LocalFileManager.shared.saveOriginalFile(from: url, fileName: fileName)
            print("[SceneDelegate] 文件已复制到: \(savedURL.path)")
            
            // 检测文件类型
            var docType: DocumentType = .image
            if fileExtension == "pdf" {
                docType = .pdf
            }
            
            // 导航到预览页面
            DispatchQueue.main.async { [weak self] in
                self?.navigateToPreview(fileURL: savedURL, documentType: docType)
            }
        } catch {
            print("[SceneDelegate] 导入失败: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "导入失败", message: error.localizedDescription)
            }
        }
    }
    
    private func navigateToPreview(fileURL: URL, documentType: DocumentType) {
        guard let navigationController = window?.rootViewController as? UINavigationController else {
            print("[SceneDelegate] 错误: 无法获取导航控制器")
            return
        }
        
        // 如果当前已有预览页面在栈中，先 pop 到根页面
        navigationController.popToRootViewController(animated: false)
        
        let previewVC = PreviewViewController(fileURL: fileURL, documentType: documentType)
        navigationController.pushViewController(previewVC, animated: true)
        print("[SceneDelegate] 已导航到预览页面")
    }
    
    private func showAlert(title: String, message: String) {
        guard let rootViewController = window?.rootViewController else { return }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        
        // 找到最顶层的 view controller 来 present alert
        var topViewController = rootViewController
        while let presented = topViewController.presentedViewController {
            topViewController = presented
        }
        topViewController.present(alert, animated: true)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
