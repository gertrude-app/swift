import NetworkExtension
import SystemExtensions

extension FilterManager: OSSystemExtensionRequestDelegate {
  func request(
    _ request: OSSystemExtensionRequest,
    didFinishWithResult result: OSSystemExtensionRequest.Result
  ) {
    guard result == .completed else {
      print("system extension request finished not completed")
      Task { @MainActor in
        await activationRequest.setValue(.failed)
      }
      return
    }

    print("system extension request finished successfully")
    Task { @MainActor in
      await activationRequest.setValue(.succeeded)
    }
  }

  func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
    print("system extension request needs user approval")
  }

  func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
    print("system extension request failed w/ error: \(error)")
    // filterController.status = .error
  }

  func request(
    _ request: OSSystemExtensionRequest,
    actionForReplacingExtension existing: OSSystemExtensionProperties,
    withExtension extension: OSSystemExtensionProperties
  ) -> OSSystemExtensionRequest.ReplacementAction {
    let old = existing.bundleShortVersion
    let new = `extension`.bundleShortVersion
    print("system extension request replacing \(old) with \(new)")
    return .replace
  }
}
