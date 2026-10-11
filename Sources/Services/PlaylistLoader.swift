import Foundation

enum PlaylistLoaderError: LocalizedError {
    case invalidURL
    case unsupportedScheme
    case invalidResponse
    case httpStatus(Int)
    case unreadableText

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "L'URL de la playlist est invalide."
        case .unsupportedScheme:
            return "Utilisez une URL HTTP(S) ou un fichier local."
        case .invalidResponse:
            return "Le serveur a renvoyé une réponse invalide."
        case .httpStatus(let statusCode):
            return "Le serveur a répondu avec le code HTTP \(statusCode)."
        case .unreadableText:
            return "Impossible de lire le contenu de la playlist."
        }
    }
}

struct PlaylistLoader {
    /// Point d'entrée destiné au champ de saisie de l'étape MVP.
    func load(from urlString: String) async throws -> [Channel] {
        let value = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: value) else {
            throw PlaylistLoaderError.invalidURL
        }

        return try await load(from: url)
    }

    /// Accepte aussi une URL file:// afin de préparer un futur sélecteur de fichier local.
    func load(from url: URL) async throws -> [Channel] {
        let data: Data

        if url.isFileURL {
            data = try Data(contentsOf: url)
        } else {
            guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
                throw PlaylistLoaderError.unsupportedScheme
            }

            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            request.setValue("Rattrapage/1.0", forHTTPHeaderField: "User-Agent")

            let responseData = try await URLSession.shared.data(for: request)
            data = responseData.0

            guard let response = responseData.1 as? HTTPURLResponse else {
                throw PlaylistLoaderError.invalidResponse
            }
            guard (200...299).contains(response.statusCode) else {
                throw PlaylistLoaderError.httpStatus(response.statusCode)
            }
        }

        guard let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
        else {
            throw PlaylistLoaderError.unreadableText
        }

        return try M3UParser().parse(text, relativeTo: url.deletingLastPathComponent())
    }
}
