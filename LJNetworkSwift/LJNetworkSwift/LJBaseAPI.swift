//
//  LJBaseAPI.swift
//  LJNetwork-Swift
//
//  Created by ljcoder on 2017/5/15.
//  Copyright © 2017年 ljcoder. All rights reserved.
//

import UIKit
import Alamofire
#if !RX_NO_MODULE
    import RxSwift
    import RxCocoa
#endif
import SVProgressHUD

/****************************** Enum *************************************/
/// 网络请求方式
public enum LJHTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

/// 请求错误
public enum LJRequestError: Error {
    case failed(msg: String, code: String)
    case systemError(msg: String)
}

extension LJRequestError {
    
    public var msg: String {
        switch self {
        case .failed(let msg, _):
            return msg
        case .systemError(let msg):
            return msg
        }
    }
    
    public var code: String {
        switch self {
        case .failed(_ , let code):
            return code
        case .systemError(_):
            return "0"
        }
    }
}

/************************** 请求响应枚举 ***********************************/
// Data Key
let LJDataKey = "data"
let LJStatusKey = "status"
let LJCodekey = "code"
let LJMessagekey = "msg"

/// 请求响应
public enum LJResponse {
    case success(result: Any, msg: String, code: String)
    case failed(msg: String, code: String)
}

extension LJResponse {
    
    // 消息
    public var message: String {
        switch self {
        case .success( _, let msg, _):
            return msg
            
        case .failed(let msg, _):
            return msg
        }
    }
    
    // JSON数据
    public var data: Any {
        switch self {
        case .success(let data, _, _):
            return data
        default:
            return ""
        }
    }
    
    // code码
    public var code: String {
        switch self {
        case .success( _, _, let statusCode):
            return statusCode
            
        case .failed(_, let statusCode):
            return statusCode
        }
    }
    // 状态，成功和失败
    public var status: Bool {
        switch self {
        case .success:
            return true
        case .failed:
            return false
        }
    }
}

/******************************* LJRequest Protocol ************************************/
// 1.设置请求信息
// 2.处理请求回调
/******************************* LJRequest Protocol ************************************/
public protocol LJRequest {
    
    // 请求方式， 默认为 .post
    func method(_ api: LJBaseAPI) -> LJHTTPMethod
    // API路由
    func route(_ api: LJBaseAPI) -> String
    // 成功是否显示提示信息，默认为 true
    func showMessage(_ api: LJBaseAPI) -> Bool
    // 拦截器
    func shouldRequest(_ api: LJBaseAPI) -> Bool
    // 请求参数设置
    func requestParameters(_ api: LJBaseAPI) -> Dictionary<String, Any>?
    // 请求头添加
    func requestHeader(_ api: LJBaseAPI) -> HTTPHeaders
}

public extension LJRequest {
    
    func shouldRequest(_ api: LJBaseAPI) -> Bool {
        return true
    }
    
    func showMessage(_ api: LJBaseAPI) -> Bool {
        return true
    }
    
    func method(_ api: LJBaseAPI) -> LJHTTPMethod {
        return .post
    }
    
    func requestParameters(_ api: LJBaseAPI) -> Dictionary<String, Any>? {
        return nil
    }
    
    func requestHeader(_ api: LJBaseAPI) -> HTTPHeaders {
        return [:]
    }
}

/// 请求成功回调
public protocol LJRequestCallBack: LJRequest {
    // 失败回调
    func callFailed(_ api: LJBaseAPI, error: LJRequestError)
    // 成功回调
    func callSuccess(_ api: LJBaseAPI, result: LJResponse)
    // code 处理
    func callCodeHandler(_ api: LJBaseAPI, code: String)
}

public extension LJRequestCallBack {
    
    func callFailed(_ api: LJBaseAPI, error: LJRequestError) {
        
    }
    
    func callCodeHandler(_ api: LJBaseAPI, code: String) {
        
    }
    
}

/******************************* LJBaseAPI ************************************/
// MARK: LJBaseAPI Class Interface
public class LJBaseAPI {

    fileprivate var disposeBag = DisposeBag()
    
    fileprivate var requestList: [Int] = []
    
    public var requestDelegate: LJRequest?
    
    public var callBackDelegate: LJRequestCallBack?
    
    deinit {
        LJNetworkProxy.sharedInstance.cancelRequest(requestList)
        disposeBag = DisposeBag()
    }
}


// MARK: - 请求具体实现
extension LJBaseAPI {
    
    /// 发起网络请求
    ///
    /// - Parameters:
    ///   - parameters: 请求参数
    ///   - encodeing: 参数编码
    func request(parameters: [String: Any]?, encodeing: ParameterEncoding = URLEncoding.default) -> Void {
        
        guard
            let delegate = requestDelegate,
            let callBack = callBackDelegate
        else {
            print("LJNetworkError: 未设置代理")
            return
        }
        let method = delegate.method(self)
        let showMessage = delegate.showMessage(self)
        let route = delegate.route(self)
        let header = delegate.requestHeader(self)
        // 拦截器
        if !delegate.shouldRequest(self) { return }
        
        let HTTPMethod: HTTPMethod
        switch method {
            case .options:
                HTTPMethod = .options
            case .get:
                HTTPMethod = .get
            case .head:
                HTTPMethod = .head
            case .post:
                HTTPMethod = .post
            case .put:
                HTTPMethod = .put
            case .patch:
                HTTPMethod = .patch
            case .delete:
                HTTPMethod = .delete
            case .trace:
                HTTPMethod = .trace
            case .connect:
                HTTPMethod = .connect
        }
        
        let requestID = LJNetworkProxy.sharedInstance.call(LJServer.sharedInstance.domain().appending(route), method: HTTPMethod, parameters: parameters, encodeing: URLEncoding.default, headers: header) { (result) in
            
            let resultDic = result.value as? NSDictionary ?? NSDictionary()
            let status = resultDic[LJStatusKey] as? Bool ?? false
            let data = resultDic[LJDataKey]
            let msg = resultDic[LJMessagekey] as? String ?? ""
            let code = resultDic[LJCodekey] as? String ?? ""
            // code码处理
            callBack.callCodeHandler(self, code: code)
            // 请求回调处理
            switch result {
            case .success:
                if status == true {
                    // 显示提示
                    if showMessage && msg != ""  {
                        SVProgressHUD.showSuccess(withStatus: msg)
                    }
                    // 成功回调
                    callBack.callSuccess(self, result: LJResponse.success(result: data ?? "", msg: msg, code: code))
                }
                else {
                    // 显示提示
                    SVProgressHUD.showError(withStatus: msg)
                    // 失败回调
                    callBack.callFailed(self, error: LJRequestError.failed(msg: msg, code: code))
                }
        
            case .failure(let error):
                callBack.callFailed(self, error: LJRequestError.systemError(msg: error.localizedDescription))
            }
        }
        if !requestList.contains(requestID) {
            requestList.append(requestID)
        }
    }

    
    /// 网络请求信号
    ///
    /// - Parameters:
    ///   - parameters: 请求参数
    ///   - encodeing: 参数编码
    /// - Returns: Observable<LJResponse>信号
    func rx_request(parameters: [String: Any]?, encodeing: ParameterEncoding = URLEncoding.default) -> Observable<LJResponse> {
        
        guard
            let delegate = requestDelegate,
            let callBack = callBackDelegate
            else {
                print("LJNetworkError: 未设置代理")
                return Observable.empty()
        }
        // 拦截器
        if !delegate.shouldRequest(self) { return Observable.error(LJRequestError.failed(msg: "取消请求", code: "0"))}
        // 获取请求信息
        var requestParameters: Dictionary<String, Any>?
        if parameters == nil {
            requestParameters = delegate.requestParameters(self)
        }
        else {
            requestParameters = parameters
        }
        let method = delegate.method(self)
        let route = delegate.route(self)
        let showMessage = delegate.showMessage(self)
        let header = delegate.requestHeader(self)
        
        let HTTPMethod: HTTPMethod
        switch method {
        case .options:
            HTTPMethod = .options
        case .get:
            HTTPMethod = .get
        case .head:
            HTTPMethod = .head
        case .post:
            HTTPMethod = .post
        case .put:
            HTTPMethod = .put
        case .patch:
            HTTPMethod = .patch
        case .delete:
            HTTPMethod = .delete
        case .trace:
            HTTPMethod = .trace
        case .connect:
            HTTPMethod = .connect
        }
        
        let observer = Observable<LJResponse>.create { (observer) -> Disposable in
            let requestID = LJNetworkProxy.sharedInstance.call(LJServer.sharedInstance.domain().appending(route), method: HTTPMethod, parameters: requestParameters, encodeing: encodeing, headers: header) { (result) in
                
                let resultDic = result.value as? NSDictionary ?? NSDictionary()
                let status = resultDic[LJStatusKey] as? Bool ?? false
                let data = resultDic[LJDataKey]
                let msg = resultDic[LJMessagekey] as? String ?? ""
                let code = resultDic[LJCodekey] as? String ?? ""
                
                // code 处理
                callBack.callCodeHandler(self, code: code)
                // 回调处理
                switch result {
                    case .success:
                        if status == true {
                            // 显示提示信息
                            if showMessage && msg != "" {
                                SVProgressHUD.showSuccess(withStatus: msg)
                            }
                            // 代理回调
                            callBack.callSuccess(self, result: LJResponse.success(result: data ?? "", msg: msg, code: code))
                            // 发送信号
                            observer.on(.next(LJResponse.success(result: data ?? "", msg: msg, code: code)))
                            observer.on(.completed)
                        }
                        else {
                            // 显示提示信息
                            SVProgressHUD.showError(withStatus: msg)
                            // 代理回调
                            callBack.callFailed(self, error: LJRequestError.failed(msg: msg, code: code))
                            // 发送信号
                            observer.on(.error(LJRequestError.failed(msg: msg, code: code)))
                        }
                        break
                        
                    case .failure(let error):
       
                        callBack.callFailed(self, error: LJRequestError.systemError(msg: error.localizedDescription))
                        
                        observer.on(.error(LJRequestError.systemError(msg: error.localizedDescription)))
                        break
                }
            }
            if !self.requestList.contains(requestID) {
                self.requestList.append(requestID)
            }
            return Disposables.create()
        }
        
        return observer
        
    }
    
    /// 上传图片
    ///
    /// - Parameters:
    ///   - imageData: 图片数据
    ///   - parameters: 请求参数
    /// - Returns: Observable<LJResponse>信号
    func rx_updateImage(_ imageData: Data?, parameters: Parameters?, fileName: String = "file.jpg") -> Observable<LJResponse> {
        guard
            let delegate = requestDelegate,
            let callBack = callBackDelegate,
            let imgData = imageData
            else {
                return Observable.empty()
        }
        
        // 拦截器
        if !delegate.shouldRequest(self) { return Observable.error(LJRequestError.failed(msg: "取消请求", code: "0"))}
        
        let route = delegate.route(self)
        let showMessage = delegate.showMessage(self)
        
        let observable = Observable<LJResponse>.create { (observer) -> Disposable in
            
            Alamofire.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(imgData, withName: "upload",fileName: fileName, mimeType: "image/jpg")
                if let dic = parameters {
                    for (key, value) in dic {
                        multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
                    }
                }
                
            },
            to:"\(LJServer.sharedInstance.domain())\(route)")
            { (result) in
                switch result {
                    case .success(let upload, _, _):
                        
                        upload.uploadProgress(closure: { (progress) in
                            print("Upload Progress: \(progress.fractionCompleted)")
                        })
                        
                        upload.responseJSON { response in
                            let resultDic = response.value as? NSDictionary ?? NSDictionary()
                            let status = resultDic[LJStatusKey] as? Bool ?? false
                            let data = resultDic[LJDataKey] as? String ?? ""
                            let msg = resultDic[LJMessagekey] as? String ?? ""
                            let code = resultDic[LJCodekey] as? String ?? ""
                            // code 处理
                            callBack.callCodeHandler(self, code: code)
                            
                            switch response.result {
                                case .success:
                                    if status == true {
                                        
                                        if showMessage {
                                            SVProgressHUD.showSuccess(withStatus: msg)
                                        }
                                        
                                        callBack.callSuccess(self, result: LJResponse.success(result: data, msg: msg, code: code))
                                        
                                        observer.onNext(LJResponse.success(result: data, msg: msg, code: code))
                                        observer.onCompleted()
                                    }
                                    else {
                                        SVProgressHUD.showError(withStatus: msg)
                                        
                                        callBack.callFailed(self, error: LJRequestError.failed(msg: msg, code: code))
                                        
                                        observer.onError(LJRequestError.failed(msg: msg, code: code))
                                    }

                                case .failure(let error):
                                    callBack.callFailed(self, error: LJRequestError.systemError(msg: error.localizedDescription))
                                    
                                    observer.on(.error(LJRequestError.systemError(msg: error.localizedDescription)))
                            }
                        }

                    case .failure(let encodingError):
                        print(encodingError)  
                }
            }
            return Disposables.create()
        }
        
        return observable
    }
    
}
