//
//  WebsiteMetadataFetcher.swift
//  site_navigator
//

import Foundation
import UIKit

struct WebsiteMetadata {
    var title: String?
    var iconData: Data?
}

/// Best-effort scraper for a site's title and favicon. Every step degrades
/// gracefully — this never throws in a way that would block saving a site;
/// worst case it returns an all-nil `WebsiteMetadata` and the caller falls
/// back to showing the raw URL and a placeholder icon.
///
/// Marked `nonisolated` so the regex parsing / image decoding here runs off
/// the main actor between network awaits (the project's default actor
/// isolation is `MainActor`, which would otherwise pin this CPU-bound work
/// to the main thread).
nonisolated enum WebsiteMetadataFetcher {

    /// Prepends "https://" when the user typed a bare domain (e.g. "example.com").
    static func normalizeURL(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let candidate: String
        if trimmed.contains("://") {
            candidate = trimmed
        } else {
            candidate = "https://" + trimmed
        }

        guard let url = URL(string: candidate), url.host != nil else { return nil }
        return url
    }

    static func fetchMetadata(for url: URL) async -> WebsiteMetadata {
        let html = await fetchHTML(from: url)

        let title = html.flatMap(extractTitle)

        var iconData: Data?

        if let html {
            let candidates = extractIconCandidates(from: html, baseURL: url)
            iconData = await downloadFirstValidImage(from: candidates)
        }

        if iconData == nil {
            iconData = await downloadFirstValidImage(from: [domainRootFavicon(for: url)])
        }

        if iconData == nil {
            iconData = await downloadFirstValidImage(from: [thirdPartyFaviconFallback(for: url)], requireDecodable: false)
        }

        let processedIcon = iconData.flatMap { ImageProcessing.resizedAndCompressed($0) }

        return WebsiteMetadata(title: title, iconData: processedIcon)
    }

    // MARK: - HTML fetching

    private static func fetchHTML(from url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 8

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }
            return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
        } catch {
            return nil
        }
    }

    // MARK: - Title extraction

    private static func extractTitle(from html: String) -> String? {
        if let raw = firstMatch(pattern: "<title[^>]*>(.*?)</title>", in: html, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            let decoded = decodeHTMLEntities(raw).trimmingCharacters(in: .whitespacesAndNewlines)
            if !decoded.isEmpty { return decoded }
        }

        // Fall back to Open Graph title, whichever attribute order the tag uses.
        let ogPatterns = [
            #"<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']"#,
        ]
        for pattern in ogPatterns {
            if let raw = firstMatch(pattern: pattern, in: html, options: [.caseInsensitive]) {
                let decoded = decodeHTMLEntities(raw).trimmingCharacters(in: .whitespacesAndNewlines)
                if !decoded.isEmpty { return decoded }
            }
        }
        return nil
    }

    // MARK: - Icon candidate extraction

    private static func extractIconCandidates(from html: String, baseURL: URL) -> [URL] {
        let linkTagPattern = "<link[^>]+>"
        guard let regex = try? NSRegularExpression(pattern: linkTagPattern, options: [.caseInsensitive]) else {
            return []
        }
        let nsHTML = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsHTML.length))

        // (priority, url) pairs; lower priority number = tried first.
        var scored: [(Int, URL)] = []

        for match in matches {
            let tag = nsHTML.substring(with: match.range)
            guard let rel = firstMatch(pattern: #"rel=["']([^"']+)["']"#, in: tag, options: [.caseInsensitive])?.lowercased() else {
                continue
            }
            guard rel.contains("icon") else { continue }
            guard let href = firstMatch(pattern: #"href=["']([^"']+)["']"#, in: tag, options: [.caseInsensitive]) else {
                continue
            }
            let decodedHref = decodeHTMLEntities(href)
            guard let resolved = URL(string: decodedHref, relativeTo: baseURL)?.absoluteURL else { continue }

            let priority: Int
            if rel.contains("apple-touch-icon") {
                priority = 0
            } else if rel == "icon" {
                priority = 1
            } else {
                priority = 2 // e.g. "shortcut icon"
            }
            scored.append((priority, resolved))
        }

        return scored
            .sorted { $0.0 < $1.0 }
            .map(\.1)
    }

    private static func domainRootFavicon(for url: URL) -> URL {
        var components = URLComponents()
        components.scheme = url.scheme ?? "https"
        components.host = url.host
        components.path = "/favicon.ico"
        return components.url ?? url
    }

    private static func thirdPartyFaviconFallback(for url: URL) -> URL {
        var components = URLComponents(string: "https://www.google.com/s2/favicons")!
        components.queryItems = [
            URLQueryItem(name: "domain", value: url.host ?? url.absoluteString),
            URLQueryItem(name: "sz", value: "128"),
        ]
        return components.url ?? url
    }

    // MARK: - Image download

    /// Downloads the first candidate that succeeds. When `requireDecodable` is
    /// true (the default), the response must also decode as a raster image via
    /// `UIImage(data:)` — this is what lets SVG favicons fail fast and fall
    /// through to the next tier instead of being stored as unusable data.
    private static func downloadFirstValidImage(from candidates: [URL], requireDecodable: Bool = true) async -> Data? {
        for candidate in candidates {
            var request = URLRequest(url: candidate)
            request.timeoutInterval = 8
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    continue
                }
                if requireDecodable {
                    guard UIImage(data: data) != nil else { continue }
                }
                return data
            } catch {
                continue
            }
        }
        return nil
    }

    // MARK: - Small string helpers

    private static func firstMatch(pattern: String, in text: String, options: NSRegularExpression.Options = []) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsText.length)),
              match.numberOfRanges > 1 else {
            return nil
        }
        return nsText.substring(with: match.range(at: 1))
    }

    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let namedEntities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&apos;", "'"), ("&#39;", "'"), ("&nbsp;", " "),
        ]
        for (entity, replacement) in namedEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Numeric entities: &#123; and &#x1F600;
        if let regex = try? NSRegularExpression(pattern: "&#x?[0-9A-Fa-f]+;", options: [.caseInsensitive]) {
            let nsResult = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsResult.length))
            for match in matches.reversed() {
                let token = nsResult.substring(with: match.range)
                let isHex = token.lowercased().hasPrefix("&#x")
                let digitsStart = token.index(token.startIndex, offsetBy: isHex ? 3 : 2)
                let digits = token[digitsStart..<token.index(before: token.endIndex)]
                if let scalarValue = UInt32(digits, radix: isHex ? 16 : 10),
                   let scalar = Unicode.Scalar(scalarValue) {
                    result = (result as NSString).replacingCharacters(in: match.range, with: String(Character(scalar)))
                }
            }
        }
        return result
    }
}
