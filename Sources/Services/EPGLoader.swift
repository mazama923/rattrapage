import Foundation

struct EPGLoader {
    func load(from urlString: String) async throws -> [String: [TVProgram]] {
        let value = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let url = URL(string: value),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            throw EPGLoaderError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("Rattrapage/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EPGLoaderError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw EPGLoaderError.httpStatus(httpResponse.statusCode)
        }

        return try XMLTVParser().parse(data)
    }
}

enum EPGLoaderError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "L'URL du guide TV doit être une URL HTTP(S) valide."
        case .invalidResponse:
            return "Le serveur du guide TV a renvoyé une réponse invalide."
        case .httpStatus(let statusCode):
            return "Le serveur du guide TV a répondu avec le code HTTP \(statusCode)."
        }
    }
}
