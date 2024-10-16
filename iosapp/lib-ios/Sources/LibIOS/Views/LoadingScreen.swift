import Foundation
import SwiftUI

public struct LoadingScreen: View {
  @State private var t = 0.0
  @State var timer: Timer?

  public var body: some View {
    HStack(spacing: sin(self.t) * 20) {
      Rectangle()
        .frame(width: -sin(self.t) * 5 + 15, height: sin(self.t) * 40 + 60)
        .cornerRadius(20)
        .foregroundColor(violet500.opacity(0.8))
      Rectangle()
        .frame(width: -sin(self.t + 0.4) * 5 + 15, height: sin(self.t + 0.4) * 40 + 60)
        .cornerRadius(20)
        .foregroundColor(violet500.opacity(0.8))
      Rectangle()
        .frame(width: -sin(self.t + 0.8) * 5 + 15, height: sin(self.t + 0.8) * 40 + 60)
        .cornerRadius(20)
        .foregroundColor(violet500.opacity(0.8))
    }
    .onAppear {
      self.startAnimation()
    }
    .onDisappear {
      self.stopAnimation()
    }
  }

  private func startAnimation() {
    self.timer = Timer.scheduledTimer(
      withTimeInterval: 0.016,
      repeats: true
    ) { _ in
      withAnimation(.linear(duration: 0.016)) {
        self.t += 0.06
      }
    }
  }

  private func stopAnimation() {
    self.timer?.invalidate()
    self.timer = nil
  }
}

#Preview {
  ZStack {
    BgGradient()
      .ignoresSafeArea()
    LoadingScreen()
  }
}
