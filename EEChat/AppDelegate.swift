//
//  AppDelegate.swift
//  EEChat
//
//  Created by Snow on 2021/5/18.
//

import UIKit
import RxSwift
import IQKeyboardManagerSwift
import OpenIM

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var window: UIWindow? = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white
        return window
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UIViewController.initHook()
        ApiModule.shared.delegate = MessageModule.shared
        configKeyboard()
        PushManager.shared.launchOptions(launchOptions)
        
        window?.makeKeyAndVisible()
        
        _ = Observable.merge(
            NotificationCenter.default.rx.notification(AccountManager.loginNotification),
            NotificationCenter.default.rx.notification(AccountManager.logoutNotification)
        )
        .map { (_) -> Bool in
            return AccountManager.shared.isLogin()
        }
        .startWith(AccountManager.shared.isLogin())
        .subscribe(onNext: { (isLogin) in
            let vc = isLogin ? MainTabBarController() : LoginVC.vc()
            self.window?.rootViewController = UINavigationController(rootViewController: vc)
        })
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        let badgeNumber = OpenIMManager.shared.badgeNumber
        PushManager.shared.setBadge(badgeNumber)
    }

}

extension AppDelegate {
    private func configKeyboard() {
        let keyboardManager = IQKeyboardManager.shared
        // 键盘配置
        keyboardManager.enable = true
        keyboardManager.shouldResignOnTouchOutside = true
        keyboardManager.keyboardDistanceFromTextField = 64

        // 自动工具条
        keyboardManager.enableAutoToolbar = false
        keyboardManager.toolbarManageBehaviour = .byPosition
        keyboardManager.shouldShowToolbarPlaceholder = true

        // 剔除某些界面不使用IQKeyboard
        let classes: [UIViewController.Type] = [MessagesVC.self, ChatVC.self]
        keyboardManager.disabledDistanceHandlingClasses.append(contentsOf: classes)
        keyboardManager.disabledToolbarClasses.append(contentsOf: classes)
        keyboardManager.disabledTouchResignedClasses.append(contentsOf: classes)
    }
}
