import Foundation
import Vapor

protocol Matches {
    func matches(url: URI) -> Bool
    func matches(queryParameters: [URLQueryItem]?) -> Bool
}

extension String: Matches {
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

    func matches(queryParameters: [URLQueryItem]?) -> Bool {
        guard let requestedQueryItems = queryParameters, let requestUrlComponents = URLComponents(string: self),
            let queryItems = requestUrlComponents.queryItems else { return true }

        var mached = true
        for requestQueryItem in requestedQueryItems where mached == true {
            mached = (queryItems.first { $0.name == requestQueryItem.name }?.value == requestQueryItem.value) && mached
        }
        return mached
    }
}
