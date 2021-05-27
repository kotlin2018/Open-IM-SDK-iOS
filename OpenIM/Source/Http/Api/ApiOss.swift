//
//  ApiOss.swift
//  OpenIM
//
//  Created by Snow on 2021/5/14.
//

import Foundation
import RxSwift

internal struct ApiQCloudInfo: ApiType {
    let apiTarget: ApiTarget = ApiInfo(path: "credential/tencent_upload")
    let param = OnlyOperationID()
    
    public init() {}
    
    struct Credentials: Codable {
        var tmpSecretId = ""
        var tmpSecretKey = ""
        var token = ""
    }
    
    struct Model: Codable {
        var credentials = Credentials()
        var expiredTime = TimeInterval.zero
        var startTime = TimeInterval.zero
    }
    
    static func request() -> Single<ApiQCloudInfo.Model> {
        return ApiQCloudInfo().request()
            .map(type: Model.self, keyDecodingStrategy: .convert(type: LowercasedFirstLetterCodingKey.self))
    }
}
