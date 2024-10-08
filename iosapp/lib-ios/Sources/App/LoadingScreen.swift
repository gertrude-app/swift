import SwiftUI

public struct LoadingScreen: View {
  @State private var rotation = 0.0

  public var body: some View {
    Image("GertrudeIcon", bundle: Bundle.main)
      .frame(width: 20, height: 20)
      .opacity(0.5)
      .rotationEffect(.degrees(rotation))
      .onAppear {
        withAnimation(
          .linear(duration: 1)
            .speed(1.2).repeatForever(autoreverses: false)
        ) {
          rotation = 360.0
        }
      }
  }

  public init() {}
}

#Preview {
  LoadingScreen()
}
