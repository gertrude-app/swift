import Foundation
import Shared
import SharedCore
import SwiftUI

struct AdminSectionView: View {
  var section: AdminScreenSection

  var body: some View {
    Group {
      switch section {
      case .healthCheck:
        HealthCheckView()
      case .exemptUsers:
        ExemptUsersView()
      case .actions:
        AdminActionsView()
      }
    }
  }
}

struct MainAdminScreen: View, StoreView {
  @EnvironmentObject var store: AppStore

  var body: some View {
    AccountStatusAware {
      NavigationView {
        List([
          AdminScreenSection.healthCheck,
          AdminScreenSection.actions,
          AdminScreenSection.exemptUsers,
        ]) { section in
          NavigationLink(
            destination: AdminSectionView(section: section),
            tag: section,
            selection: store.bind(\.adminWindow.section, .setAdminViewSection(section))
          ) {
            Label(section.rawValue, systemImage: section.systemImage)
          }
          .accentColor(.brandPurple)
        }
        .listStyle(SidebarListStyle())
        .frame(width: 160)
      }
    }
  }
}

struct MainAdminScreen_Previews: PreviewProvider, GertrudeProvider {
  static var cases: [StateCustomizer] = [
    { state in
      state.filterStatus = .installedAndRunning
      state.accountStatus = .needsAttention
      state.colorScheme = .light
    },
    { state in
      state.colorScheme = .dark
    },
    { state in
      state.colorScheme = .light
      state.filterStatus = .installedAndRunning
      state.adminWindow = .exemptUsers(.init(
        exemptUsers: [.init(id: 501, name: "Joe Admin")],
        users: [
          .init(id: 501, name: "Joe Admin"),
          .init(id: 502, name: "Ezra"),
          .init(id: 503, name: "Kiah"),
          .init(id: 504, name: "Harriet"),
        ],
        currentUser: .init(id: 502, name: "Ezra")
      ))
    },
  ]

  static var previews: some View {
    ForEach(allPreviews) {
      MainAdminScreen().store($0).adminPreview()
    }
  }
}
