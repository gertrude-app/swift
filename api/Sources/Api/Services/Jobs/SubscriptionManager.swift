import Dependencies
import DuetSQL
import Foundation
import Gertie
import Queues
import Vapor
import XCore

enum SubscriptionEmail: Equatable {
  case trialEndingSoon
  case trialEndedToOverdue
  case overdueToUnpaid
  case paidToOverdue
  case unpaidToPendingDelete
  case deleteEmailUnverified
}

struct SubscriptionUpdate: Equatable {
  enum Action: Equatable {
    case update(status: Admin.SubscriptionStatus, expiration: Date)
    case delete(reason: String)
  }

  var action: Action
  var email: SubscriptionEmail?
}

struct SubscriptionManager: AsyncScheduledJob {
  @Dependency(\.stripe) var stripe
  @Dependency(\.env) var env
  @Dependency(\.db) var db
  @Dependency(\.date.now) var now
  @Dependency(\.postmark) var postmark

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    try await self.advanceExpired()
  }

  func advanceExpired() async throws {
    var logs: [String] = []
    let admins = try await Admin.query().all(in: self.db)
    for var admin in admins {
      guard let update = try await self.subscriptionUpdate(for: admin) else {
        continue
      }

      switch update.action {

      case .update(let status, let expiration):
        admin.subscriptionStatus = status
        admin.subscriptionStatusExpiration = expiration
        try await self.db.update(admin)
        logs.append("Updated admin \(admin.email) to `.\(status)` until \(expiration)")

      case .delete(let reason):
        try await self.db.create(DeletedEntity(
          type: "Admin",
          reason: reason,
          data: try JSON.encode(admin, [.isoDates])
        ))
        try await self.db.delete(admin)
        logs.append("Deleted admin \(admin.email) reason: \(reason)")
      }

      if let event = update.email {
        try await self.postmark.send(template: email(event, to: admin.email))
        logs.append("Sent `.\(event)` email to admin \(admin.email)")
      }
    }

    if self.env.mode == .prod, !logs.isEmpty {
      self.postmark.toSuperAdmin(
        "Gertrude subscription manager events",
        "<ol><li>" + logs.joined(separator: "</li><li>") + "</li></ol>"
      )
    }
  }

  func subscriptionUpdate(for admin: Admin) async throws -> SubscriptionUpdate? {
    if admin.subscriptionStatusExpiration > self.now {
      return nil
    }

    let completedOnboarding = try await admin.completedOnboarding(self.db)
    switch admin.subscriptionStatus {

    case .pendingEmailVerification:
      return .init(
        action: .delete(reason: "email never verified"),
        email: .deleteEmailUnverified
      )

    case .trialing:
      return .init(
        action: .update(
          status: .trialExpiringSoon,
          expiration: self.now + .days(7)
        ),
        // NB: trial ending soon email is ALWAYS sent, regardless of onboarding status
        // but if they have never onboarded, it will be the only email they receive
        email: .trialEndingSoon
      )

    case .trialExpiringSoon:
      return .init(
        action: .update(status: .overdue, expiration: self.now + .days(14)),
        email: completedOnboarding ? .trialEndedToOverdue : nil
      )

    case .overdue:
      return try await self.updateIfPaid(admin.subscriptionId) ?? .init(
        action: .update(status: .unpaid, expiration: self.now + .days(365)),
        email: completedOnboarding ? .overdueToUnpaid : nil
      )

    case .pendingAccountDeletion:
      return .init(
        action: .delete(reason: "account unpaid > 1yr"),
        email: nil
      )

    case .unpaid:
      return .init(
        action: .update(
          status: .pendingAccountDeletion,
          expiration: self.now + .days(30)
        ),
        email: completedOnboarding ? .unpaidToPendingDelete : nil
      )

    case .paid:
      return try await self.updateIfPaid(admin.subscriptionId) ?? .init(
        action: .update(status: .overdue, expiration: self.now + .days(14)),
        email: .paidToOverdue
      )

    case .complimentary:
      unexpected("2d1710c2", admin.id)
      return nil
    }
  }

  // failsafe in case webhook missed the `invoice.paid` event
  // theoretically, we should never find a subscription active
  private func updateIfPaid(
    _ subscriptionId: Admin.SubscriptionId?
  ) async throws -> SubscriptionUpdate? {
    if let subsId = subscriptionId?.rawValue,
       let subscription = try? await self.stripe.getSubscription(subsId),
       subscription.status == .active {
      return .init(
        action: .update(
          status: .paid,
          expiration: Date(timeIntervalSince1970: TimeInterval(subscription.currentPeriodEnd))
            .advanced(by: .days(2)) // +2 days is for a little leeway, recommended by stripe docs
        ),
        email: nil
      )
    }
    return nil
  }
}

// helpers

private extension Admin {
  func completedOnboarding(_ db: any DuetSQL.Client) async throws -> Bool {
    let children = try await users(in: db)
    let childDevices = try await children.concurrentMap {
      try await $0.devices(in: db)
    }.flatMap { $0 }
    return !childDevices.isEmpty
  }
}

func email(_ event: SubscriptionEmail, to address: EmailAddress) -> TemplateEmail {
  switch event {
  case .trialEndingSoon:
    return .trialEndingSoon(to: address.rawValue, model: .init())
  case .trialEndedToOverdue:
    return .trialEndedToOverdue(to: address.rawValue, model: .init())
  case .overdueToUnpaid:
    return .overdueToUnpaid(to: address.rawValue, model: .init())
  case .paidToOverdue:
    return .paidToOverdue(to: address.rawValue, model: .init())
  case .unpaidToPendingDelete:
    return .unpaidToPendingDelete(to: address.rawValue, model: .init())
  case .deleteEmailUnverified:
    return .deleteEmailUnverified(to: address.rawValue, model: .init())
  }
}
