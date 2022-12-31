import Shared

extension Device {
  struct Model: Encodable {
    var type: Kind
    var identifier: String
    var chip: Chip
    var manufactureDates: Set<ManufactureDate>
    var screenSizeInInches: Float?
    var newestCompatibleOS: MacOS?

    init(
      type: Kind,
      identifier: String,
      chip: Device.Model.Chip,
      manufactureDates: Set<Device.Model.ManufactureDate> = [],
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

extension Device.Model {
  enum Kind: String, Encodable, CaseIterable {
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

extension Device.Model {
  var shortDescription: String {
    var desc = type.rawValue
    let chipDesc = chip.madeByApple ? "\(chip.family.rawValue) " : ""
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

extension Device.Model {
  var family: DeviceModelFamily {
    switch type {
    case .macBookAir:
      return .macBookAir
    case .macBookPro:
      return .macBookPro
    case .mini:
      return .mini
    case .iMac, .iMacPro:
      return .iMac
    case .studio:
      return .studio
    case .pro:
      return .pro
    case .unknown:
      return .unknown
    }
  }
}

extension Device.Model {
  enum Chip: Encodable {
    case m2
    case m1Max
    case m1Ultra
    case m1
    case intel
  }
}

extension Device.Model.Chip {
  enum Family: String {
    case m2 = "M2"
    case m1 = "M1"
    case intel = "Intel"
  }

  var family: Family {
    switch self {
    case .m2:
      return .m2
    case .m1Max, .m1Ultra, .m1:
      return .m1
    case .intel:
      return .intel
    }
  }

  var madeByApple: Bool {
    switch self {
    case .intel:
      return false
    default:
      return true
    }
  }
}

enum MacOS: Encodable {
  case ventura
  case monterey
  case bigSur
  case catalina
}

extension Device.Model {
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

extension Device.Model {
  static let unknown = Self(type: .unknown, identifier: "unknown", chip: .m1)
}

extension Device.Model.ManufactureDate: ExpressibleByIntegerLiteral {
  init(integerLiteral value: Int) {
    self.init(year: value)
  }
}

extension Device.Model.ManufactureDate {
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

extension Device {
  var model: Model {
    switch modelIdentifier {
    // MacBook Air @link https://support.apple.com/en-us/HT201862
    case "Mac14,2":
      return .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .m2,
        manufactureDates: [2022]
      )
    case "MacBookAir10,1":
      return .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2020]
      )
    case "MacBookAir9,1":
      return .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2020],
        screenSizeInInches: 13
      )
    case "MacBookAir8,2":
      return .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 13
      )
    case "MacBookAir8,1":
      return .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2018],
        screenSizeInInches: 13
      )
    case "MacBookAir7,2":
      return .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 13
      )
    case "MacBookAir7,1":
      return .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.early(2015)],
        screenSizeInInches: 11
      )
    case "MacBookAir6,2":
      return .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2013), .early(2014)],
        screenSizeInInches: 13,
        newestCompatibleOS: .bigSur
      )
    case "MacBookAir6,1":
      return .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2013), .early(2014)],
        screenSizeInInches: 11,
        newestCompatibleOS: .bigSur
      )
    case "MacBookAir5,2":
      return .init(
        type: .macBookAir,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2012)],
        screenSizeInInches: 13,
        newestCompatibleOS: .catalina // lol for eden
      )
    // Macbook Pro @link https://support.apple.com/en-us/HT201300
    case "Mac14,7":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m2,
        manufactureDates: [2022],
        screenSizeInInches: 13
      )
    case "MacBookPro18,3", "MacBookPro18,4":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2021],
        screenSizeInInches: 14
      )
    case "MacBookPro18,1", "MacBookPro18,2":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2021],
        screenSizeInInches: 16
      )
    case "MacBookPro17,1":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2020],
        screenSizeInInches: 13
      )
    case "MacBookPro16,3", "MacBookPro16,2":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2020],
        screenSizeInInches: 13
      )
    case "MacBookPro16,1", "MacBookPro16,4":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 16
      )
    case "MacBookPro15,4":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 13
      )
    case "MacBookPro15,1":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2018, 2019],
        screenSizeInInches: 15
      )
    case "MacBookPro15,3":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 15
      )
    case "MacBookPro15,2":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2018, 2019],
        screenSizeInInches: 13
      )
    case "MacBookPro14,3":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 15
      )
    case "MacBookPro14,2", "MacBookPro14,1":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 13
      )
    case "MacBookPro13,3":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2016],
        screenSizeInInches: 15
      )
    case "MacBookPro13,2", "MacBookPro13,1":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2016],
        screenSizeInInches: 13
      )
    case "MacBookPro11,4", "MacBookPro11,5":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2015)],
        screenSizeInInches: 15
      )
    case "MacBookPro12,1":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.early(2015)],
        screenSizeInInches: 13
      )
    case "MacBookPro11,2", "MacBookPro11,3":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2013), .mid(2014)],
        screenSizeInInches: 15,
        newestCompatibleOS: .bigSur
      )
    case "MacBookPro11,1":
      return .init(
        type: .macBookPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2013), .mid(2014)],
        screenSizeInInches: 13,
        newestCompatibleOS: .bigSur
      )
    // iMac @link https://support.apple.com/en-us/HT201634
    case "iMac21,1", "iMac21,2":
      return .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2021],
        screenSizeInInches: 24
      )
    case "iMac20,1, iMac20,2":
      return .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2020],
        screenSizeInInches: 27
      )
    case "iMac19,1":
      return .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 27
      )
    case "iMac19,2":
      return .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019],
        screenSizeInInches: 21.5
      )
    case "iMacPro1,1":
      return .init(
        type: .iMacPro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 27
      )
    case "iMac18,3":
      return .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 27
      )
    case "iMac18,2", "iMac18,1":
      return .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2017],
        screenSizeInInches: 21.5
      )
    case "iMac17,1":
      return .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2015)],
        screenSizeInInches: 27
      )
    case "iMac16,2", "iMac16,1":
      return .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2015)],
        screenSizeInInches: 21.5
      )
    case "iMac15,1":
      return .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2014), .mid(2015)],
        screenSizeInInches: 27
      )
    case "iMac14,4":
      return .init(
        type: .iMac,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.mid(2014)],
        screenSizeInInches: 21.5,
        newestCompatibleOS: .bigSur
      )

    // Mac Mini @link https://support.apple.com/en-us/HT201894
    case "Macmini9,1":
      return .init(
        type: .mini,
        identifier: modelIdentifier,
        chip: .m1,
        manufactureDates: [2020]
      )
    case "Macmini8,1":
      return .init(
        type: .mini,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2018]
      )
    case "Macmini7,1":
      return .init(
        type: .mini,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2014)]
      )
    // Mac Studio @link https://support.apple.com/en-us/HT213073
    case "Mac13,1":
      return .init(
        type: .studio,
        identifier: modelIdentifier,
        chip: .m1Max,
        manufactureDates: [2022]
      )
    case "Mac13,2":
      return .init(
        type: .studio,
        identifier: modelIdentifier,
        chip: .m1Ultra,
        manufactureDates: [2022]
      )
    // Mac Pro @link https://support.apple.com/en-us/HT202888
    case "MacPro7,1":
      return .init(
        type: .pro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [2019]
      )
    case "MacPro6,1":
      return .init(
        type: .pro,
        identifier: modelIdentifier,
        chip: .intel,
        manufactureDates: [.late(2013)]
      )
    default:
      return .unknown
    }
  }
}
