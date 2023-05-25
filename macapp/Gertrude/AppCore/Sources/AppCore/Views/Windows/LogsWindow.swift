import Gertie
import SharedCore
import SwiftUI

struct LogsWindow: View, StoreView {
  static let MIN_WIDTH: CGFloat = 900
  static let MIN_HEIGHT: CGFloat = 500

  @EnvironmentObject var store: AppStore
  @State private var filterText = ""
  @State private var selected: IdentifiedLog?

  var logs: [IdentifiedLog] {
    store.state.loggingWindow.logs.reversed().filter { log in
      if filterText.isEmpty {
        return true
      }

      return log.messageAndMeta.lowercased().contains(filterText.lowercased())
    }
  }

  func iconData(for log: Log.Message) -> (name: String, color: Color, offset: CGFloat) {
    var name = "info.circle.fill"
    var color = Color.blue
    var offset: CGFloat = 0
    if log.level == .error {
      name = "xmark.octagon.fill"
      color = red
    } else if log.meta["filter_decision.verdict"] == "block" {
      name = "lock.fill"
      color = .orange
    } else if log.meta["filter_decision.verdict"] == "allow" {
      name = "lock.open.fill"
      color = .green
      offset = 2
    }
    return (name: name, color: color, offset: offset)
  }

  var logsTable: some View {
    List(logs.indexed) { indexed in
      let log = indexed.identified
      let (iconName, iconColor, iconOffset) = iconData(for: log)
      HStack(spacing: 12) {
        Image(systemName: iconName)
          .resizable()
          .scaledToFit()
          .frame(width: 15, height: 15)
          .foregroundColor(iconColor)
          .offset(x: iconOffset)
          .opacity(0.8)
          .padding(right: 2)
        Text(log.conciseTime)
          .foregroundColor(.secondary)
          .font(.system(size: 12, weight: .thin, design: .monospaced))
        Text(log.enhancedMessage)
          .font(.system(size: 12, weight: .regular, design: .monospaced))
          .foregroundColor(log.level == .error ? red : .primary)
        Spacer()
      }
      .padding(x: 6, y: 5)
      .background(bandedRowBg(selected: false, alt: indexed.index % 2 == 0))
      .frame(height: 18)
      .onTapGesture {
        selected = indexed.indexed
        copyToClipboard("\(log.conciseTime) \(log.messageAndMeta)")
      }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 20) {
        Button(action: {
          store.send(.clearAppLogsClicked)
          selected = nil
        }) {
          Image(systemName: "xmark.circle")
          Text("Clear").offset(x: -1)
        }
        Button(action: copyAll) {
          Image(systemName: "square.on.square").offset(y: 0.5)
          Text("Copy All").offset(x: -1)
        }
        Toggle("Log to Console", isOn: store.bind(
          { store.state.logging.toConsole },
          { .toggleConsoleLogging(enabled: $0) }
        ))
        TextInput(text: $filterText)
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(Color(hex: darkMode ? 0x333333 : 0xEEEEEE))

      Group {
        if logs.isEmpty {
          Text("Waiting for logs...")
            .foregroundColor(.secondary)
            .italic()
        } else {
          logsTable
        }
      }
      .infinite()

      if let isolated = selected?.identified {
        Text(isolated.debugDescription)
          .font(.system(size: 16, weight: .regular, design: .monospaced))
          .lineSpacing(5.0)
          .padding()
      }
    }
    .frame(minWidth: Self.MIN_WIDTH, minHeight: Self.MIN_HEIGHT)
    .background(darkMode ? Color.black : Color.white)
  }

  func copyAll() {
    copyToClipboard(logs.map(\.debugDescription).joined(separator: "\n"))
  }
}

public extension Log.Message {
  var conciseTime: String {
    conciseTimeFormatter.string(from: date)
  }

  var isoDate: String {
    isoDateFormatter.string(from: date)
  }

  var enhancedMessage: String {
    var enhanced = message

    if message == "reducer received action",
       let appAction = meta["meta.primary"]?.description.split(separator: "(").first {
      enhanced += ": \(appAction)"
    }

    if let verdict = meta["filter_decision.verdict"] {
      enhanced += " > \(verdict)".uppercased()
      if let target = meta["filter_decision.target"],
         target != .string("(nil)") {
        enhanced += " \(target)"
      }
    }

    return enhanced
  }

  var messageAndMeta: String {
    "\(enhancedMessage) \(stableMetaString)"
  }

  var debugDescription: String {
    "\(isoDate) \(conciseTime) \(messageAndMeta)"
  }

  var stableMetaString: String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    guard let data = try? encoder.encode(meta),
          let json = String(data: data, encoding: .utf8)
    else {
      return ""
    }
    return json
  }
}

struct LogsWindow_Previews: PreviewProvider, GertrudeProvider {
  static var initializeState: StateCustomizer? = { state in
    state.loggingWindow.logs = make(20, Log.Message.mock)
      .map { .init(id: UUID(), identified: $0) }
  }

  static var cases: [(inout AppState) -> Void] = [
    { _ in },
    { state in
      state.colorScheme = .dark
    },
    { state in
      state.loggingWindow.logs = []
      state.colorScheme = .dark
    },
    { state in
      state.loggingWindow.logs = []
      state.colorScheme = .light
    },
  ]

  static var previews: some View {
    ForEach(allPreviews) {
      LogsWindow().store($0)
    }
  }
}
