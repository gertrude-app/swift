import Gertie

func dashSecurityEvent(
  _ event: Gertie.SecurityEvent.Dashboard,
  _ adminId: Admin.Id,
  _ ipAddress: String? = nil,
  _ detail: String? = nil
) {
  Task {
    try? await Api.SecurityEvent(
      adminId: adminId,
      event: event.rawValue,
      detail: detail,
      ipAddress: ipAddress
    ).create()
  }
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
    detail
  )
}
