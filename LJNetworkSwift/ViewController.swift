//
//  ViewController.swift
//  LJNetworkSwift
//
//  Created by ljcoder on 2017/8/7.
//  Copyright © 2017年 ljcoder. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    fileprivate lazy var test: LJBaseAPI = {
        let api = LJBaseAPI(delegate: self)
//        api.requestDelegate = self
//        api.callBackDelegate = self
        return api
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        test.request(parameters: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: LJRequest, LJRequestCallBack {
    
    func route(_ api: LJBaseAPI) -> String {
        return "/api/banner"
    }
    
    func callSuccess(_ api: LJBaseAPI, result: LJResponse) {
        
    }
    
    
}
