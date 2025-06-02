import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL
import TaggedMoney

struct AnalyticsOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var overview: Overview
    var recentSignups: [RecentSignup]
  }
}

struct RecentSignup: Equatable, Sendable, Codable {
  var date: Date
  var status: ParentAnalyticsStatus
  var email: EmailAddress
}

enum ParentAnalyticsStatus: String, Codable {
  case noAction = "no_action"
  case onboarded
  case active
}

struct ParentData: Sendable {
  var id: Admin.Id
  var email: EmailAddress
  var numComputerUsers: Int
  var numChildren: Int
  var numNonEmptyKeychains: Int
  var numNotifications: Int
  var childActivityCount: Int
  var paidPrice: Cents<Int>?
  var subscriptionStatus: Admin.SubscriptionStatus
  var hasGclid: Bool
  var createdAt: Date

  init(model: Admin) {
    self.id = model.id
    self.email = model.email
    self.numComputerUsers = 0
    self.numChildren = 0
    self.numNonEmptyKeychains = 0
    self.numNotifications = 0
    self.childActivityCount = 0
    self.paidPrice = model.subscriptionStatus == .paid ? model.monthlyPrice : nil
    self.subscriptionStatus = model.subscriptionStatus
    self.hasGclid = model.gclid != nil
    self.createdAt = model.createdAt
  }
}

struct Overview: PairOutput {
  var annualRevenue: Dollars<Int>
  var payingParents: Int
  var activeParents: Int
  var childrenOfActiveParents: Int
  var allTimeSignups: Int
  var allTimeChildren: Int
  var allTimeAppInstallations: Int
}

struct AnalyticsData: Sendable {
  var parents: [Admin.Id: ParentData]
  var overview: Overview
}

@globalActor actor AnalyticsQuery {
  static let shared = AnalyticsQuery()
  private var _data: AnalyticsData?

  @Dependency(\.db) private var db
  @Dependency(\.logger) private var logger

  init() {}

  func data() async throws -> AnalyticsData {
    if let data = _data { return data }
    let data = try await self.queryFreshData()
    self._data = data
    return data
  }

  func queryFreshData() async throws -> AnalyticsData {
    self.logger.notice("Querying analytics data")
    let parentModels = try await Admin.query().all(in: self.db)

    let nonEmptyKeyChains = try await self.db.customQuery(NonEmptyKeychains.self)
    let keychainMap: [Admin.Id: [Int]] = nonEmptyKeyChains.reduce(into: [:]) { map, row in
      map[row.parentId, default: []].append(row.keyCount)
    }

    let notificationsCount = try await self.db.customQuery(NotificationsCount.self)
    let notificationsMap: [Admin.Id: Int] = notificationsCount.reduce(into: [:]) { map, row in
      map[row.parentId] = row.notificationsCount
    }

    let childCount = try await self.db.customQuery(ChildCount.self)
    let childMap: [Admin.Id: Int] = childCount.reduce(into: [:]) { map, child in
      map[child.parentId] = child.childCount
    }

    let computerUserCount = try await self.db.customQuery(ComputerUserCount.self)
    let computerUserMap: [Admin.Id: Int] = computerUserCount.reduce(into: [:]) { map, row in
      map[row.parentId] = row.computerUserCount
    }

    let activityCounts = try await self.db.customQuery(ActivityCounts.self)
    let activityMap: [Admin.Id: Int] = activityCounts.reduce(into: [:]) { map, row in
      map[row.parentId] = row.screenshotCount + row.keystrokeLineCount
    }

    var data = try await AnalyticsData(
      parents: [:],
      overview: .init(
        annualRevenue: 0,
        payingParents: 0,
        activeParents: 0,
        childrenOfActiveParents: 0,
        allTimeSignups: parentModels.count,
        allTimeChildren: User.query().count(in: self.db),
        allTimeAppInstallations: ComputerUser.query().count(in: self.db)
      )
    )
    var totalAnnualCents = Cents(0)
    var parents = parentModels.reduce(into: [Admin.Id: ParentData]()) { map, model in
      var parent = ParentData(model: model)
      parent.numNonEmptyKeychains = keychainMap[model.id]?.count ?? 0
      parent.numChildren = childMap[model.id] ?? 0
      parent.numNotifications = notificationsMap[model.id] ?? 0
      parent.numComputerUsers = computerUserMap[model.id] ?? 0
      parent.childActivityCount = activityMap[model.id] ?? 0
      if parent.isActive {
        data.overview.activeParents += 1
        data.overview.childrenOfActiveParents += parent.numChildren
      }
      map[parent.id] = parent
      if let paidPrice = parent.paidPrice {
        totalAnnualCents += paidPrice * 12
        data.overview.payingParents += 1
      }
    }
    data.overview.annualRevenue = Dollars(totalAnnualCents.rawValue / 100)

    let children = try await User.query().all(in: self.db)
    for child in children {
      guard var parent = parents[child.parentId] else { continue }
      parent.numChildren += 1
      parents[child.parentId] = parent
    }

    data.parents = parents
    self._data = data
    return data
  }
}

extension ParentData {
  var isActive: Bool {
    self.numComputerUsers > 0
      && self.numNotifications > 0
      && (self.numNonEmptyKeychains > 0 || self.childActivityCount > 0)
  }

  var status: ParentAnalyticsStatus {
    if self.isActive {
      .active
    } else if self.numComputerUsers > 0 {
      .onboarded
    } else {
      .noAction
    }
  }

  var recentSignup: RecentSignup {
    .init(
      date: self.createdAt,
      status: self.status,
      email: self.email
    )
  }
}

extension AnalyticsOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let data = try await AnalyticsQuery.shared.data()
    return .init(
      overview: data.overview,
      recentSignups: data.parents.values.map(\.recentSignup)
    )
  }
}

// custom queries

struct NonEmptyKeychains: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT kc.parent_id, COUNT(k.id) AS key_count
    FROM keychains kc
    LEFT JOIN keys k ON k.keychain_id = kc.id
    WHERE kc.is_public = false
    GROUP BY kc.id, kc.parent_id
    HAVING COUNT(k.id) > 0;
    """)
  }

  var parentId: Admin.Id
  var keyCount: Int
}

struct ChildCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT p.id AS parent_id, COUNT(c.id) AS child_count
    FROM parents p
    LEFT JOIN children c ON c.parent_id = p.id
    GROUP BY p.id;
    """)
  }

  var parentId: Admin.Id
  var childCount: Int
}

struct NotificationsCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT p.id AS parent_id, COUNT(c.id) AS notifications_count
    FROM parents p
    LEFT JOIN notifications c ON c.parent_id = p.id
    GROUP BY p.id;
    """)
  }

  var parentId: Admin.Id
  var notificationsCount: Int
}

struct ComputerUserCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    SELECT p.id AS parent_id, COUNT(DISTINCT cu.id) AS computer_user_count
    FROM parents p
    JOIN computers c ON c.parent_id = p.id
    JOIN computer_users cu ON cu.computer_id = c.id
    GROUP BY p.id;
    """)
  }

  var parentId: Admin.Id
  var computerUserCount: Int
}

struct ActivityCounts: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    .init("""
    WITH ss_counts AS (
      SELECT cu.computer_id, COUNT(*) AS screenshot_count
      FROM screenshots ss
      JOIN computer_users cu ON ss.computer_user_id = cu.id
      GROUP BY cu.computer_id
    ),
    kl_counts AS (
      SELECT cu.computer_id, COUNT(*) AS keystroke_line_count
      FROM keystroke_lines kl
      JOIN computer_users cu ON kl.computer_user_id = cu.id
      GROUP BY cu.computer_id
    )
    SELECT p.id AS parent_id,
           COALESCE(SUM(ss.screenshot_count), 0)::int AS screenshot_count,
           COALESCE(SUM(kl.keystroke_line_count), 0)::int AS keystroke_line_count
    FROM parents p
    JOIN computers c ON c.parent_id = p.id
    LEFT JOIN ss_counts ss ON ss.computer_id = c.id
    LEFT JOIN kl_counts kl ON kl.computer_id = c.id
    GROUP BY p.id;
    """)
  }

  var parentId: Admin.Id
  var screenshotCount: Int
  var keystrokeLineCount: Int
}
