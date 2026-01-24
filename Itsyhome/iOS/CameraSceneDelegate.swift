//
//  CameraSceneDelegate.swift
//  Itsyhome
//
//  UIWindowSceneDelegate for the camera panel
//

import UIKit

class CameraSceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        #if targetEnvironment(macCatalyst)
        windowScene.sizeRestrictions?.minimumSize = CGSize(width: 200, height: 150)
        windowScene.sizeRestrictions?.maximumSize = CGSize(width: 800, height: 800)
        windowScene.title = "Cameras"

        if let titlebar = windowScene.titlebar {
            titlebar.titleVisibility = .hidden
            titlebar.toolbar = nil
        }
        #endif

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = CameraViewController()
        window.isHidden = false
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if let cameraVC = window?.rootViewController as? CameraViewController {
            cameraVC.stopAllStreams()
        }
    }
}
