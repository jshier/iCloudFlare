//
//  NetworkController.swift
//  HazeLight
//
//  Created by Jon Shier on 9/20/18.
//  Copyright © 2018 Jon Shier. All rights reserved.
//

import Alamofire
import Foundation

final class NetworkController {
    static let shared = NetworkController()
    
    let session: Session
    
    init(session: Session = .hazeLight) {
        self.session = session
    }
    
    typealias Completion<Request: Requestable> = (_ response: DataResponse<BaseResponse<Request.Response>>) -> Void
    
    func validate(email: String, token: String, completion: @escaping Completion<User.Validate>) {
        perform(User.Validate(email: email, token: token), completion: completion)
    }
    
    func fetchUser(_ completion: @escaping Completion<User.Request>) {
        perform(User.Request(), completion: completion)
    }
    
    func editUser(_ userEdit: User.Edit, completion: @escaping Completion<User.Edit>) {
        perform(userEdit, completion: completion)
    }

    func perform<Request: Requestable>(_ request: Request, completion: @escaping Completion<Request>) {
        session.request(request).responseValue(handler: completion)
    }
}

extension Session {
    static let hazeLight: Session = {
        let session = Session(adapter: UserCredentialAdapter(), eventMonitors: [LoggingMonitor()])
        
        return session
    }()
}

final class UserCredentialAdapter: RequestAdapter {
    private var token: NotificationToken?
    private var currentCredential: CredentialsModelController.UserCredential?
    
    init(credentials: CredentialsModelController = .shared) {
        token = credentials.currentCredential.observe { self.currentCredential = $0 }
    }
    
    func adapt(_ urlRequest: URLRequest, completion: @escaping (Result<URLRequest>) -> Void) {
        completion(Result {
            guard urlRequest.httpHeaders["X-Auth-Email"] == nil, urlRequest.httpHeaders["X-Auth-Key"] == nil else {
                return urlRequest
            }
            
            var urlRequest = urlRequest
            
            let credential = try currentCredential.unwrapped()
            urlRequest.httpHeaders.add(.xAuthEmail(credential.email))
            urlRequest.httpHeaders.add(.xAuthKey(credential.token))
            
            return urlRequest
        })
    }
}

extension HTTPHeader {
    static func xAuthEmail(_ email: String) -> HTTPHeader {
        return HTTPHeader(name: "X-Auth-Email", value: email)
    }
    
    static func xAuthKey(_ key: String) -> HTTPHeader {
        return HTTPHeader(name: "X-Auth-Key", value: key)
    }
}

final class LoggingMonitor: EventMonitor {
    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value>) {
        debugPrint(response)
        let body = request.data.map { String(decoding: $0, as: UTF8.self) } ?? "No body."
        print("[Body]: \(body)")
    }
}

//protocol NetworkObservable {
//    static var loading
//    static var response
//    static var result
//    static var value
//}
// observable.map({ }, into: otherObservable)
// otherObservable.ingest(from: observable, using: { (currentValue) })
