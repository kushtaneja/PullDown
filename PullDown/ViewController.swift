//
//  ViewController.swift
//  PullDown
//
//  Created by Kush Taneja on 15/06/17.
//  Copyright © 2017 Kush Taneja. All rights reserved.
//

import UIKit

fileprivate var minimumHeight: CGFloat = 66.0
fileprivate var alpha: CGFloat = 0.52
fileprivate var cornerRadius: CGFloat = 10.0
fileprivate var bottomSpacing: CGFloat = 100.0


class ViewController: UIViewController {

    var height: CGFloat!
    var pullDownViewController: PullDownViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.height = self.view.frame.height - bottomSpacing
        
        self.pullDownViewController = PullDownViewController(nibName: "PullDownViewController", bundle: Bundle.main, height: height, minimumHeight: minimumHeight, dimmingAlpha: alpha, cornerRadius: cornerRadius)
        self.pullDownViewController.view.frame = CGRect(x: 0, y: -height + minimumHeight, width: self.view.frame.width, height: height)
        self.pullDownViewController.view.layer.cornerRadius = cornerRadius
        self.view.backgroundColor = UIColor.black
        self.addChildViewController(pullDownViewController)
        self.pullDownViewController.modalPresentationStyle = .currentContext
        self.view.addSubview(self.pullDownViewController.view)
        self.pullDownViewController.didMove(toParentViewController: self)

        self.pullDownViewController.setup()
    }

}
