//
//  EECPopupVC.swift
//  EEChat
//
//  Created by Snow on 2021/4/20.
//

import UIKit

class EECPopupVC: UIViewController {
    
    class func show(configCallback: @escaping (_ popupVC: EECPopupVC) -> Void) {
        let vc = Self()
        vc.modalPresentationStyle = .overCurrentContext
        
        NavigationModule.shared.present(vc: vc) {
            configCallback(vc)
        }
    }
    
    var dismissOnTouchOutside = true

    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(dismissAction), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    @objc func dismissAction() {
        if dismissOnTouchOutside {
            NavigationModule.shared.dismiss(self)
        }
    }

}
