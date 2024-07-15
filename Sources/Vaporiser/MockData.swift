import Foundation
import Vapor

public struct MockData: Codable {

    public let path: String
    public let responseBody: Data?
    public let method: Method
    public let returnCode: Int
    public let requestBody: Data?
    public let queryParameters: [URLQueryItem]?
    public let requestHeaders: [String: String]?

    public init(
        path: String,
        responseBody: Data? = nil,
        method: MockData.Method,
        queryParameters: [URLQueryItem]? = nil,
        requestBody: Data? = nil,
        requestHeaders: [String: String]? = nil,
        returnCode: Int = 200
    ) {
        self.path = path
        self.responseBody = responseBody
        self.method = method
        self.queryParameters = queryParameters
        self.requestBody = requestBody
        self.requestHeaders = requestHeaders
        self.returnCode = returnCode
    }

    var pathComponents: [PathComponent] {
        path.pathComponents
    }

    func matches(url: URI, body: String?, headers: HTTPHeaders) -> Bool {
        path.matches(url: url) && url.string.matches(queryParameters: queryParameters) && matches(body: body, mediaType: headers.contentType) && matches(headers: headers)
    }

    func matches(url: URI, body: String?, method: Method, headers: HTTPHeaders) -> Bool {
        guard method == self.method else { return false }
        return matches(url: url, body: body, headers: headers)
    }

    func matches(headers: HTTPHeaders) -> Bool {
        guard let requestHeaders = self.requestHeaders else { return true }

        for requestHeader in requestHeaders.keys {
            if let requestHeaderValue = headers.first(name: requestHeader), requestHeaderValue == requestHeaders[requestHeader] { } else {
                return false
            }
        }

        return true
    }

    public enum Method: Codable, Equatable {
        case GET
        case PUT
        case HEAD
        case POST
        case PATCH
        case DELETE
        case OTHER(String)

        init(httpMethod: HTTPMethod) {
            switch httpMethod {
            case .GET: self = .GET
            case .PUT: self = .PUT
            case .HEAD: self = .HEAD
            case .POST: self = .POST
            case .DELETE: self = .DELETE
            default: self = .OTHER(httpMethod.rawValue)
            }
        }
    }

    private func matches(body: String?, mediaType: HTTPMediaType?) -> Bool {
        guard let requestBody = self.requestBody, let mediaType else { return true }
        switch mediaType {
        case .json:
            return jsonBodyMatches(requestBody: requestBody, currentBody: body)
        default:
            return true // Not supported yet
        }
    }

    private func jsonBodyMatches(requestBody: Data, currentBody: String?) -> Bool {
        guard let requestBody = try? JSONSerialization.jsonObject(with: requestBody, options: []),
              let dataBody = currentBody?.data(using: .utf8),
              let currentBody = try? JSONSerialization.jsonObject(with: dataBody, options: []) else {
            return false
        }
        return matchJSONLevel(matching: requestBody, from: currentBody)
    }

    func matchJSONLevel(matching: Any, from: Any) -> Bool {

        /// - Top level object is an NSArray or NSDictionary
        /// - All objects are NSString, NSNumber, NSArray, NSDictionary, or NSNull
        /// - All dictionary keys are NSStrings
        /// - NSNumbers are not NaN or infinity

        if let m = matching as? NSArray, let f = from as? NSArray {
            var idx = 0
            for element in m {
                if idx < f.count {
                    if !matchJSONLevel(matching: element, from: f[idx]) {
                        return false
                    }
                } else {
                    return false
                }
                idx += 1
            }
            return true
        } else if let m = matching as? NSDictionary, let f = from as? NSDictionary {
            let matchingKeys = m.allKeys
            for key in matchingKeys {
                if let fromValue = f[key], let matchingValue = m[key] {
                    if !matchJSONLevel(matching: matchingValue, from: fromValue) {
                        return false
                    }
                } else {
                    return false
                }
            }
            return true
        } else if let m = matching as? NSString, let f = from as? NSString {
            return m.isEqual(to: f as String)
        } else if let m = matching as? NSNumber, let f = from as? NSNumber {
            return m.isEqual(to: f)
        } else if let m = matching as? NSNull, let f = from as? NSNull {
            return m.isEqual(f)
        } else {
            return false
        }
    }
}

extension Dictionary where Key == String, Value == MockData {
    func firstMatch(url: URI, body: String?, headers: HTTPHeaders) -> MockData? {
        guard let universalPath = keys.first(where: { self[$0]?.matches(url: url, body: body, headers: headers) ?? false })  else {
            return nil
        }
        return self[universalPath]
    }
}

extension Array where Element == MockData {
    func firstMatch(url: URI, body: String?, method: HTTPMethod, headers: HTTPHeaders) -> MockData? {
        first(where: { $0.matches(url: url, body: body, method: .init(httpMethod: method), headers: headers)})
    }
}
