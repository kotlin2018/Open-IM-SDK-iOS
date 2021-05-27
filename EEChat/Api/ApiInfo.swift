//
//  ApiInfo.swift
//  EEChat
//
//  Created by snow on 2021/3/27.
//

import Foundation
import Alamofire
import OpenIM

public struct ApiInfo: ApiTarget {
    
    public init(path: String) {
        self.path = path
    }
    
    public let baseURL: URL = URL(string: "http://47.112.160.66:20000")!
    
    public let path: String
    
    public let method: HTTPMethod = .post
    
    public var headers: [String : String]?

    public var encoder: ParameterEncoder = JSONParameterEncoder.default
    
    public var processor: ApiProcessor {
        return ApiInfoProcessor.default
    }
}
