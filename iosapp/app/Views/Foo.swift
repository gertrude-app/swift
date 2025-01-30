import ComposableArchitecture
import SwiftUI

struct Foo: View {
  @State var positions: IdentifiedArrayOf<Vector> = [
    Vector(0, 200),
    Vector(0, 100),
    Vector(0, 50),
  ]
  
//  @State var singlePosition = Vector(0, 100)
  
  var body: some View {
    HStack(spacing: 60) {
      ForEach($positions) { $position in
        Text("foo \(position.id)")
          .swooshIn(tracking: $position, to: .origin, after: .zero, for: .seconds(0.5))
      }
//      Text("foo")
//        .swooshIn(tracking: $singlePosition, to: .origin, after: .zero, for: .seconds(0.4))
    }
  }
}

#Preview {
  Foo()
}
