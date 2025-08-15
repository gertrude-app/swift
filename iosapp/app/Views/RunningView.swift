import ComposableArchitecture
import Dependencies
import LibApp
import SwiftUI

struct RunningView: View {
  @Environment(\.colorScheme) var cs

  @State private var iconOffset = Vector(x: 0, y: 20)
  @State private var titleOffset = Vector(x: 0, y: 20)
  @State private var subtitleOffset = Vector(x: 0, y: 20)
  @State private var linkOffset = Vector(x: 0, y: 20)
  @State private var showBg = false

  @Bindable var store: StoreOf<IOSReducer>

  let childName: String?
  let onBtnTap: () -> Void

  var body: some View {
    ZStack {
      FairiesView()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation {
            self.showBg = true
          }
        }

      VStack(spacing: 0) {
        Spacer()

        Image(systemName: "checkmark")
          .font(.system(size: 30, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet800, dark: .violet400))
          .padding(12)
          .background(Color(self.cs, light: .violet300.opacity(0.6), dark: .violet950))
          .cornerRadius(24)
          .swooshIn(tracking: self.$iconOffset, to: .zero, after: .seconds(0.2), for: .seconds(0.5))

        Text("Gertude is blocking unwanted content")
          .font(.system(size: 24, weight: .medium))
          .padding(.bottom, 12)
          .padding(.top, 28)
          .swooshIn(
            tracking: self.$titleOffset,
            to: .zero,
            after: .seconds(0.3),
            for: .seconds(0.5)
          )

        if let childName = self.childName {
          Text("Hi \(childName)!")
            .font(.system(size: 18, weight: .medium))
            .padding(.bottom, 20)
        } else {
          BigButton("Connect to parent account", type: .button(self.onBtnTap))
            .padding(.bottom, 20)
        }

        Text("You can quit the app now, it will keep blocking even when not running.")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.6), dark: .white.opacity(0.6)))
          .swooshIn(
            tracking: self.$subtitleOffset,
            to: .zero,
            after: .seconds(0.4),
            for: .seconds(0.5)
          )

        Link(destination: URL(string: "https://gertrude.app")!) {
          HStack {
            Text("www.gertrude.app")
            Image(systemName: "arrow.up.right")
              .font(.system(size: 14, weight: .semibold))
              .offset(y: 1.5)
          }
        }
        .padding(.top, 25)
        .swooshIn(
          tracking: self.$linkOffset,
          to: .zero,
          after: .seconds(0.5),
          for: .seconds(0.5)
        )

        Spacer()
      }
      .frame(maxWidth: .infinity)
      .multilineTextAlignment(.center)
      .padding(30)
    }
  }
}

#Preview {
  RunningView(
    store: .init(initialState: .init()) { IOSReducer() },
    childName: nil,
    onBtnTap: {}
  )
}
