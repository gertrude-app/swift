import Dependencies
import DuetSQL
import Foundation
import Gertie
import Queues
import Vapor
import XCore

enum SubscriptionEmail: Equatable {
  case trialEndingSoon(length: Int, remaining: Int)
  case trialEndedToOverdue(length: Int)
  case overdueToUnpaid
  case paidToOverdue
  case unpaidToPendingDelete
  case deleteEmailUnverified
}

struct SubscriptionUpdate: Equatable {
  enum Action: Equatable {
    case update(status: Parent.SubscriptionStatus, expiration: Date)
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
    let parents = try await Parent.query().all(in: self.db)
    for var parent in parents {
      guard let update = try await self.subscriptionUpdate(for: parent) else {
        continue
      }

      switch update.action {

      case .update(let status, let expiration):
        parent.subscriptionStatus = status
        parent.subscriptionStatusExpiration = expiration
        try await self.db.update(parent)
        logs.append("Updated admin \(parent.email) to `.\(status)` until \(expiration)")

      case .delete(let reason):
        try await self.db.create(DeletedEntity(
          type: "Admin",
          reason: reason,
          data: JSON.encode(parent, [.isoDates])
        ))
        try await self.db.delete(parent)
        logs.append("Deleted admin \(parent.email) reason: \(reason)")
      }

      if let event = update.email {
        try await self.postmark.send(template: email(event, to: parent.email))
        logs.append("Sent `.\(event)` email to admin \(parent.email)")
      }
    }

    if self.env.mode == .prod, !logs.isEmpty {
      self.postmark.toSuperAdmin(
        "Gertrude subscription manager events",
        "<ol><li>" + logs.joined(separator: "</li><li>") + "</li></ol>"
      )
    }
  }

  func subscriptionUpdate(for parent: Parent) async throws -> SubscriptionUpdate? {
    if parent.subscriptionStatusExpiration > self.now {
      return nil
    }

    let completedOnboarding = try await parent.completedOnboarding(self.db)
    switch parent.subscriptionStatus {

    case .pendingEmailVerification:
      return .init(
        action: .delete(reason: "email never verified"),
        email: .deleteEmailUnverified
      )

    case .trialing where parent.trialPeriodDays == 60: // <-- legacy 60-day trial
      return .init(
        action: .update(
          status: .trialExpiringSoon,
          expiration: self.now + .days(7)
        ),
        email: .trialEndingSoon(length: parent.trialPeriodDays, remaining: 7)
      )

    case .trialing:
      return .init(
        action: .update(
          status: .trialExpiringSoon,
          expiration: self.now + .days(3)
        ),
        email: .trialEndingSoon(length: parent.trialPeriodDays, remaining: 3)
      )

    case .trialExpiringSoon:
      return .init(
        action: .update(status: .overdue, expiration: self.now + .days(7)),
        email: completedOnboarding ? .trialEndedToOverdue(length: parent.trialPeriodDays) : nil
      )

    case .overdue:
      return try await self.updateIfPaid(parent.subscriptionId) ?? .init(
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
      return try await self.updateIfPaid(parent.subscriptionId) ?? .init(
        action: .update(status: .overdue, expiration: self.now + .days(14)),
        email: .paidToOverdue
      )

    case .complimentary:
      unexpected("2d1710c2", parent.id)
      return nil
    }
  }

  // failsafe in case webhook missed the `invoice.paid` event
  // theoretically, we should never find a subscription active
  private func updateIfPaid(
    _ subscriptionId: Parent.SubscriptionId?
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

private extension Parent {
  func completedOnboarding(_ db: any DuetSQL.Client) async throws -> Bool {
    let children = try await children(in: db)
    let childDevices = try await children.concurrentMap {
      try await $0.computerUsers(in: db)
    }.flatMap(\.self)
    return !childDevices.isEmpty
  }
}

func email(_ event: SubscriptionEmail, to address: EmailAddress) -> TemplateEmail {
  switch event {
  case .trialEndingSoon(let length, let remaining):
    .trialEndingSoon(
      to: address.rawValue,
      model: .init(length: length, remaining: remaining)
    )
  case .trialEndedToOverdue(let length):
    .trialEndedToOverdue(to: address.rawValue, model: .init(length: length))
  case .overdueToUnpaid:
    .overdueToUnpaid(to: address.rawValue, model: .init())
  case .paidToOverdue:
    .paidToOverdue(to: address.rawValue, model: .init())
  case .unpaidToPendingDelete:
    .unpaidToPendingDelete(to: address.rawValue, model: .init())
  case .deleteEmailUnverified:
    .deleteEmailUnverified(to: address.rawValue, model: .init())
  }
}
