import SwiftUI

struct MarkdownRenderer: View {
    var markdown: String
    var baseURL: URL?

    private var blocks: [MarkdownBlock] {
        MarkdownParser.parse(markdown: markdown, baseURL: baseURL)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(blocks) { block in
                switch block.kind {
                case .heading(let level):
                    Text(block.text)
                        .font(headingFont(level: level))
                        .foregroundStyle(.primary)
                        .padding(.top, level == 1 ? 8 : 4)
                case .paragraph:
                    markdownText(block.text)
                        .font(.body)
                        .lineSpacing(4)
                        .foregroundStyle(.primary)
                case .bullet:
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Circle()
                            .fill(.blue.gradient)
                            .frame(width: 5, height: 5)
                        markdownText(block.text)
                            .font(.body)
                            .lineSpacing(3)
                    }
                case .code(let language):
                    VStack(alignment: .leading, spacing: 8) {
                        if !language.isEmpty {
                            Text(language.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(block.text)
                                .font(.system(.callout, design: .monospaced))
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                                .padding(14)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(.white.opacity(0.08))
                    }
                case .image(let url):
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        case .failure:
                            EmptyView()
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 120)
                        @unknown default:
                            EmptyView()
                        }
                    }
                case .divider:
                    Divider()
                        .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func headingFont(level: Int) -> Font {
        switch level {
        case 1: return .system(.title, design: .rounded, weight: .bold)
        case 2: return .system(.title2, design: .rounded, weight: .bold)
        default: return .system(.headline, design: .rounded, weight: .semibold)
        }
    }

    private func markdownText(_ source: String) -> Text {
        if let attributed = try? AttributedString(markdown: source, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return Text(attributed)
        }
        return Text(source)
    }
}

private struct MarkdownBlock: Identifiable {
    let id = UUID()
    var kind: MarkdownBlockKind
    var text: String
}

private enum MarkdownBlockKind {
    case heading(Int)
    case paragraph
    case bullet
    case code(String)
    case image(URL)
    case divider
}

private enum MarkdownParser {
    static func parse(markdown: String, baseURL: URL?) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraphLines: [String] = []
        var codeLines: [String] = []
        var codeLanguage = ""
        var isInCodeBlock = false

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(MarkdownBlock(kind: .paragraph, text: paragraphLines.joined(separator: " ")))
            paragraphLines.removeAll()
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("```") {
                if isInCodeBlock {
                    blocks.append(MarkdownBlock(kind: .code(codeLanguage), text: codeLines.joined(separator: "\n")))
                    codeLines.removeAll()
                    codeLanguage = ""
                    isInCodeBlock = false
                } else {
                    flushParagraph()
                    isInCodeBlock = true
                    codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                continue
            }

            if isInCodeBlock {
                codeLines.append(rawLine)
                continue
            }

            if line.isEmpty {
                flushParagraph()
                continue
            }

            if line == "---" || line == "***" {
                flushParagraph()
                blocks.append(MarkdownBlock(kind: .divider, text: ""))
                continue
            }

            if let imageURL = imageURL(from: line, baseURL: baseURL) {
                flushParagraph()
                blocks.append(MarkdownBlock(kind: .image(imageURL), text: ""))
                continue
            }

            if line.hasPrefix("#") {
                flushParagraph()
                let level = line.prefix { $0 == "#" }.count
                let text = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
                blocks.append(MarkdownBlock(kind: .heading(level), text: text))
                continue
            }

            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                blocks.append(MarkdownBlock(kind: .bullet, text: String(line.dropFirst(2))))
                continue
            }

            paragraphLines.append(line)
        }

        if isInCodeBlock {
            blocks.append(MarkdownBlock(kind: .code(codeLanguage), text: codeLines.joined(separator: "\n")))
        }
        flushParagraph()

        return blocks.isEmpty ? [MarkdownBlock(kind: .paragraph, text: "No README content available.")] : blocks
    }

    private static func imageURL(from line: String, baseURL: URL?) -> URL? {
        guard line.hasPrefix("!["), let open = line.firstIndex(of: "("), let close = line.lastIndex(of: ")"), open < close else {
            return nil
        }
        let path = String(line[line.index(after: open)..<close])
        if let url = URL(string: path), url.scheme != nil {
            return url
        }
        return URL(string: path, relativeTo: baseURL)
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")))
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
