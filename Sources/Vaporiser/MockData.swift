import Foundation
import Vapor

public struct MockData: Codable {

    public let path: String
    public let payload: Data?
    public let method: Method
    public let returnCode: Int
    public let queryParameters: [URLQueryItem]?

    public init(path: String, payload: Data? = nil, method: MockData.Method, queryParameters: [URLQueryItem]? = nil, returnCode: Int = 200) {
        self.path = path
        self.payload = payload
        self.method = method
        self.returnCode = returnCode
        self.queryParameters = queryParameters
    }

    var pathComponents: [PathComponent] {
        path.pathComponents
    }

    func matches(url: URI) -> Bool {
        path.matches(url: url) && url.string.matches(queryParameters: queryParameters)
    }

    func matches(url: URI, method: Method) -> Bool {
        guard method == self.method else { return false }
        return matches(url: url)
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
}

extension Dictionary where Key == String, Value == MockData {
    func firstMatch(url: URI) -> MockData? {
        guard let universalPath = keys.first(where: { self[$0]?.matches(url: url) ?? false })  else {
            return nil
        }
        return self[universalPath]
    }
}

extension Array where Element == MockData {
    func firstMatch(url: URI, method: HTTPMethod) -> MockData? {
        first(where: { $0.matches(url: url, method: .init(httpMethod: method))})
    }
}
