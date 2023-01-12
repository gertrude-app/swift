import Foundation
import SharedCore
import SystemExtensions

class FilterActivationRequestDelegate: NSObject, OSSystemExtensionRequestDelegate {
  var filterController: FilterController

  init(filterController: FilterController) {
    self.filterController = filterController
  }

  func request(
    _ request: OSSystemExtensionRequest,
    didFinishWithResult result: OSSystemExtensionRequest.Result
  ) {
    guard result == .completed else {
      log(.systemExtensionRequestDelegate(.error("request finished !.completed", nil)))
      filterController.status = .error
      return
    }

    log(.systemExtensionRequestDelegate(.notice("request finished .completed")))
    filterController.enableFilterConfiguration()
  }

  func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
    log(.systemExtensionRequestDelegate(.notice("request needs user approval")))
  }

  func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
    log(.systemExtensionRequestDelegate(.error("request failed", error)))
    filterController.status = .error
  }

  func request(
    _ request: OSSystemExtensionRequest,
    actionForReplacingExtension existing: OSSystemExtensionProperties,
    withExtension extension: OSSystemExtensionProperties
  ) -> OSSystemExtensionRequest.ReplacementAction {
    let old = existing.bundleShortVersion
    let new = `extension`.bundleShortVersion
    log(.systemExtensionRequestDelegate(.level(.notice, "replaced extension", [
      "meta.primary": .string("\(old) -> \(new)"),
    ])))
    return .replace
  }
}
