import Foundation

enum M3UParserError: LocalizedError {
    case noPlayableChannels

    var errorDescription: String? {
        switch self {
        case .noPlayableChannels:
            return "La playlist ne contient aucune chaîne lisible."
        }
    }
}

struct M3UParser {
    /// Lit le format courant : une ligne #EXTINF décrit la chaîne et la ligne suivante est son URL.
    func parse(_ playlist: String, relativeTo baseURL: URL? = nil) throws -> [Channel] {
        var channels: [Channel] = []
        var pendingMetadata: Metadata?

        for rawLine in playlist.components(separatedBy: .newlines) {
            let line = rawLine
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\u{FEFF}", with: "")

            guard !line.isEmpty else { continue }

            if line.hasPrefix("#EXTINF:") {
                pendingMetadata = metadata(from: line)
                continue
            }

            let userAgentPrefix = "#EXTVLCOPT:http-user-agent="
            if line.hasPrefix(userAgentPrefix) {
                let value = String(line.dropFirst(userAgentPrefix.count))
                pendingMetadata?.userAgent = validUserAgent(value)
                continue
            }

            // Les autres directives M3U (#EXTM3U, #EXTVLCOPT…) ne sont pas des flux.
            guard !line.hasPrefix("#"), let metadata = pendingMetadata else { continue }
            defer { pendingMetadata = nil }

            guard let streamURL = URL(string: line, relativeTo: baseURL)?.absoluteURL else {
                continue
            }

            let logoURL = metadata.logoURLString.flatMap { URL(string: $0, relativeTo: baseURL)?.absoluteURL }
            channels.append(
                Channel(
                    name: metadata.name,
                    streamURL: streamURL,
                    logoURL: logoURL,
                    group: metadata.group,
                    guideID: metadata.guideID,
                    userAgent: metadata.userAgent
                )
            )
        }

        guard !channels.isEmpty else {
            throw M3UParserError.noPlayableChannels
        }

        return channels
    }

    private func metadata(from extinf: String) -> Metadata {
        // Le nom affiché est la partie située après la dernière virgule de #EXTINF.
        let name: String
        if let separator = extinf.lastIndex(of: ",") {
            name = String(extinf[extinf.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
        } else {
            name = "Unnamed channel"
        }

        return Metadata(
            name: name.isEmpty ? "Unnamed channel" : name,
            logoURLString: attribute(named: "tvg-logo", in: extinf),
            group: nonEmptyAttribute(named: "group-title", in: extinf),
            guideID: nonEmptyAttribute(named: "tvg-id", in: extinf),
            userAgent: attribute(named: "http-user-agent", in: extinf).flatMap(validUserAgent)
        )
    }

    private func nonEmptyAttribute(named name: String, in text: String) -> String? {
        guard let value = attribute(named: name, in: text)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !value.isEmpty
        else {
            return nil
        }
        return value
    }

    private func validUserAgent(_ value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmedValue.isEmpty,
            !trimmedValue.contains("\r"),
            !trimmedValue.contains("\n")
        else {
            return nil
        }
        return trimmedValue
    }

    private func attribute(named name: String, in text: String) -> String? {
        let pattern = "(?:^|\\s)" + NSRegularExpression.escapedPattern(for: name) + "=\\\"([^\\\"]*)\\\""
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(text.startIndex..., in: text)
        guard
            let match = expression.firstMatch(in: text, range: range),
            let valueRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return String(text[valueRange])
    }

    private struct Metadata {
        let name: String
        let logoURLString: String?
        let group: String?
        let guideID: String?
        var userAgent: String?
    }
}
