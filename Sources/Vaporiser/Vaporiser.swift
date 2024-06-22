import Vapor
import Foundation

public class Vaporiser {
    public init() {}
    lazy var app: Application = {
        do {
            var env = try Environment.detect()
            return Application(env)
        } catch {
            fatalError("Couldn't start server")
        }
    }()

    var router = Router()

    public func start() async throws {
        try configure(app: app)
        try await app.startup()
    }

    public func stop() {
        app.shutdown()
    }

    func respond(_ request: Request) throws -> Response {
        guard let mock = router.answer(request) else {
            return Response(
                status: .notFound,
                headers: .init([("Content-Type", "application/json")]),
                body: .empty
            )
        }
        
        let body = mock.responseBody.map { data in Response.Body(data: data) } ?? Response.Body()
        return Response(
            status: .init(statusCode: mock.returnCode),
            headers: .init([("Content-Type", "application/json")]),
            body: body
        )
    }

    public func store(mock: MockData) {
        router.store(mock)
    }

    func configure(app: Application) throws {
        app.routes.defaultMaxBodySize = "1mb"

        app.get(.catchall) { request in
            try self.respond(request)
        }

        app.post(.catchall) { request in
            try self.respond(request)
        }

        app.delete(.catchall) { request in
            try self.respond(request)
        }

        app.post("setMock") { request in

            try self.router.store(request)

            return Response(
                status: .ok,
                version: .http1_1,
                headers: .init([("Content-Type", "application/json")]),
                body: .empty
            )
        }
    }
}

enum MockServerError: Error {
    case incorrectMock
    case missingStub
}

struct HelloStruct: Content {
    var value: String
}
