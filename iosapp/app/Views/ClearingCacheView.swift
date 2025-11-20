import ComposableArchitecture
import LibApp
import SwiftUI

struct ClearingCacheView: View {
  @Environment(\.colorScheme) var cs

  @Bindable var store: StoreOf<ClearCacheFeature>

  var clearedMessage: String
  var clearedBtnLabel: String

  @State private var spinnerOffset = Vector(x: 0, y: 20)
  @State private var titleOffset = Vector(x: 0, y: 20)
  @State private var subtitleOffset = Vector(x: 0, y: 20)
  @State private var amountClearedOffset = Vector(x: 0, y: 20)
  @State private var showBg = false

  var body: some View {
    switch self.store.screen {
    case .loading:
      Color.clear // can't use EmptyView, won't get .onAppear
    case .batteryWarning:
      self.batteryWarningView
    case .clearing:
      self.clearingView
    case .cleared:
      self.clearedView
    }
  }

  var batteryWarningView: some View {
    ButtonScreenView(
      text: "Clearing the cache uses a lot of battery; we recommend you plug in the device now.",
      primary: .init("Next") {
        self.store.send(.batteryWarningContinueTapped)
      },
    )
  }

  var clearedView: some View {
    ButtonScreenView(
      text: self.clearedMessage,
      primary: .init(self.clearedBtnLabel) {
        self.store.send(.completeBtnTapped)
      },
    )
  }

  var clearingView: some View {
    ZStack {
      FairiesView()
        .opacity(self.showBg ? 1 : 0)
        .onAppear {
          withAnimation {
            self.showBg = true
          }
        }

      VStack(spacing: 0) {
        ProgressView()
          .swooshIn(
            tracking: self.$spinnerOffset,
            to: .zero,
            after: .seconds(0.2),
            for: .seconds(0.5),
          )

        Text("Clearing cache...")
          .font(.system(size: 24, weight: .medium))
          .padding(.top, 16)
          .swooshIn(
            tracking: self.$titleOffset,
            to: .zero,
            after: .seconds(0.3),
            for: .seconds(0.5),
          )

        Text("This may take a little while.")
          .padding(.top, 6)
          .font(.system(size: 18, weight: .regular))
          .foregroundStyle(Color(self.cs, light: .black.opacity(0.7), dark: .white.opacity(0.7)))
          .swooshIn(
            tracking: self.$subtitleOffset,
            to: .zero,
            after: .seconds(0.4),
            for: .seconds(0.5),
          )

        if let availableSpace = self.store.availableDiskSpaceInBytes {
          ProgressView(
            value: Double(self.store.bytesCleared),
            // available is estimate, pad a little to prevent full bar
            total: Double(availableSpace) * 1.1,
          )
          .progressViewStyle(LinearProgressViewStyle())
          .frame(height: 20)
          .padding(.horizontal, 60)
          .padding(.top, 20)
          .swooshIn(
            tracking: self.$amountClearedOffset,
            to: .zero,
            after: .seconds(0.5),
            for: .seconds(0.5),
          )
        }

        Text(
          "\(Bytes.humanReadable(self.store.bytesCleared, decimalPlaces: 3, prefix: .decimal)) checked",
        )
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(Color(self.cs, light: .black.opacity(0.4), dark: .white.opacity(0.4)))
        .padding(.top, 15)
        .swooshIn(
          tracking: self.$amountClearedOffset,
          to: .zero,
          after: .seconds(0.5),
          for: .seconds(0.5),
        )
      }
    }
  }
}

#Preview {
  ClearingCacheView(
    store: .init(initialState: .init(
      context: .onboarding,
      availableDiskSpaceInBytes: 3_000_000_000,
      bytesCleared: 1_040_031_000,
    )) {
      ClearCacheFeature()
    },
    clearedMessage: "Done! Previously downloaded GIFs should be gone!",
    clearedBtnLabel: "Next",
  )
}
