import Dependencies
import PodcastRoute

extension LogPodcastEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await context.db.create(PodcastEvent(
      eventId: input.eventId,
      kind: .init(rawValue: input.kind) ?? .unexpected,
      label: input.label,
      detail: input.detail,
      installId: input.installId,
      deviceType: input.deviceType,
      appVersion: input.appVersion,
      iosVersion: input.iosVersion
    ))

    if context.env.mode == .prod {
      let slack = get(dependency: \.slack)
      let detail = input.detail ?? "(nil)"
      let search = githubSearch(input.eventId, repo: "podcasts")
      let message = "Podcast app event: \(search) \(detail)"
      await slack.internal(.info, message)
    }

    return .success
  }
}
