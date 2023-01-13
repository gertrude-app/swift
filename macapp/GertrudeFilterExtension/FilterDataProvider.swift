import FilterCore
import NetworkExtension
import Shared
import SharedCore
import XCore

class FilterDataProvider: NEFilterDataProvider {
  private(set) static var instance: FilterDataProvider?
  private var exemptedUsers: Set<uid_t>?
  private var userIdMap: [UUID: uid_t] = [:]
  static var decisions = DecisionBag()
  var decisionMaker = FilterDecisionMaker()
  var auditor: SourceAppAuditor = CachingSourceAppAuditor()

  override init() {
    super.init()
    Self.instance = self
    loadExemptedUserList()
    FilterStorage.loadIdManifest()
    FilterStorage.getUsersWithKeys().forEach { userId in
      FilterStorage.loadKeys(forUserWithId: userId)
    }
    Current.logger = FilterLogger()
  }

  func loadExemptedUserList() {
    exemptedUsers = FilterStorage.getExemptedUserIds()
  }

  override func startFilter(completionHandler: @escaping (Error?) -> Void) {
    log(.filterDataProvider(.filterStarted))
    let networkRule = NENetworkRule(
      remoteNetwork: nil,
      remotePrefix: 0,
      localNetwork: nil,
      localPrefix: 0,
      protocol: .any,
      direction: .outbound
    )

    let filterRule = NEFilterRule(networkRule: networkRule, action: .filterData)
    let filterSettings = NEFilterSettings(rules: [filterRule], defaultAction: .allow)

    apply(filterSettings) { error in
      log(.filterDataProvider(.error("error applying filter settings", error)))
      completionHandler(error)
    }
  }

  override func stopFilter(
    with reason: NEProviderStopReason,
    completionHandler: @escaping () -> Void
  ) {
    log(.filterDataProvider(.filterStopped))
    Current.logger.flush()
    completionHandler()
  }

  override func handleOutboundData(
    from rawFlow: NEFilterFlow,
    readBytesStartOffset offset: Int,
    readBytes: Data
  ) -> NEFilterDataVerdict {
    var userId = userIdMap.removeValue(forKey: rawFlow.identifier)
    if userId == nil {
      userId = auditor.userId(fromAuditToken: rawFlow.sourceAppAuditToken)
    }

    var flow = SharedCore.FilterFlow(rawFlow, userId: userId)
    if flow.url == nil {
      let bytes = bytesToString(readBytes)
      flow.parseOutboundData(byteString: bytes)
    }

    let decision = decisionMaker.make(fromCompletedFlow: flow)
    saveDecisionForTransmission(decision)

    debug(.filterDecision(.made(.afterSeeingOutboundData(
      decisionDebugMeta(decision, userId, rawFlow),
      bytesToString(readBytes)
    ))))

    // prevent a memory leak
    if userIdMap.count > 100 {
      userIdMap = [:]
    }

    switch decision.verdict {
    case .allow:
      return .allow()
    default:
      return .drop()
    }
  }

  override func handleNewFlow(_ rawFlow: NEFilterFlow) -> NEFilterNewFlowVerdict {
    let userId = auditor.userId(fromAuditToken: rawFlow.sourceAppAuditToken)
    let userIdDecision = decisionMaker.make(userId: userId, exemptedUsers: exemptedUsers)

    if let userDec = userIdDecision {
      switch (userDec.verdict, userDec.reason) {
      case (.allow, .systemUser):
        debug(.filterDecision(.made(.earlyFromUserId(
          .allowSystemUser(decisionDebugMeta(userDec, userId, rawFlow))
        ))))
        return .allow()

      case (.allow, .userIsExempt):
        debug(.filterDecision(.made(.earlyFromUserId(
          .allowExemptUser(decisionDebugMeta(userDec, userId, rawFlow))
        ))))
        return .allow()

      case (.allow, .filterSuspended):
        saveDecisionForTransmission(userDec)
        debug(.filterDecision(.made(.earlyFromUserId(
          .filterSuspended(decisionDebugMeta(userDec, userId, rawFlow))
        ))))
        return .allow()

      case (.block, .missingUserId):
        saveDecisionForTransmission(userDec)
        debug(.filterDecision(.made(.earlyFromUserId(
          .unexpectedMissingUserId(decisionDebugMeta(userDec, userId, rawFlow))
        ))))
        return .drop()

      default:
        debug(.filterDecision(.made(.earlyFromUserId(
          .unexpectedCondition(decisionDebugMeta(userDec, userId, rawFlow))
        ))))
        saveDecisionForTransmission(userDec)
        return .drop()
      }
    }

    let flow = FilterFlow(rawFlow, userId: userId)

    #if DEBUG
      if flow.hostname == "timestamp.apple.com",
         flow.bundleId == ".com.apple.security.XPCTimeStampingService",
         isDev() {
        log(.filterDecision(.devOnlyXcodeBuildRequestAllowed))
        return .allow()
      }
    #endif

    guard let decision = decisionMaker.make(fromFlow: flow) else {
      debug(.filterDecision(.deferred(decisionDebugMeta(nil, userId, rawFlow))))
      userIdMap[rawFlow.identifier] = userId
      return .filterDataVerdict(
        withFilterInbound: false,
        peekInboundBytes: Int.max,
        filterOutbound: true,
        peekOutboundBytes: 250
      )
    }

    debug(.filterDecision(.made(.beforeSeeingOutboundData(decisionDebugMeta(
      decision,
      userId,
      rawFlow
    )))))
    saveDecisionForTransmission(decision)

    switch decision.verdict {
    case .allow:
      return .allow()
    case .block:
      return .drop()
    }
  }

  private func saveDecisionForTransmission(_ decision: FilterDecision) {
    Self.decisions.push(decision)
    if Self.decisions.count >= TRANSMIT_DECISIONS_THRESHOLD {
      SendToApp.recentFilterDecisions(Self.decisions.flushRecentFirst())
    }
  }

  private func decisionDebugMeta(
    _ decision: FilterDecision?,
    _ userId: uid_t?,
    _ flow: NEFilterFlow
  ) -> Log.Meta {
    decision?.logMeta + [
      "filter_decision.raw_flow_description": .string(flow.description),
      "filter_decision.raw_flow_identifier": .string(flow.identifier.uuidString),
      "filter_decision.suspension_data": .string(decisionMaker.suspensions.debugData),
      "filter_decision.user_id": .string(userId.map { "\($0)" } ?? "(nil)"),
      "filter_decision.exempt_users": .init(
        exemptedUsers
          .map { $0.map { "\($0)" }}?
          .sorted()
          .joined(separator: ",")
      ),
    ]
  }
}

// helpers

private let TRANSMIT_DECISIONS_THRESHOLD = 250

private func bytesToString(_ bytes: Data) -> String {
  var str = ""
  bytes.forEach { byte in
    switch byte {
    // ascii characters possible in hostname
    case 45 ... 57, 61, 63, 65 ... 90, 95, 97 ... 122:
      str += String(Character(UnicodeScalar(byte)))
    default:
      str += "•"
    }
  }
  return str
}
