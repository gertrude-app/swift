public extension FilterDecision {
  var logMeta: Log.Meta {
    [
      "filter_decision": true,
      "filter_decision.verdict": .string(verdict.rawValue),
      "filter_decision.reason": .string(reason.rawValue),
      "filter_decision.bundle_id": .init(bundleId),
      "filter_decision.responsible_key_id": .init(responsibleKeyId?.uuidString),
      "filter_decision.app_descriptor": .init(app?.description),
      "filter_decision.target": .init(target),
      "filter_decision.ip_protocol": .init(ipProtocol?.shortDescription),
      "filter_decision.hostname": .init(hostname),
      "filter_decision.ip_address": .init(ipAddress),
      "filter_decision.url": .init(url),
      "filter_decision.description": .string(description),
    ]
  }
}
