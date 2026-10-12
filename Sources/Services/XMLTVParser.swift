import Foundation

struct XMLTVParser {
    func parse(_ data: Data, now: Date = Date()) throws -> [String: [TVProgram]] {
        let delegate = XMLTVParserDelegate(now: now)
        let parser = XMLParser(data: data)
        parser.delegate = delegate

        guard parser.parse() else {
            throw delegate.parseError ?? XMLTVParserError.invalidDocument
        }

        return delegate.programsByChannel
    }
}

enum XMLTVParserError: LocalizedError {
    case invalidDocument

    var errorDescription: String? {
        "Le guide TV XML est invalide ou illisible."
    }
}

private final class XMLTVParserDelegate: NSObject, XMLParserDelegate {
    private let now: Date
    private let dateFormatters: [DateFormatter]
    private var activeProgram: ProgramDraft?
    private var activeTextElement: String?
    private var text = ""
    private(set) var programsByChannel: [String: [TVProgram]] = [:]
    var parseError: Error?

    init(now: Date) {
        self.now = now
        self.dateFormatters = ["yyyyMMddHHmmss Z", "yyyyMMddHHmmss"].map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            formatter.isLenient = false
            return formatter
        }
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        if elementName == "programme" {
            activeProgram = ProgramDraft(
                channelID: attributeDict["channel"] ?? "",
                start: attributeDict["start"],
                end: attributeDict["stop"]
            )
        } else if activeProgram != nil, elementName == "title" || elementName == "desc" {
            activeTextElement = elementName
            text = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard activeTextElement != nil else { return }
        text += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == activeTextElement {
            if activeTextElement == "title" {
                activeProgram?.title = text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if activeTextElement == "desc" {
                activeProgram?.summary = text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            activeTextElement = nil
            text = ""
        }

        guard elementName == "programme", let draft = activeProgram else { return }
        activeProgram = nil
        add(draft)
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }

    private func add(_ draft: ProgramDraft) {
        guard
            !draft.channelID.isEmpty,
            let startString = draft.start,
            let endString = draft.end,
            let start = date(from: startString),
            let end = date(from: endString),
            start < end,
            end > now,
            !draft.title.isEmpty
        else {
            return
        }

        let program = TVProgram(
            channelID: draft.channelID,
            title: draft.title,
            start: start,
            end: end,
            summary: draft.summary.isEmpty ? nil : draft.summary
        )

        // On garde le programme en cours et le suivant, pas l'historique complet du guide.
        let updatedPrograms = (programsByChannel[draft.channelID, default: []] + [program])
            .sorted { $0.start < $1.start }
        programsByChannel[draft.channelID] = Array(updatedPrograms.prefix(2))
    }

    private func date(from value: String) -> Date? {
        // Sans fuseau dans le XMLTV, l'heure est interprétée en UTC.
        dateFormatters.lazy.compactMap { $0.date(from: value) }.first
    }

    private struct ProgramDraft {
        let channelID: String
        let start: String?
        let end: String?
        var title = ""
        var summary = ""
    }
}
