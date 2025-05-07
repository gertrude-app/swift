import IOSRoute

extension CreateSuspendFilterRequest: Resolver {
  static func resolve(
    with input: Input,
    in context: IOSApp.ChildContext
  ) async throws -> Output {
    let req = try await context.db.create(IOSApp.SuspendFilterRequest(
      deviceId: context.device.id,
      status: .pending,
      duration: input.duration,
      requestComment: input.comment
    ))
    await with(dependency: \.adminNotifier).notify(
      context.child.parentId,
      .suspendFilterRequestSubmitted(.init(
        dashboardUrl: context.dashboardUrl,
        childId: context.child.id,
        childName: context.child.name,
        duration: input.duration,
        requestComment: input.comment,
        context: .iosapp(deviceId: context.device.id, requestId: req.id)
      ))
    )
    return req.id.rawValue
  }
}
