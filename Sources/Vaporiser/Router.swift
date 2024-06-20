import Foundation
import Vapor

class Router {
    var getData = [String: MockData]()
    var putData = [String: MockData]()
    var headData = [String: MockData]()
    var postData = [String: MockData]()
    var patchData = [String: MockData]()
    var deleteData = [String: MockData]()
    var otherData = [MockData]()

    func store(_ request: Request) throws {

        guard let bytes = request.body.data else {
            throw MockServerError.incorrectMock
        }

        let mock = try JSONDecoder().decode(MockData.self, from: bytes)

        store(mock)
    }

    func store(_ mock: MockData) {
        switch mock.method {
        case .GET:
            getData[mock.path] = mock
        case .PUT:
            putData[mock.path] = mock
        case .HEAD:
            headData[mock.path] = mock
        case .POST:
            postData[mock.path] = mock
        case .PATCH:
            patchData[mock.path] = mock
        case .DELETE:
            deleteData[mock.path] = mock
        case .OTHER:
            otherData.append(mock)
        }

        print("\n -------- \nResponse added for \npath: \(mock.path) \nmethod: \(mock.method)")
    }

    private func log(_ mock: MockData) {
        print(print("\n✅ Response for \(mock.method) \(mock.path)"))
        
        if let payload = mock.payload, let json = try? JSONSerialization.jsonObject(with: payload, options: .fragmentsAllowed) {
            print(json)
            print(print("\n⬆️ End response for  \(mock.method) \(mock.path)"))
        }
    }
    
    func answer(_ request: Request) -> MockData? {
        let mock: MockData?
        switch MockData.Method(httpMethod: request.method) {
        case .GET: 
            mock = getData.firstMatch(url: request.url)
        case .PUT:
            mock = putData.firstMatch(url: request.url)
        case .HEAD:
            mock = headData.firstMatch(url: request.url)
        case .POST:
            mock = postData.firstMatch(url: request.url)
        case .PATCH:
            mock = patchData.firstMatch(url: request.url)
        case .DELETE:
            mock = deleteData.firstMatch(url: request.url)
        case .OTHER:
            mock = otherData.firstMatch(url: request.url, method: request.method)
        }

        guard let mock else {
            print("\n🛑 Response not found for \(request.url.path)")
            return nil
        }

        log(mock)
        return mock
    }
}

public struct MockData: Codable {

    public let path: String
    public let payload: Data?
    public let method: Method
    public let returnCode: Int

    public init(path: String, payload: Data? = nil, method: MockData.Method, returnCode: Int = 200) {
        self.path = path
        self.payload = payload
        self.method = method
        self.returnCode = returnCode
    }

    var pathComponents: [PathComponent] {
        path.pathComponents
    }

    func matches(url: URI) -> Bool {
        path.matches(url: url)
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

private extension String {
    func matches(url: URI) -> Bool {
        guard url.path.pathComponents.count == pathComponents.count else {
            return false
        }

        var match = true
        for (component1, component2) in zip(url.path.pathComponents, pathComponents) {

            if component2 == .anything {
                continue
            }

            if component1 != component2 {
                match = false
                break
            }
        }

        return match
    }
}

private extension Dictionary where Key == String, Value == MockData {
    func firstMatch(url: URI) -> MockData? {
        guard let universalPath = keys.first(where: { $0.matches(url: url)})  else {
            return nil
        }
        return self[universalPath]
    }
}

public extension Array where Element == MockData {
    func firstMatch(url: URI, method: HTTPMethod) -> MockData? {
        first(where: { $0.matches(url: url, method: .init(httpMethod: method))})
    }
}
