import Dependencies
import DuetSQL
import Gertie

func dashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ detail: String? = nil,
  parent parentId: Parent.Id,
  in context: Context
) {
  dashSecurityEvent(
    event,
    parentId,
    context.ipAddress,
    detail,
    with: context.db
  )
}

func dashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ detail: String? = nil,
  in context: ParentContext
) {
  dashSecurityEvent(
    event,
    context.parent.id,
    context.ipAddress,
    detail,
    with: context.db
  )
}

private func dashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ parentId: Parent.Id,
  _ ipAddress: String? = nil,
  _ detail: String? = nil,
  with db: any DuetSQL.Client
) {
  Task {
    try? await db.create(Api.SecurityEvent(
      // opt out of using the controlled uuid dependency
      // as the unstructured task causes test flakiness
      id: .init(UUID()),
      parentId: parentId,
      event: event.rawValue,
      detail: detail,
      ipAddress: ipAddress
    ))
  }
}
