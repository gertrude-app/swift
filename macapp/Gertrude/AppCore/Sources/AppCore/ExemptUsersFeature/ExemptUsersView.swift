import SwiftUI

struct ExemptUsersView: View, StoreView {
  @EnvironmentObject var store: AppStore

  var state: AdminWindowState.ExemptUsersState { store.state.adminWindow.exemptUsersState }

  var body: some View {
    AdminWindowSubScreen(section: .exemptUsers) {
      if store.state.filterState == .off {
        InfoNotice(FILTER_OFF_MSG).centered().offset(y: -20)
      } else if state.users.count == 1 {
        InfoNotice(ONE_USER_MSG).centered().offset(y: -20)
      } else if state.exemptUsers == nil {
        Submitting("Loading...").centered()
      } else {
        VStack(alignment: .leading, spacing: 20) {
          Markdown(FEATURE_EXPLANATION).lineSpacing(4).opacity(0.85)
          Markdown(PASSWORD_WARNING).lineSpacing(4).opacity(0.85)
          if let error = state.errorMsg {
            HStack {
              Spacer()
              Text(error)
                .padding(x: 9, y: 3)
                .background(red)
                .foregroundColor(.white)
                .cornerRadius(8)
              Spacer()
            }
          }
          Form {
            ForEach(state.users.filter { $0 != state.currentUser }) { user in
              Toggle(isOn: Binding(
                get: { state.exemptUsers?.contains(user) ?? false },
                set: { isOn in
                  if isOn {
                    Auth.challengeAdmin { isAdmin in
                      store.send(.exemptUser(.setUserExempt(user, isAdmin)))
                    }
                  } else {
                    store.send(.exemptUser(.setUserExempt(user, false)))
                  }
                }
              )) {
                Group {
                  if state.exemptUsers?.contains(user) ?? false {
                    Text(user.name)
                      .bold() +
                      Text(" (exempt from filtering - unrestricted internet access)")
                      .italic()
                      .foregroundColor(red)
                  } else {
                    Text(user.name)
                  }
                }
                .padding(left: 3)
              }
            }
          }
          .padding(left: 20)
          .accentColor(red)
        }
        Spacer()
        HStack {
          Spacer()
          Button("Administrate user accounts →") {
            store.send(.openSystemPrefs(.accounts))
          }
          .buttonStyle(.link)
          .padding(top: 10)
        }
      }
    }
    .onAppear {
      store.send(.exemptUser(.viewDidAppear))
    }
  }
}

struct InfoNotice: View {
  var text: String

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    HStack(alignment: .top, spacing: 15) {
      Image(systemName: "info.circle")
        .resizable()
        .frame(width: 25, height: 25)
        .padding(top: 3)
      Markdown(text)
        .italic()
        .lineSpacing(5)
        .frame(maxWidth: 400)
    }
  }
}

struct ExemptUsersView_Previews: PreviewProvider, GertrudeProvider {
  static var cases: [StateCustomizer] = [
    // loaded state, w/ multiple users (light & dark)
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
    { state in
      state.colorScheme = .dark
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

    // loading state
    { state in
      state.colorScheme = .light
      state.filterStatus = .installedAndRunning
      state.adminWindow = .exemptUsers(.init(
        exemptUsers: nil, // <-- LOADING exempt users
        users: [],
        currentUser: .init(id: 502, name: "Ezra")
      ))
    },

    // ERROR state
    { state in
      state.colorScheme = .light
      state.filterStatus = .installedAndRunning
      state.adminWindow = .exemptUsers(.init(
        exemptUsers: [.init(id: 501, name: "Joe Admin")],
        users: [
          .init(id: 501, name: "Joe Admin"),
          .init(id: 502, name: "Ezra"),
        ],
        currentUser: .init(id: 502, name: "Ezra"),
        errorMsg: "Something went wrong, please try again, or contact support for additional help."
      ))
    },

    // filter OFF state
    { state in
      state.colorScheme = .light
      state.filterStatus = .notInstalled
    },
    { state in
      state.colorScheme = .dark
      state.filterStatus = .notInstalled
    },

    // only one user
    { state in
      state.colorScheme = .light
      state.filterStatus = .installedAndRunning
      state.adminWindow = .exemptUsers(.init(
        users: [
          .init(id: 501, name: "Ezra"),
        ],
        currentUser: .init(id: 501, name: "Ezra")
      ))
    },
  ]

  static var previews: some View {
    ForEach(allPreviews) {
      ExemptUsersView()
        .store($0)
        .adminPreview()
    }
  }
}

private var FILTER_OFF_MSG = """
Filter is currently **OFF**. \
User exemptions prevent the filter from blocking from other users \
(like a parent's admin account on a shared computer), therefore they \
are **not applicable** when the filter is not running.
"""

private var ONE_USER_MSG = """
This computer currently only has **a single user**. \
User exemptions prevent the filter from blocking from _other users_ \
(like a parent's admin account on a shared computer), therefore they \
are **not applicable** when there is only a single user.
"""

private var FEATURE_EXPLANATION = """
Gertrude's network filter has to make decisions about whether to \
allow or deny network requests from _every user_ on this computer. \
For maximum internet safety, it defaults to _blocking all requests_ \
for users that it doesn't have rules for. If this computer has \
another user or users who should have _unrestricted internet access_ \
(like a parent's admin account on a shared computer), you can make \
that user **exempt from filtering** by selecting the user name below.
"""

private var PASSWORD_WARNING = """
**Please note:** any user that is exempt from filtering should have \
a _password enabled that is unknown to any individual subject to filtering,_ \
or else they would be able to log in to that user at any time and \
also have unrestricted internet access.
"""
