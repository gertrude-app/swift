import Dependencies
import DuetSQL
import Gertie

func dashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ detail: String? = nil,
  admin adminId: Admin.Id,
  in context: Context
) {
  dashSecurityEvent(
    event,
    adminId,
    context.ipAddress,
    detail,
    with: context.db
  )
}

func dashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ detail: String? = nil,
  in context: AdminContext
) {
  dashSecurityEvent(
    event,
    context.admin.id,
    context.ipAddress,
    detail,
    with: context.db
  )
}

private func dashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ adminId: Admin.Id,
  _ ipAddress: String? = nil,
  _ detail: String? = nil,
  with db: any DuetSQL.Client
) {
  Task {
    try? await db.create(Api.SecurityEvent(
      adminId: adminId,
      event: event.rawValue,
      detail: detail,
      ipAddress: ipAddress
    ))
  }
}
