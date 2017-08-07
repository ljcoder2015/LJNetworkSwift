//
//  LJNetworkProxy.swift
//  LJNetwork-Swift
//
//  Created by ljcoder on 2017/5/16.
//  Copyright © 2017年 ljcoder. All rights reserved.
//

import UIKit
import Alamofire

class LJNetworkProxy {

    static let sharedInstance = LJNetworkProxy()
    // 网络请求列表
    fileprivate var requestList : [Int: URLSessionTask] = [:]
    // MARK: 底层网络请求
    public func call(_ route: String, method: HTTPMethod, parameters: Parameters?, encodeing: ParameterEncoding, headers: HTTPHeaders?, result: @escaping (Result<Any>) -> Void) -> Int {
        
        let cookiesCache = UserDefaults.standard.object(forKey: "cookieStorage") as? Array<[String: String]>
        if cookiesCache != nil {
            for cookie in cookiesCache! {
                var cookieProperties = [HTTPCookiePropertyKey: AnyObject]()
                cookieProperties[HTTPCookiePropertyKey.name] = cookie["name"] as AnyObject
                cookieProperties[HTTPCookiePropertyKey.value] = cookie["value"] as AnyObject
                cookieProperties[HTTPCookiePropertyKey.domain] = cookie["domain"] as AnyObject
                cookieProperties[HTTPCookiePropertyKey.path] = cookie["path"] as AnyObject
                cookieProperties[HTTPCookiePropertyKey.version] = cookie["version"] as AnyObject
                cookieProperties[HTTPCookiePropertyKey.expires] = NSDate().addingTimeInterval(31536000)

                let newCookie = HTTPCookie(properties: cookieProperties)
                HTTPCookieStorage.shared.setCookie(newCookie!)
//                print("cookie: \(cookie)")
            }
        }
        
        let request = Alamofire.request(route, method: method, parameters: parameters, encoding: encodeing, headers: headers).responseJSON(completionHandler: { (response) in
            
            let httpBody = NSString(data: response.request?.httpBody ?? Data(), encoding: String.Encoding.utf8.rawValue)
            print("=================== LJNetworkRequest Start ===================")
            print("Request URL: \(String(describing: response.request?.url?.absoluteString ?? ""))")
            print("Request Method: \(String(describing: response.request?.httpMethod ?? ""))")
            print("Response StatusCode: \(String(describing: response.response?.statusCode ?? 0))")
            print("Request Header:\n  \(String(describing: response.request?.allHTTPHeaderFields ?? ["NoHeader": "NoValue"]))")
            print("Request Body:\n  \(String(describing: httpBody ?? ""))")
            print("Response Data:\n  \(response.result.value ?? "result empty")")
            print("=================== LJNetworkRequest End =====================")
            
            result(response.result)
            
            let cookieStorage = HTTPCookieStorage.shared.cookies
            guard let cookies = cookieStorage
            else { return }
            var array = Array<[String: String]>()
            for cookie in cookies {
                var dic = Dictionary<String, String>()
                dic["name"] = cookie.name
                dic["value"] = cookie.value
                dic["domain"] = cookie.domain
                dic["path"] = cookie.path
                dic["version"] = "\(cookie.version)"
                array.append(dic)
//                print("...cookie: \(cookie)")
            }
            UserDefaults.standard.set(array, forKey: "cookieStorage")

        })
        let taskIdentifier = request.task?.taskIdentifier ?? 0
        requestList[taskIdentifier] = request.task
        return taskIdentifier
    }
    // MARK: 上传图片方法
    public func uploadImage(_ route: String, imageData: Data, parameters: Parameters?, result: @escaping (Result<Any>) -> Void) -> Void {

        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imageData, withName: "fileset",fileName: "file.jpg", mimeType: "image/jpg")
            if let dic = parameters {
                for (key, value) in dic {
                    multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
                }
            }
            
        },
        to:route)
        { (result) in
            
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    print(response.result.value ?? "")  
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
        }
    }
    
    // MARK:取消网络请求方法
    public func cancelRequest(_ requestTable: [Int]) {
        for requestID in requestTable {
            guard let task: URLSessionTask = requestList[requestID]  else {
                return
            }
            task.cancel()
        }
        
    }
}
