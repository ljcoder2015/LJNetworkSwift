//
//  LJServer.swift
//  LJNetworkSwift
//
//  Created by ljcoder on 2017/8/4.
//  Copyright © 2017年 ljcoder. All rights reserved.
//

import Foundation

class LJServer {
    
    static let sharedInstance = LJServer()
    
    open var developServerDomain: String {
        return ""
    }
    
    open var developImageServerDomain: String {
        return ""
    }
    
    open var distributionServerDomain: String  {
        return ""
    }
    
    open var distributionImageServerDomain: String {
        return ""
    }
    
    open func domain() -> String {
        return developServerDomain
    }
    
    open func imageDomain() -> String {
        return developServerDomain
    }
    
}
