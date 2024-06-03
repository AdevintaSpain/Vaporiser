import SwiftUI
import Foundation

struct CatView: View {
    @ObservedObject var presenter = CatPresenter()

    var body: some View {
        Group {
            switch presenter.state {
            case .idle: idleView
            case .loading: loadingView
            case .error(let error): errorView(error)
            case .fetched(let cats): list(cats)
            }
        }
    }

    var idleView: some View {
        VStack {
            Button(action: { onTap() }) {
                Text("Search")
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
    }

    var loadingView: some View {
        VStack { ProgressView() }
    }

    func errorView(_ error: String) -> some View {
        VStack { Text(error) }
    }

    func list(_ cats: [Cat]) -> some View {
        List(cats, id: \.id) { cat in
            Text(cat.text)
        }
    }

    func onTap() {
        Task {
            try await Task.sleep(for: .seconds(1))
            await presenter.fetchFacts()
        }
    }
}

class CatPresenter: ObservableObject {

    let repo = CatRepo()
    enum State {
        case loading
        case idle
        case fetched([Cat])
        case error(String)
    }

    @Published var state = State.idle

    @MainActor
    func fetchFacts() async {
        state = .loading
        do {
            let cat = try await repo.fetchFacts(for: .cat)
            state = .fetched(cat)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func fetchFact(id: String) async {}
}

enum AnimalType: String {
    case cat
}

struct Cat: Codable {
    let id: String
    let text: String
    let deleted: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case text
        case deleted
    }
}

class CatRepo {
    enum CatService {

        case facts(AnimalType)
        case someFact(String)

        var endpoint: String {
            switch self {
            case .facts: "facts/random"
            case .someFact(let id): "facts/\(id)"
            }
        }

        var queryItems: [URLQueryItem] {
            switch self {
            case .facts(let animalType):
                [
                    URLQueryItem(name: "animal_type", value: animalType.rawValue),
                    URLQueryItem(name: "amount", value: "20"),
                ]
            case .someFact:
                []
            }
        }

        var baseURL: String {
            if isRunningUITests() {
                return "http://127.0.0.1:8080"
            } else {
                return "https://cat-fact.herokuapp.com"
            }
        }

        var url: URL {
            let service = CatService.facts(.cat)
            var url = URL(string: baseURL+"/"+service.endpoint)!
            url.append(queryItems: service.queryItems)
            return url
        }

        var request: URLRequest {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            return request
        }
    }

    enum CatError: Error {
        case noData
    }

    func fetchFacts(for: AnimalType) async throws -> [Cat] {
        let result = try await URLSession.shared.data(for: CatService.facts(.cat).request)
        return try JSONDecoder().decode([Cat].self, from: result.0)
    }

    func fetchFact(id: String) async throws -> Cat {
        let result = try await URLSession.shared.data(for: CatService.someFact(id).request)
        return try JSONDecoder().decode(Cat.self, from: result.0)
    }

}

#Preview {
    CatView()
}

public func isRunningUITests() -> Bool {
    return ProcessInfo.processInfo.environment["RUNNING_XCUITESTS"] != nil
}
