//
//  MainTabBarController.swift
//  EEChat
//
//  Created by Snow on 2021/5/18.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fd_prefersNavigationBarHidden = true
        
        viewControllers = [SessionListVC.vc(), AddressBookVC.vc(), UserCenterVC.vc()]
        
        let titles = [
            LocalizedString("Chats"),
            LocalizedString("Contacts"),
            LocalizedString("Me"),
        ]
        for i in 0 ..< tabBar.items!.count {
            let item = tabBar.items![i]
            item.title = titles[i]
            item.image = UIImage(named: "tabbar_icon_\(i)_0")!.withRenderingMode(.alwaysOriginal)
            item.selectedImage = UIImage(named: "tabbar_icon_\(i)_1")!.withRenderingMode(.alwaysOriginal)
        }
    }
    
}
