import ComposableArchitecture
import Dependencies
import IOSRoute
import LibApp
import SwiftUI
import UIKit

struct InfoView: View {
  @Bindable var store: StoreOf<InfoFeature>
  @Environment(\.colorScheme) var cs
  @State private var justCopied = false

  var body: some View {
    ZStack {
      Color(self.cs, light: .violet100, dark: .black)
        .ignoresSafeArea()
      if let clearCacheStore = self.store.scope(
        state: \.clearCache,
        action: \.clearCache,
      ) {
        ClearingCacheView(
          store: clearCacheStore,
          clearedMessage: "Done! Previously downloaded GIFs should be gone!",
          clearedBtnLabel: "Back",
        )
        .onAppear { clearCacheStore.send(.onAppear) }
      } else {
        switch self.store.subScreen {
        case .main:
          if let connection = self.store.connection {
            self.connectedView(connection: connection)
          } else {
            self.unconnectedView
          }
        case .explainClearCache1:
          self.explainClearCacheView1
        case .explainClearCache2:
          self.explainClearCacheView2
        case .clearingCache:
          EmptyView()
        }
      }
    }
  }

  var unconnectedView: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 24) {
          HStack(spacing: 8) {
            Image(systemName: "gearshape")
              .font(.system(size: 24, weight: .bold))
              .foregroundStyle(Color(self.cs, light: .violet900, dark: .white))
            Text("Info")
              .font(.system(size: 28, weight: .bold))
              .foregroundStyle(Color(self.cs, light: .violet900, dark: .white))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.bottom, 8)

          self.infoCard(
            title: "Device ID",
            value: self.store.vendorId?.uuidString.lowercased() ?? "(nil)",
            icon: "iphone",
            showCopyButton: true,
            justCopied: self.$justCopied,
          )

          self.infoCard(
            title: "Block Rules",
            value: "\(self.store.numRules) rules active",
            icon: "shield.checkered",
          )

          self.infoCard(
            title: "Block Groups",
            value: self.blockGroupsCardValue,
            icon: "slider.horizontal.3",
          )

          Spacer()

          VStack(spacing: 12) {
            BigButton(
              "Clear cache",
              type: .button { self.store.send(.clearCacheTapped) },
              variant: .primary,
              icon: "trash",
            )
          }
          .padding(.top, 8)
          .padding(.bottom, 16)
        }
        .frame(minHeight: geometry.size.height - 30)
        .padding(.horizontal, 24)
        .padding(.top, 32)
      }
    }
  }

  var blockGroupsCardValue: String {
    let totalBlockGroups = [BlockGroup].all.count
    let enabled = totalBlockGroups - self.store.numDisabledBlockGroups
    let total = max(totalBlockGroups, enabled)
    return "\(enabled)/\(total) groups enabled"
  }

  func connectedView(connection: ChildIOSDeviceData_b1) -> some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 24) {
          HStack(spacing: 8) {
            Image(systemName: "gearshape")
              .font(.system(size: 24, weight: .bold))
              .foregroundStyle(Color(self.cs, light: .violet900, dark: .white))
            Text("Info")
              .font(.system(size: 28, weight: .bold))
              .foregroundStyle(Color(self.cs, light: .violet900, dark: .white))
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.bottom, 8)

          self.infoCard(
            title: "Child Name",
            value: connection.childName,
            icon: "person.circle",
          )

          self.infoCard(
            title: "Child ID",
            value: String(connection.childId.uuidString.lowercased().prefix(23)),
            icon: "number",
          )

          self.infoCard(
            title: "Device ID",
            value: self.store.vendorId?.uuidString.lowercased() ?? "(nil)",
            icon: "iphone",
            showCopyButton: true,
            justCopied: self.$justCopied,
          )

          self.infoCard(
            title: "Block Rules",
            value: "\(self.store.numRules) rules active",
            icon: "shield.checkered",
          )

          Spacer()

          VStack(spacing: 12) {
            BigButton(
              "Clear Cache",
              type: .button { self.store.send(.clearCacheTapped) },
              variant: .secondary,
              icon: "trash",
            )
          }
          .padding(.top, 8)
          .padding(.bottom, 16)
        }
        .frame(minHeight: geometry.size.height - 30)
        .padding(.horizontal, 24)
        .padding(.top, 32)
      }
    }
  }

  func infoCard(
    title: String,
    value: String,
    icon: String,
    showCopyButton: Bool = false,
    justCopied: Binding<Bool> = .constant(false),
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Color(self.cs, light: .violet600, dark: .violet300))
        Text(title)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color(self.cs, light: .violet700, dark: .violet200))
        Spacer()
        if showCopyButton {
          Button {
            UIPasteboard.general.string = value
            justCopied.wrappedValue = true
            Task {
              try? await Task.sleep(for: .seconds(2))
              justCopied.wrappedValue = false
            }
          } label: {
            Image(systemName: justCopied.wrappedValue ? "checkmark" : "doc.on.doc")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(
                justCopied.wrappedValue
                  ? Color(self.cs, light: .green, dark: .green)
                  : Color(self.cs, light: .violet500, dark: .violet300),
              )
              .frame(width: 16, height: 16)
          }
        }
      }

      Text(value)
        .font(.system(size: 15, design: .monospaced))
        .foregroundStyle(Color(self.cs, light: .violet900, dark: .white))
        .lineLimit(1)
        .truncationMode(.tail)
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(self.cs, light: .white.opacity(0.7), dark: .violet950)),
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(self.cs, light: .violet300, dark: .violet800), lineWidth: 1),
    )
  }

  var explainClearCacheView1: some View {
    ButtonScreenView(
      text: "Clearing the cache can help if there are images still visible that were downloaded BEFORE Gertrude was installed, especially if the #images GIF search is showing a mixture of images and grey squares.",
      primary: ButtonScreenView.Config(text: "Next", type: .button {
        self.store.send(.explainClearCacheNextTapped)
      }),
      secondary: ButtonScreenView.Config(text: "Cancel", type: .button {
        self.store.send(.cancelClearCacheTapped)
      }),
    )
  }

  var explainClearCacheView2: some View {
    ButtonScreenView(
      text: "However, clearing the cache does not always remove all of these images. If you find that images persist, the only guaranteed way to remove them is to backup the device, do a factory reset, and then restore the backup.",
      primary: ButtonScreenView.Config(text: "Next", type: .button {
        self.store.send(.explainClearCacheNextTapped)
      }),
      secondary: ButtonScreenView.Config(text: "Cancel", type: .button {
        self.store.send(.cancelClearCacheTapped)
      }),
    )
  }
}

#Preview("Unconnected - Light") {
  InfoView(store: .init(
    initialState: .init(
      vendorId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
      numRules: 42,
      numDisabledBlockGroups: 4,
    ),
  ) {
    InfoFeature()
  })
  .environment(\.colorScheme, .light)
}

#Preview("Unconnected - Dark") {
  InfoView(store: .init(
    initialState: .init(
      vendorId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
      numRules: 42,
      numDisabledBlockGroups: 4,
    ),
  ) {
    InfoFeature()
  })
  .environment(\.colorScheme, .dark)
}

#Preview("Connected - Light") {
  InfoView(store: .init(
    initialState: .init(
      connection: .init(
        childId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        token: UUID(),
        deviceId: UUID(),
        childName: "Emma Johnson",
      ),
      vendorId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
      numRules: 87,
    ),
  ) {
    InfoFeature()
  })
  .environment(\.colorScheme, .light)
}

#Preview("Connected - Dark") {
  InfoView(store: .init(
    initialState: .init(
      connection: .init(
        childId: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
        token: UUID(),
        deviceId: UUID(),
        childName: "Emma Johnson",
      ),
      vendorId: UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!,
      numRules: 87,
    ),
  ) {
    InfoFeature()
  })
  .environment(\.colorScheme, .dark)
}
