import ComposableArchitecture
import Core
import TestSupport
import XCore
import XCTest
import XExpect

@testable import App

@MainActor final class RequestSuspensionFeatureTests: XCTestCase {
  func testFilterCommunicationConfirmationSucceeded() async {
    let (store, _) = AppReducer.testStore {
      $0.requestSuspension.filterCommunicationConfirmed = false // <-- prove nilling out
    }

    // can't connect, or repair connection
    store.deps.filterXpc.checkConnectionHealth = { .success(()) }

    await store.send(.menuBar(.suspendFilterClicked)) {
      $0.requestSuspension.filterCommunicationConfirmed = nil // <-- nils out for fresh confirmation
      $0.requestSuspension.windowOpen = true
    }

    await store.receive(.requestSuspension(.receivedFilterCommunicationConfirmation(true))) {
      $0.requestSuspension.filterCommunicationConfirmed = true
    }
  }

  func testFilterCommunicationConfirmationFailed() async {
    let (store, _) = AppReducer.testStore {
      $0.requestSuspension.filterCommunicationConfirmed = true
    }

    // can't connect, or repair connection
    store.deps.filterXpc.checkConnectionHealth = { .failure(.unknownError("???")) }
    store.deps.filterXpc.establishConnection = { .failure(.unknownError("???")) }

    await store.send(.menuBar(.suspendFilterClicked)) {
      $0.requestSuspension.filterCommunicationConfirmed = nil // <-- nils out for fresh confirmation
      $0.requestSuspension.windowOpen = true
    }

    await store.receive(.requestSuspension(.receivedFilterCommunicationConfirmation(false))) {
      $0.requestSuspension.filterCommunicationConfirmed = false
    }
  }

  func testClickingAdministrateFromFilterCommFailureOpensAdmin() async {
    let (store, _) = AppReducer.testStore {
      $0.adminWindow.windowOpen = false
      $0.requestSuspension.windowOpen = true
    }

    await store
      .send(.adminAuthed(.requestSuspension(.webview(.noFilterCommunicationAdministrateClicked)))) {
        $0.adminWindow.windowOpen = true
        $0.adminWindow.screen = .healthCheck
        $0.requestSuspension.windowOpen = false
      }
  }
}
