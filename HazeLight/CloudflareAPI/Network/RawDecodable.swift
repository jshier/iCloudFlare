//
//  RawDecodable.swift
//  HazeLight
//
//  Created by Jon Shier on 8/17/18.
//  Copyright © 2018 Jon Shier. All rights reserved.
//

import Alamofire
import Foundation

protocol RawDecodable {
    associatedtype RawType: Decodable
    
    init(_ rawValue: RawType) throws
}

extension Optional {
    func unwrapped() throws -> Wrapped {
        guard case let .some(value) = self else {
            throw OptionalError.noExpectedValue(type: String(reflecting: Wrapped.self))
        }
        
        return value
    }
}

enum OptionalError: Error {
    case noExpectedValue(type: String)
}

/// Type describing requirements for making a request. Typical it describes the where and how of a request / response pair.
protocol RequestRouter {
    /// Base `URL` for a request. Will have `path` appended to it.
    var baseURL: URL { get }
    /// Additional URL path components for a request.
    var path: String { get }
    /// `HTTPMethod` for a request.
    var method: HTTPMethod { get }
    /// The `ParameterEncoder` for a request. This will be used to encode an `Encodable` value into the request.
    var parameterEncoder: ParameterEncoder { get }
    /// A `ResponseDecoder` to be used to parse the response to the request.
    var responseDecoder: ResponseDecoder { get }
}

/// Type describing the route and parameters of a request. This type encompasses the how and where (the `RequestRouter`),
/// as well as the what (request `Parameters` and `Response`).
///
/// - Note: Inheriting from and conforming to `URLRequestConvertible` allows the type to directly use Alamofire's
///         `request()` methods with no special handling.
///
protocol Requestable: URLRequestConvertible {
    /// The expected response type.
    associatedtype Response: RawResponseDecodable
    /// The `Encodable` parameters that will be encoded into a request.
    associatedtype Parameters: Encodable
    
    /// Returns the `RequestRouter` used to make the request.
    ///
    /// - Returns: The `RequestRouter` value.
    /// - Throws:  Any error produced while creating or returning the `RequestRouter`.
    func router() throws -> RequestRouter
    /// Returns the `Parameters` to be encoded into the request.
    ///
    /// - Returns: The `Parameters`.
    /// - Throws:  Any error produced while creating the `Parameters`.
    func parameters() throws -> Parameters?
}

extension Requestable {
    func asURLRequest() throws -> URLRequest {
        let url = try router().baseURL.appendingPathComponent(try router().path)
        var request = URLRequest(url: url)
        request.httpMethod = try router().method.rawValue
        
        return try router().parameterEncoder.encode(try parameters(), into: request)
    }
}

extension Requestable {
    func parameters() -> Self? { return Optional<Self>.none }
}

/// Allow `Requestable` types which are `Encodable` too to be their own parameters.
extension Requestable where Self: Encodable {
    func parameters() -> Self? { return self }
}

/// Protocol describing types that can be transformed into types which go over the wire.
///
/// - Note: Inherits from `Requestable` so that conforming types are also `Requestable`.
///
protocol RawRequestEncodable: Requestable {
    /// The underlying `Requestable` which `Self` will tranform into.
    associatedtype RawRequest: Requestable
    associatedtype Response = Self.RawRequest.Response
    
    /// Transforms `Self` into a `Requestable` type.
    ///
    /// - Returns: The `RawRequest`.
    /// - Throws:  Any error produce during the transformation.
    func asRequest() throws -> RawRequest
}

/// Extensions connecting a `RawRequestEncodable` type's `RawRequest` type to its `Requestable` conformance. This
/// ensures conforming types only need to implement the `asRequest()` requirement.
extension RawRequestEncodable {
    func router() throws -> RequestRouter {
        return try asRequest().router()
    }
    
    func parameters() throws -> Self.RawRequest.Parameters? {
        return try asRequest().parameters()
    }
}

// MARK: - Response Handling

/// Protocol describing types which can be intialized using value received from the network.
///
/// - Note: This protocol allows the separation of network-received types with autogenerated `Codable` conformance and
///         properly designed Swift types, so types used in the app don't have to care how they were received from the
///         network.
///
protocol RawResponseDecodable {
    associatedtype RawResponse: Decodable
    
    init(_ rawValue: RawResponse) throws
}

/// Abstraction protocol for any decoder which decodes from `Data`.
protocol ResponseDecoder {
    /// Decode `Data` into the desired type.
    ///
    /// - Parameters:
    ///   - type: The `Type` to be decoded.
    ///   - data: The `Data` to be decoded from.
    /// - Returns: The instance of `Type` decoded.
    /// - Throws: A decoding error.
    func decode<Response: Decodable>(_ type: Response.Type, from data: Data) throws -> Response
}

extension JSONDecoder: ResponseDecoder { }
