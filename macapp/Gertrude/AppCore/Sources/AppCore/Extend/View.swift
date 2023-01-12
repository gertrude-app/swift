import Shared
import SwiftUI

extension View {
  func popoverSized() -> some View {
    modifier(PopoverSize())
  }

  func adminPreview() -> some View {
    frame(width: AdminWindow.MIN_WIDTH, height: AdminWindow.MIN_HEIGHT)
  }

  func requestsPreview() -> some View {
    frame(width: RequestsWindow.MIN_WIDTH, height: RequestsWindow.MIN_HEIGHT)
  }

  func infinite() -> some View {
    frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  func colorSchemeBg(_ colorScheme: ColorScheme) -> some View {
    background(colorScheme == .dark ? Color.black : Color.white)
      .preferredColorScheme(colorScheme)
  }

  func padding(
    top: CGFloat? = nil,
    right: CGFloat? = nil,
    bottom: CGFloat? = nil,
    left: CGFloat? = nil
  ) -> some View {
    padding(.init(
      top: top ?? PAD_DFLT,
      leading: left ?? PAD_DFLT,
      bottom: bottom ?? PAD_DFLT,
      trailing: right ?? PAD_DFLT
    ))
  }

  func padding(left: CGFloat, right: CGFloat) -> some View {
    padding(.leading, left).padding(.trailing, right)
  }

  func padding(top: CGFloat) -> some View {
    padding(.top, top)
  }

  func padding(bottom: CGFloat) -> some View {
    padding(.bottom, bottom)
  }

  func padding(left: CGFloat) -> some View {
    padding(.leading, left)
  }

  func padding(right: CGFloat) -> some View {
    padding(.trailing, right)
  }

  func padding(top: CGFloat, bottom: CGFloat) -> some View {
    padding(.top, top).padding(.bottom, bottom)
  }

  func padding(x: CGFloat) -> some View {
    padding(.leading, x).padding(.trailing, x)
  }

  func padding(y: CGFloat) -> some View {
    padding(.top, y).padding(.bottom, y)
  }

  func padding(x: CGFloat, y: CGFloat) -> some View {
    padding(x: x).padding(y: y)
  }

  func store(_ store: AppStore) -> some View {
    environmentObject(store)
      .colorSchemeBg(store.state.colorScheme)
  }

  func store(_ preview: PreviewCase) -> some View {
    environmentObject(preview.store)
      .colorSchemeBg(preview.store.state.colorScheme)
  }
}

private let PAD_DFLT: CGFloat = 10

struct PopoverSize: ViewModifier {
  static let WIDTH: CGFloat = 725
  static let HEIGHT: CGFloat = 365

  func body(content: Content) -> some View {
    content.frame(width: PopoverSize.WIDTH, height: PopoverSize.HEIGHT, alignment: .center)
  }
}

typealias StateCustomizer = (inout AppState) -> Void

struct PreviewCase: Identifiable {
  var id: String
  var state: AppState

  init(
    id: String,
    initialize: StateCustomizer? = nil,
    customize: StateCustomizer = { _ in },
    colorScheme: ColorScheme = .light
  ) {
    var state = AppState()
    state.colorScheme = colorScheme
    initialize?(&state)
    customize(&state)
    self.id = id
    self.state = state
  }

  var store: AppStore {
    AppStore(initialState: state, reducer: nilReducer, environment: .noop)
  }
}

protocol GertrudeProvider {
  static var cases: [StateCustomizer] { get }
  static var allPreviews: [PreviewCase] { get }
  static var colorScheme: ColorScheme { get }
  static var initializeState: StateCustomizer? { get }
}

extension PreviewProvider where Self: GertrudeProvider {
  static var allPreviews: [PreviewCase] {
    cases.enumerated().map { index, customize in
      PreviewCase(
        id: "pc-\(index)",
        initialize: initializeState,
        customize: customize,
        colorScheme: colorScheme
      )
    }
  }

  static var initializeState: StateCustomizer? { nil }
  static var colorScheme: ColorScheme { .light }
}

protocol DarkModeAware {
  var darkMode: Bool { get }
  var red: Color { get }
  var green: Color { get }
}

extension DarkModeAware {
  var red: Color { darkMode ? .darkModeRed : .lightModeRed }
  var green: Color { darkMode ? .darkModeGreen : .lightModeGreen }

  func bandedRowBg(selected: Bool, alt: Bool) -> Color {
    if selected {
      return Color(
        hex: 0xCF8B0E,
        alpha: darkMode ? 0.2 : 0.25
      )
    } else {
      return Color(
        hex: 0x000,
        alpha: alt ? (darkMode ? 0.15 : 0.05) : 0
      )
    }
  }
}

protocol ColorSchemeView: DarkModeAware {
  var colorScheme: ColorScheme { get }
}

extension ColorSchemeView {
  var darkMode: Bool { colorScheme == .dark }
}

protocol StoreView: DarkModeAware {
  var store: AppStore { get }
}

extension StoreView {
  var darkMode: Bool { store.state.colorScheme == .dark }

  func send(_ action: AppAction) -> () -> Void {
    { store.send(action) }
  }
}

// this is currently (10/21) the only way to remove a focus ring
// from a swiftui TextField, which also removes it from ALL text fields
extension NSTextField {
  override open var focusRingType: NSFocusRingType {
    get { .none }
    set {}
  }
}

// seems required in order to set a background color on a TextEditor
// @see https://developer.apple.com/forums/thread/659788
extension NSTextView {
  override open var frame: CGRect {
    didSet {
      backgroundColor = .clear
      drawsBackground = true
    }
  }
}

extension Binding {
  static func mock(_ value: Value) -> Self {
    var value = value
    return Binding(get: { value }, set: { value = $0 })
  }
}

extension FilterState {
  var bgColor: Color {
    switch self {
    case .on:
      return Color(hex: 0x3CAD26)
    case .off:
      return Color(hex: 0xB32222)
    case .suspended:
      return Color(hex: 0xEB881E)
    }
  }
}

extension View {
  func centered() -> some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        self
        Spacer()
      }
      Spacer()
    }
  }
}
