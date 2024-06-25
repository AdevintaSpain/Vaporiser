import XCTest
import Vaporiser

enum HTTPOperation: Codable {
    case POST
    case GET
    case DELETE
}

enum ServerError: Error {
    case fileNotFound
    case dataParsing
}

private extension HTTPOperation {
    var serverMethod: MockData.Method {
        switch self {
        case .POST: .POST
        case .GET: .GET
        case .DELETE: .DELETE
        }
    }
}

enum TestData {

    case randomFacts

    var requestPath: String {
        switch self {
        case .randomFacts: "facts/random"
        }
    }

    var fileName: String {
        switch self {
        case .randomFacts: "facts"
        }
    }

    var data: Data? {
        guard let url = Bundle(for: ExampleUITests.self).url(forResource: fileName, withExtension: "json") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
    
    var method: HTTPOperation { 
        switch self {
        case .randomFacts: .GET
        }
    }
}

final class ExampleUITests: XCTestCase {

    let server = Vaporiser()

    override func tearDown() {
        super.tearDown()
        server.stop()
    }

    func setup(request: TestData) throws {
        server.store(
            mock: MockData(
                path: request.requestPath,
                responseBody: request.data,
                method: request.method.serverMethod
            )
        )
    }

    @MainActor
    func testExample() async throws {
        try await server.start()

        try setup(request: TestData.randomFacts)

        let app = XCUIApplication()
        app.launchEnvironment["RUNNING_XCUITESTS"] = "YES"
        app.launch()

        let searchButton = app.buttons["Search"]
        searchButton.tap()
        
        let resultElement = app.staticTexts["Cats have 9 lives"]
        let exists = resultElement.waitForExistence(timeout: 2)
        XCTAssertTrue(exists)
        resultElement.tap()
    }
}
