import SwiftUI

struct ChooseWhatToBlockView: View {
  @Environment(\.colorScheme) var cs
  
  let onTap: () -> Void
  
  struct BlockableItem: Identifiable {
    var name: String
    var shortDescription: String
    var longDescription: String
    var image: String
    var isSelected: Bool
    
    var id: String
  }
  
  @State private var blockableItems = [
    (
      "GIFs",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "Amet irure eu laboris consequat commodo et dolor quis est duis anim ut voluptate. Laborum nostrud proident commodo occaecat sit excepteur cupidatat reprehenderit. Sit ullamco culpa duis officia occaecat ipsum deserunt dolore. Excepteur ut ut exercitation adipisicing consequat qui tempor proident.",
      "MessagesGIFs"
    ),
    (
      "Apple Maps images",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "Amet irure eu laboris consequat commodo et dolor quis est duis anim ut voluptate. Laborum nostrud proident commodo occaecat sit excepteur cupidatat reprehenderit. Sit ullamco culpa duis officia occaecat ipsum deserunt dolore. Excepteur ut ut exercitation adipisicing consequat qui tempor proident.",
      "MapsImages"
    ),
    (
      "AI features",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "Amet irure eu laboris consequat commodo et dolor quis est duis anim ut voluptate. Laborum nostrud proident commodo occaecat sit excepteur cupidatat reprehenderit. Sit ullamco culpa duis officia occaecat ipsum deserunt dolore. Excepteur ut ut exercitation adipisicing consequat qui tempor proident.",
      "AIFeatures"
    ),
    (
      "App store images",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "Amet irure eu laboris consequat commodo et dolor quis est duis anim ut voluptate. Laborum nostrud proident commodo occaecat sit excepteur cupidatat reprehenderit. Sit ullamco culpa duis officia occaecat ipsum deserunt dolore. Excepteur ut ut exercitation adipisicing consequat qui tempor proident.",
      "AppStoreImages"
    ),
    (
      "Spotlight",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "Amet irure eu laboris consequat commodo et dolor quis est duis anim ut voluptate. Laborum nostrud proident commodo occaecat sit excepteur cupidatat reprehenderit. Sit ullamco culpa duis officia occaecat ipsum deserunt dolore. Excepteur ut ut exercitation adipisicing consequat qui tempor proident.",
      "SpotlightSearch"
    ),
    (
      "Ads",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "Amet irure eu laboris consequat commodo et dolor quis est duis anim ut voluptate. Laborum nostrud proident commodo occaecat sit excepteur cupidatat reprehenderit. Sit ullamco culpa duis officia occaecat ipsum deserunt dolore. Excepteur ut ut exercitation adipisicing consequat qui tempor proident.",
      "AdBlocking"
    ),
    (
      "WhatsApp",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "Amet irure eu laboris consequat commodo et dolor quis est duis anim ut voluptate. Laborum nostrud proident commodo occaecat sit excepteur cupidatat reprehenderit. Sit ullamco culpa duis officia occaecat ipsum deserunt dolore. Excepteur ut ut exercitation adipisicing consequat qui tempor proident.",
      "BadWhatsAppFeatures"
    ),
    (
      "apple.com",
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "Amet irure eu laboris consequat commodo et dolor quis est duis anim ut voluptate. Laborum nostrud proident commodo occaecat sit excepteur cupidatat reprehenderit. Sit ullamco culpa duis officia occaecat ipsum deserunt dolore. Excepteur ut ut exercitation adipisicing consequat qui tempor proident.",
      "AppleWebsite"
    ),
  ].map { name, shortDescription, longDescription, image in
    BlockableItem(
      name: name,
      shortDescription: shortDescription,
      longDescription: longDescription,
      image: image,
      isSelected: true,
      id: name
    )
  }
  
  @State private var sheetItem: BlockableItem? = nil
  
  @State private var iconOffset = Vector(0, 20)
  @State private var titleOffset = Vector(0, 20)
  @State private var paragraphOffset = Vector(0, 20)
  @State private var itemOffsets = Array(repeating: Vector(0, 40), count: 8)
  @State private var buttonOffset = Vector(0, 20)
  @State private var showBg = false
  
  var body: some View {
    ScrollView {
      VStack(alignment: .center) {
        Image(systemName: "party.popper")
          .font(.system(size: 30, weight: .semibold))
          .foregroundStyle(Color(cs, light: .violet800, dark: .violet400))
          .padding(12)
          .background(Color(cs, light: .violet300.opacity(0.6), dark: .violet950))
          .cornerRadius(24)
          .swooshIn(tracking: self.$iconOffset, to: .origin, after: .zero, for: .seconds(0.6))
        
        Text("Success! We're nearly done.")
          .multilineTextAlignment(.center)
          .font(.system(size: 24, weight: .bold))
          .padding(.top, 28)
          .padding(.bottom, 8)
          .swooshIn(
            tracking: self.$titleOffset,
            to: .origin,
            after: .seconds(0.1),
            for: .seconds(0.6)
          )
        
        Text(
          "Gertrude is all set to block content. Take a moment to decide if there are any of these types of content that you don't want to block:"
        )
        .multilineTextAlignment(.center)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(Color(cs, light: .black.opacity(0.8), dark: .white.opacity(0.8)))
        .swooshIn(
          tracking: self.$paragraphOffset,
          to: .origin,
          after: .seconds(0.2),
          for: .seconds(0.6)
        )
        
        VStack(alignment: .leading) {
          ForEach(Array(self.$blockableItems.enumerated()), id: \.offset) { index, $item in
            Button {
              withAnimation(.smooth(duration: 0.1)) {
                item.isSelected.toggle()
              }
            } label: {
              HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark")
                  .font(.system(size: 12, weight: .bold))
                  .scaleEffect(item.isSelected ? 1 : 0)
                  .foregroundStyle(.white)
                  .padding(4)
                  .background(item.isSelected ? Color.violet500 : Color(cs, light: .white, dark: .black))
                  .cornerRadius(6)
                  .overlay {
                    RoundedRectangle(cornerRadius: 6)
                      .stroke(
                        item.isSelected ? Color.violet500 : Color.gray.opacity(0.2),
                        lineWidth: 2
                      )
                  }
                
                VStack(alignment: .leading, spacing: 4) {
                  HStack {
                    Text(item.name)
                      .font(.system(size: 18, weight: .semibold))
                      .foregroundStyle(Color(cs, light: .black, dark: .white))
                    Button {
                      self.sheetItem = item
                    } label: {
                      Image(systemName: "questionmark.circle")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(cs, light: .black.opacity(0.4), dark: .white.opacity(0.4)))
                        .multilineTextAlignment(.leading)
                    }
                  }
                  
                  Text(item.shortDescription)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color(cs, light: .black.opacity(0.6), dark: .white.opacity(0.6)))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 12)
              .padding(.vertical, 12)
              .background(Gradient(colors: [Color(cs, light: .white, dark: .white.opacity(0.15)), Color(cs, light: .white.opacity(0.7), dark: .white.opacity(0.07))]))
              .cornerRadius(16)
              .shadow(color: Color(cs, light: .violet200, dark: .violet900.opacity(0.3)), radius: 3)
              .opacity(item.isSelected ? 1 : cs == .light ? 0.7 : 0.5)
            }
            .buttonStyle(BounceButtonStyle())
            .sensoryFeedback(.selection, trigger: item.isSelected)
            .swooshIn(
              tracking: self.$itemOffsets[index],
              to: .origin,
              after: .seconds(Double(index) / 15.0 + 0.3),
              for: .milliseconds(600)
            )
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        
        BigButton("Done, continue", variant: .primary) {
          self.vanishingAnimations()
          delayed(by: .seconds(0.5)) {
            self.onTap()
          }
        }
        .swooshIn(
          tracking: self.$buttonOffset,
          to: .origin,
          after: .seconds(0.2),
          for: .seconds(0.6)
        )
      }
      .padding(.top, 100)
      .padding(.bottom, 50)
      .padding(.horizontal, 30)
    }
    .background(Color(cs, light: .violet100, dark: .violet950.opacity(0.4)))
    .opacity(self.showBg ? 1 : 0)
    .onAppear {
      withAnimation(.smooth(duration: 0.5)) {
        self.showBg = true
      }
    }
    .ignoresSafeArea()
    .sheet(item: self.$sheetItem) { item in
      NavigationStack {
        ZStack {
          Color(cs, light: .white, dark: .violet950.opacity(0.3)).edgesIgnoringSafeArea(.vertical)
          VStack {
            Image(item.image)
              .resizable()
              .frame(maxWidth: .infinity)
              .aspectRatio(contentMode: .fit)
              .shadow(color: .black.opacity(0.1), radius: 8)
              .overlay {
                RoundedRectangle(cornerRadius: 22)
                  .stroke(Color.black.opacity(0.05), lineWidth: 1)
              }
            Text(item.name)
              .font(.system(size: 24, weight: .bold))
              .padding(.top, 20)
              .padding(.bottom, 4)
            Text(item.longDescription)
              .font(.system(size: 16))
              .foregroundStyle(Color(cs, light: .black.opacity(0.7), dark: .white.opacity(0.7)))
              .multilineTextAlignment(.center)
          }
          .presentationDetents([.height(600)])
          .padding(20)
          .toolbar {
            ToolbarItem {
              Button {
                self.sheetItem = nil
              } label: {
                Image(systemName: "xmark")
                  .font(.system(size: 10, weight: .bold))
                  .foregroundStyle(Color(cs, light: .black.opacity(0.4), dark: .white.opacity(0.5)))
                  .padding(8)
                  .background(Color(cs, light: .black.opacity(0.05), dark: .white.opacity(0.08)))
                  .cornerRadius(16)
              }
            }
          }
        }
      }
    }
  }
  
  func vanishingAnimations() {
    withAnimation {
      self.iconOffset.y = -20
      self.titleOffset.y = -20
      self.paragraphOffset.y = -20
      self.itemOffsets = Array(repeating: .init(0, -20), count: self.blockableItems.count)
    }
    
    delayed(by: .milliseconds(100)) {
      withAnimation {
        self.buttonOffset.y = -20
        self.showBg = false
      }
    }
  }
}

#Preview {
  ChooseWhatToBlockView {}
}

struct BounceButtonStyle: ButtonStyle {
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .opacity(configuration.isPressed ? 0.8 : 1.0)
  }
}
