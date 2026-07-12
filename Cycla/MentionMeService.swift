import Foundation

/// A signed Mention Me **Entry Point** journey — a hosted URL to load in a web
/// view, returned by the backend (which calls `/api/entry-point/v2/offer` or
/// `/dashboard` on the Consumer/Entry Point API).
struct MentionMeEntryPoint: Decodable {
    let url: String
    let defaultCallToAction: String?
    let headline: String?
    let description: String?
    let mode: String?   // "offer" or "dashboard"
}

/// Calls our backend, which signs & proxies the Mention Me Entry Point API.
enum MentionMeService {
    static func fetchReferrerEntryPoint(email: String,
                                        firstname: String,
                                        surname: String) async throws -> MentionMeEntryPoint {
        var comps = URLComponents(string: "\(Constants.MentionMe.backendBaseURL)/mentionme/referrer")!
        comps.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "firstname", value: firstname),
            URLQueryItem(name: "surname", value: surname),
        ]
        let (data, response) = try await URLSession.shared.data(from: comps.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(MentionMeEntryPoint.self, from: data)
    }
}
