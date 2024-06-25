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
        guard let currentBody = convertToDictionary(currentBody),
              let requestBody = try? JSONSerialization.jsonObject(with: requestBody, options: []) as? [String: String] else {
            return false
        }

        return currentBody == requestBody
    }

    private func convertToDictionary(_ text: String?) -> [String: String]? {
        guard let text, let data = text.data(using: .utf8) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
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
