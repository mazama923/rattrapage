import Foundation

enum OfficialChannelApp: Equatable {
    case tf1Plus
    case m6Plus

    var displayName: String {
        switch self {
        case .tf1Plus:
            "TF1+"
        case .m6Plus:
            "M6+"
        }
    }
}

enum OfficialChannelAppService {
    static func officialApp(for channelName: String) -> OfficialChannelApp? {
        let tokens = channelName
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        if tokens.contains("TF1") || tokens.contains("TMC") || tokens.contains("TFX") {
            return .tf1Plus
        }

        let has6ter = tokens.contains("6TER") || zip(tokens, tokens.dropFirst()).contains {
            $0.0 == "6" && $0.1 == "TER"
        }
        if tokens.contains("M6") || tokens.contains("W9") || has6ter {
            return .m6Plus
        }

        return nil
    }
}
