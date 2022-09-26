//
//  SceneDelegate.swift
//  NotifyCharacteristicsBLEChange
//
//  Created by Mihail Matyatsko on 22.09.2022.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        guard let window = window else { return }
        let rootVC = MainBLEController.make()
        window.rootViewController = rootVC
        window.makeKeyAndVisible()
    }

}
