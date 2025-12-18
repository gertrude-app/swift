import PairQL
import Vapor

enum AuthedAdminRoute: PairRoute {
  case macOverview
  case iOSOverview
  case podcastOverview
  case parentsList(ParentsList.Input)
  case parentDetail(ParentDetail.Input)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.macOverview)) {
      Operation(MacOverview.self)
    }
    Route(.case(Self.iOSOverview)) {
      Operation(IOSOverview.self)
    }
    Route(.case(Self.podcastOverview)) {
      Operation(PodcastOverview.self)
    }
    Route(.case(Self.parentsList)) {
      Operation(ParentsList.self)
      Body(.input(ParentsList.self))
    }
    Route(.case(Self.parentDetail)) {
      Operation(ParentDetail.self)
      Body(.input(ParentDetail.self))
    }
  }
}

extension AuthedAdminRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .macOverview:
      let output = try await MacOverview.resolve(in: context)
      return try await self.respond(with: output)
    case .iOSOverview:
      let output = try await IOSOverview.resolve(in: context)
      return try await self.respond(with: output)
    case .podcastOverview:
      let output = try await PodcastOverview.resolve(in: context)
      return try await self.respond(with: output)
    case .parentsList(let input):
      let output = try await ParentsList.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .parentDetail(let input):
      let output = try await ParentDetail.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}
