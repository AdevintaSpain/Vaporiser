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
        
        if let payload = mock.responseBody, let json = try? JSONSerialization.jsonObject(with: payload, options: .fragmentsAllowed) {
            print(json)
            print(print("\n⬆️ End response for  \(mock.method) \(mock.path)"))
        }
    }
    
    func answer(_ request: Request) -> MockData? {
        let mock: MockData?
        switch MockData.Method(httpMethod: request.method) {
        case .GET: 
            mock = getData.firstMatch(url: request.url, body: request.body.string, headers: request.headers)
        case .PUT:
            mock = putData.firstMatch(url: request.url, body: request.body.string, headers: request.headers)
        case .HEAD:
            mock = headData.firstMatch(url: request.url, body: request.body.string, headers: request.headers)
        case .POST:
            mock = postData.firstMatch(url: request.url, body: request.body.string, headers: request.headers)
        case .PATCH:
            mock = patchData.firstMatch(url: request.url, body: request.body.string, headers: request.headers)
        case .DELETE:
            mock = deleteData.firstMatch(url: request.url, body: request.body.string, headers: request.headers)
        case .OTHER:
            mock = otherData.firstMatch(url: request.url, body: request.body.string, method: request.method, headers: request.headers)
        }

        guard let mock else {
            print("\n🛑 Response not found for \(request.url.path)")
            return nil
        }

        log(mock)
        return mock
    }
}
