import Foundation
import SwiftData
@preconcurrency import FoundationIntelligence

@MainActor
final class SummarizationService {
    static let shared = SummarizationService()
    private init() {}

    var isAvailable: Bool {
        if #available(iOS 18.1, *) {
            return true
        }
        return false
    }

    func summarize(_ item: NewsItem, context: ModelContext) async {
        guard item.summary == nil else { return }

        if #available(iOS 18.1, *) {
            await summarizeWithAppleIntelligence(item, context: context)
        }
    }

    @available(iOS 18.1, *)
    private func summarizeWithAppleIntelligence(_ item: NewsItem, context: ModelContext) async {
        let textToSummarize = "\(item.title). \(item.snippet)"
        guard !textToSummarize.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        do {
            let session = FoundationIntelligence.Summarizer(
                format: .paragraph,
                style: .concise
            )
            let result = try await session.summarize(textToSummarize)
            item.summary = result
            try? context.save()
        } catch {
            print("Summarization failed: \(error.localizedDescription)")
        }
    }
}
