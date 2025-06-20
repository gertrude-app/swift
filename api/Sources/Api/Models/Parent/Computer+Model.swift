import Gertie

extension Computer {
  struct Model: Encodable, Equatable {
    var type: Kind
    var identifier: String
    var chip: Chip
    var manufactureDates: Set<ManufactureDate>
    var screenSizeInInches: Float?
    var newestCompatibleOS: MacOS?

    init(
      type: Kind,
      identifier: String,
      chip: Computer.Model.Chip,
      manufactureDates: Set<Computer.Model.ManufactureDate> = [],
      screenSizeInInches: Float? = nil,
      newestCompatibleOS: MacOS? = nil
    ) {
      self.type = type
      self.identifier = identifier
      self.chip = chip
      self.manufactureDates = manufactureDates
      self.screenSizeInInches = screenSizeInInches
      self.newestCompatibleOS = newestCompatibleOS
    }
  }
}

extension Computer.Model {
  enum Kind: String, Encodable, CaseIterable {
    case macBook = "MacBook"
    case macBookAir = "MacBook Air"
    case macBookPro = "MacBook Pro"
    case mini = "Mac mini"
    case iMac
    case iMacPro = "iMac Pro"
    case studio = "Mac Studio"
    case pro = "Mac Pro"
    case unknown = "Unknown mac"
  }
}

extension Computer.Model {
  var shortDescription: String {
    var desc = type.rawValue
    let chipDesc = chip.madeByApple ? "\(chip.rawValue) " : ""
    if let screenSize = screenSizeInInches {
      let size = String(screenSize).replacingOccurrences(of: ".0", with: "")
      desc = "\(size)\" \(chipDesc)\(desc)"
    } else {
      desc = "\(chipDesc)\(desc)"
    }
    if manufactureDates.count == 1, let date = manufactureDates.first {
      desc += " (\(date.year))"
    }
    return desc
  }
}

extension Computer.Model {
  var family: DeviceModelFamily {
    switch type {
    case .macBook:
      .macBook
    case .macBookAir:
      .macBookAir
    case .macBookPro:
      .macBookPro
    case .mini:
      .mini
    case .iMac, .iMacPro:
      .iMac
    case .studio:
      .studio
    case .pro:
      .pro
    case .unknown:
      .unknown
    }
  }
}

extension Computer.Model {
  enum Chip: String, Encodable {
    case m4 = "M4"
    case m3 = "M3"
    case m2 = "M2"
    case m1 = "M1"
    case intel = "Intel"
  }
}

extension Computer.Model.Chip {
  var madeByApple: Bool {
    switch self {
    case .intel:
      false
    default:
      true
    }
  }
}

enum MacOS: Encodable {
  case sequoia
  case sonoma
  case ventura
  case monterey
  case bigSur
  case catalina
}

extension Computer.Model {
  struct ManufactureDate: Hashable, Encodable {
    enum Modifier: Encodable {
      case early
      case mid
      case late
    }

    var year: Int
    var modifier: Modifier?

    init(year: Int, modifier: Modifier? = nil) {
      self.year = year
      self.modifier = modifier
    }
  }
}

extension Computer.Model {
  static let unknown = Self(type: .unknown, identifier: "unknown", chip: .m1)
}

extension Computer.Model.ManufactureDate: ExpressibleByIntegerLiteral {
  init(integerLiteral value: Int) {
    self.init(year: value)
  }
}

extension Computer.Model.ManufactureDate {
  static func early(_ year: Int) -> Self {
    .init(year: year, modifier: .early)
  }

  static func mid(_ year: Int) -> Self {
    .init(year: year, modifier: .mid)
  }

  static func late(_ year: Int) -> Self {
    .init(year: year, modifier: .late)
  }
}

// derive the model from the identifier

extension Computer {
  var model: Model {
    switch modelIdentifier {
    // MacBook Air @link https://support.apple.com/en-us/HT201862
    case "Mac16,13":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .m4,
        manufactureDates: [2025],
        screenSizeInInches: 15.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac16,12":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .m4,
        manufactureDates: [2025],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac15,13":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .m3,
        manufactureDates: [2024],
        screenSizeInInches: 15.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac15,12":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .m3,
        manufactureDates: [2024],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac14,15":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .m2,
        manufactureDates: [2023],
        screenSizeInInches: 15.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac14,2":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .m2,
        manufactureDates: [2022],
        newestCompatibleOS: .sequoia
      )
    case "MacBookAir10,1":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2020],
        newestCompatibleOS: .sequoia
      )
    case "MacBookAir9,1":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2020],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .sequoia
      )
    case "MacBookAir8,2":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .sonoma
      )
    case "MacBookAir8,1":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2018],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .sonoma
      )
    case "MacBookAir7,2":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .monterey
      )
    case "MacBookAir7,1":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.early(2015)],
        screenSizeInInches: 11.0,
        newestCompatibleOS: .monterey
      )
    case "MacBookAir6,2":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2013), .early(2014)],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .bigSur
      )
    case "MacBookAir6,1":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2013), .early(2014)],
        screenSizeInInches: 11.0,
        newestCompatibleOS: .bigSur
      )
    case "MacBookAir5,2":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2012)],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .catalina
      )
    case "MacBookAir5,1":
      .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2012)],
        screenSizeInInches: 11.0,
        newestCompatibleOS: .catalina
      )
    // Macbook Pro @link https://support.apple.com/en-us/HT201300
    case "Mac16,1", "Mac16,6", "Mac16,8":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m4,
        manufactureDates: [2024],
        screenSizeInInches: 14.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac16,7", "Mac16,5":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m4,
        manufactureDates: [2024],
        screenSizeInInches: 16.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac15,3", "Mac15,6", "Mac15,8", "Mac15,10":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m3,
        manufactureDates: [.late(2023)],
        screenSizeInInches: 14.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac15,7", "Mac15,9", "Mac15,11":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m3,
        manufactureDates: [.late(2023)],
        screenSizeInInches: 16.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac14,5", "Mac14,9":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m2,
        manufactureDates: [2023],
        screenSizeInInches: 14.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac14,10", "Mac14,6":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m2,
        manufactureDates: [2023],
        screenSizeInInches: 16.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac14,7":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m2,
        manufactureDates: [2022],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .sequoia
      )
    case "MacBookPro18,3", "MacBookPro18,4":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2021],
        screenSizeInInches: 14.0,
        newestCompatibleOS: .sequoia
      )
    case "MacBookPro18,1", "MacBookPro18,2":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2021],
        screenSizeInInches: 16.0,
        newestCompatibleOS: .sequoia
      )
    case "MacBookPro17,1":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2020],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .sequoia
      )
    case "MacBookPro16,3", "MacBookPro16,2":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2020],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .sequoia
      )
    case "MacBookPro16,1", "MacBookPro16,4":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 16.0,
        newestCompatibleOS: .sequoia
      )
    case "MacBookPro15,4":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .sequoia
      )
    case "MacBookPro15,1":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2018, 2019],
        screenSizeInInches: 15.0,
        newestCompatibleOS: .sequoia
      )
    case "MacBookPro15,3":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 15,
        newestCompatibleOS: .sequoia
      )
    case "MacBookPro15,2":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2018, 2019],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .sequoia
      )
    case "MacBookPro14,3":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 15.0,
        newestCompatibleOS: .ventura
      )
    case "MacBookPro14,2", "MacBookPro14,1":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .ventura
      )
    case "MacBookPro13,3":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2016],
        screenSizeInInches: 15.0,
        newestCompatibleOS: .monterey
      )
    case "MacBookPro13,2", "MacBookPro13,1":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2016],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .monterey
      )
    case "MacBookPro11,4", "MacBookPro11,5":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2015)],
        screenSizeInInches: 15.0,
        newestCompatibleOS: .monterey
      )
    case "MacBookPro12,1":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.early(2015)],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .monterey
      )
    case "MacBookPro11,2", "MacBookPro11,3":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2013), .mid(2014)],
        screenSizeInInches: 15.0,
        newestCompatibleOS: .bigSur
      )
    case "MacBookPro11,1":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2013), .mid(2014)],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .bigSur
      )
    case "MacBookPro10,1":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2012), .early(2013)],
        screenSizeInInches: 15.0,
        newestCompatibleOS: .catalina
      )
    case "MacBookPro10,2":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2012), .early(2013)],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .catalina
      )
    case "MacBookPro9,1":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2012)],
        screenSizeInInches: 15.0,
        newestCompatibleOS: .catalina
      )
    case "MacBookPro9,2":
      .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2012)],
        screenSizeInInches: 13.0,
        newestCompatibleOS: .catalina
      )
    // iMac @link https://support.apple.com/en-us/HT201634
    case "Mac16,3", "Mac16,2":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .m4,
        manufactureDates: [2024],
        screenSizeInInches: 24.0,
        newestCompatibleOS: .sequoia
      )
    case "Mac15,5", "Mac15,4":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .m3,
        manufactureDates: [2023],
        screenSizeInInches: 24.0,
        newestCompatibleOS: .sequoia
      )
    case "iMac21,1", "iMac21,2":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2021],
        screenSizeInInches: 24.0,
        newestCompatibleOS: .sequoia
      )
    case "iMac20,1", "iMac20,2":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2020],
        screenSizeInInches: 27,
        newestCompatibleOS: .sequoia
      )
    case "iMac19,1":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 27.0,
        newestCompatibleOS: .sequoia
      )
    case "iMac19,2":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 21.5,
        newestCompatibleOS: .sequoia
      )
    case "iMacPro1,1":
      .init(
        type: .iMacPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 27.0,
        newestCompatibleOS: .sequoia
      )
    case "iMac18,3":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 27.0,
        newestCompatibleOS: .ventura
      )
    case "iMac18,2", "iMac18,1":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 21.5,
        newestCompatibleOS: .ventura
      )
    case "iMac17,1":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2015)],
        screenSizeInInches: 27.0,
        newestCompatibleOS: .monterey
      )
    case "iMac16,2", "iMac16,1":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2015)],
        screenSizeInInches: 21.5,
        newestCompatibleOS: .monterey
      )
    case "iMac15,1":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2014), .mid(2015)],
        screenSizeInInches: 27.0,
        newestCompatibleOS: .monterey
      )
    case "iMac14,4":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2014)],
        screenSizeInInches: 21.5,
        newestCompatibleOS: .bigSur
      )
    case "iMac14,2", "iMac14,3":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2013)],
        screenSizeInInches: 27.0,
        newestCompatibleOS: .catalina
      )
    case "iMac14,1":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2013)],
        screenSizeInInches: 21.5,
        newestCompatibleOS: .catalina
      )
    case "iMac13,2":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2012)],
        screenSizeInInches: 27.0,
        newestCompatibleOS: .catalina
      )
    case "iMac13,1":
      .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2012)],
        screenSizeInInches: 21.5,
        newestCompatibleOS: .catalina
      )
    // Mac Mini @link https://support.apple.com/en-us/HT201894
    case "Mac16,11", "Mac16,10":
      .init(
        type: .mini,
        identifier: modelIdentifier,
        chip: .m4,
        manufactureDates: [2024],
        newestCompatibleOS: .sequoia
      )
    case "Mac14,3", "Mac14,12":
      .init(
        type: .mini,
        identifier: modelIdentifier,
        chip: .m2,
        manufactureDates: [2023],
        newestCompatibleOS: .sequoia
      )
    case "Macmini9,1":
      .init(
        type: .mini,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2020],
        newestCompatibleOS: .sequoia
      )
    case "Macmini8,1":
      .init(
        type: .mini,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2018],
        newestCompatibleOS: .sequoia
      )
    case "Macmini7,1":
      .init(
        type: .mini,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2014)],
        newestCompatibleOS: .monterey
      )
    case "Macmini6,1", "Macmini6,2":
      .init(
        type: .mini,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2012)],
        newestCompatibleOS: .catalina
      )
    // Mac Studio @link https://support.apple.com/en-us/HT213073
    case "Mac16,9":
      .init(
        type: .studio,
        identifier: modelIdentifier,
        chip: .m4,
        manufactureDates: [2025],
        newestCompatibleOS: .sequoia
      )
    case "Mac15,14":
      .init(
        type: .studio,
        identifier: modelIdentifier,
        chip: .m3,
        manufactureDates: [2025],
        newestCompatibleOS: .sequoia
      )
    case "Mac14,13", "Mac14,14":
      .init(
        type: .studio,
        identifier: modelIdentifier,
        chip: .m2,
        manufactureDates: [2023],
        newestCompatibleOS: .sequoia
      )
    case "Mac13,1":
      .init(
        type: .studio,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2022],
        newestCompatibleOS: .sequoia
      )
    case "Mac13,2":
      .init(
        type: .studio,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2022],
        newestCompatibleOS: .sequoia
      )
    // Mac Pro @link https://support.apple.com/en-us/HT202888
    case "Mac14,8":
      .init(
        type: .pro,
        identifier: modelIdentifier,
        chip: .m2,
        manufactureDates: [2023],
        newestCompatibleOS: .sequoia
      )
    case "MacPro7,1":
      .init(
        type: .pro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        newestCompatibleOS: .sequoia
      )
    case "MacPro6,1":
      .init(
        type: .pro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2013)],
        newestCompatibleOS: .monterey
      )
    // Macbook @link https://support.apple.com/en-us/HT201608
    case "Macbook10,1":
      .init(
        type: .macBook,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 12.0,
        newestCompatibleOS: .sequoia
      )
    case "Macbook9,1":
      .init(
        type: .macBook,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.early(2016)],
        screenSizeInInches: 12.0,
        newestCompatibleOS: .monterey
      )
    case "Macbook8,1":
      .init(
        type: .macBook,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.early(2015)],
        screenSizeInInches: 12.0,
        newestCompatibleOS: .bigSur
      )
    default:
      .unknown
    }
  }
}
