import FluentSQL
import Gertie
import XCore

struct DeviceRefactor: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    let records = try await getPreMigrationDeviceData(sql)

    // remove all the FKs while we're moving things around
    try await dropDeviceIdForeignKeys(sql)

    // change all of those `device_id` columns to `user_device_id`
    try await renameDeviceIdColumns(sql)

    // convert the `devices` table to `user_devices`, dropping/adding cols
    try await convertDeviceTableToUserDeviceTable(sql)

    // create new `devices` table
    try await createNewDevicesTable(sql)

    // fill the two tables with the correct pre-migration data
    try await restorePreMigrationData(sql, records)

    // set new foreign keys, remove defaults, temp stuff during migration
    try await setNewConstraints(sql)
  }

  func down(sql: SQLDatabase) async throws {
    let records = try await getPostMigrationDeviceData(sql)

    try await undoSetNewConstraints(sql)
    try await undoCreateNewDevicesTable(sql)
    try await undoConvertDeviceTableToUserDeviceTable(sql)
    try await undoRenameDeviceIdColumns(sql)
    try await revertPostMigrationData(sql, records)
    try await undoDropDeviceIdForeignKeys(sql)
  }

  private func restorePreMigrationData(
    _ sql: SQLDatabase,
    _ records: [PreMigrationDeviceData]
  ) async throws {
    typealias SerialNumber = String
    struct DeviceData {
      var id: Device.Id
      var adminId: Admin.Id
      var customName: String?
      var modelIdentifier: String
      var serialNumber: SerialNumber
      var createdAt: Date
      var updatedAt: Date
    }

    var map: [SerialNumber: DeviceData] = [:]
    for record in records {
      var device = map[record.serialNumber] ?? DeviceData(
        id: Device.Id(),
        adminId: .init(record.adminId),
        customName: record.customName,
        modelIdentifier: record.modelIdentifier,
        serialNumber: record.serialNumber,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt
      )

      // keep the shortest custom name
      if device.customName == nil {
        device.customName = record.customName
      } else if let existingCustomName = device.customName,
                let recordCustomName = record.customName,
                existingCustomName.count > recordCustomName.count {
        device.customName = record.customName
      }

      // keep the earliest createdAt
      if record.createdAt < device.createdAt {
        device.createdAt = record.createdAt
      }

      // and the latest updatedAt
      if record.updatedAt > device.updatedAt {
        device.updatedAt = record.updatedAt
      }

      map[record.serialNumber] = device

      try await sql.execute(
        """
        UPDATE \(table: UserDevice.M11.self) SET
        "\(col: UserDevice.M11.deviceId)" = '\(id: device.id)',
        "\(col: .createdAt)" = '\(timestamp: record.createdAt)',
        "\(col: .updatedAt)" = '\(timestamp: record.updatedAt)'
        WHERE "\(col: .id)" = '\(uuid: record.id)';
        """
      )
    }
    for device in map.values {
      try await sql.execute(
        """
        INSERT INTO \(table: Device.M3.self) (
          "\(col: .id)",
          "\(col: Device.M11.adminId)",
          "\(col: Device.M11.customName)",
          "\(col: Device.M11.modelIdentifier)",
          "\(col: Device.M11.serialNumber)",
          "\(col: Device.M11.appReleaseChannel)",
          "\(col: .createdAt)",
          "\(col: .updatedAt)"
        ) VALUES (
          '\(id: device.id)',
          '\(id: device.adminId)',
          \(nullable: device.customName),
          '\(escaping: device.modelIdentifier)',
          '\(raw: device.serialNumber)',
          'stable',
          '\(timestamp: device.createdAt)',
          '\(timestamp: device.updatedAt)'
        );
        """
      )
    }
  }

  private func revertPostMigrationData(
    _ sql: SQLDatabase,
    _ records: [PostMigrationDeviceData]
  ) async throws {
    try await sql.execute("DELETE FROM \(table: Device.M3.self)")
    for record in records {
      try await sql.execute(
        """
        INSERT INTO \(table: Device.M3.self) (
          "\(col: .id)",
          "\(col: Device.M3.userId)",
          "\(col: Device.M3.appVersion)",
          "\(col: Device.M3.customName)",
          "\(col: Device.M3.modelIdentifier)",
          "\(col: Device.M3.username)",
          "\(col: Device.M3.fullUsername)",
          "\(col: Device.M3.numericId)",
          "\(col: Device.M3.serialNumber)",
          "\(col: .createdAt)",
          "\(col: .updatedAt)"
        ) VALUES (
          '\(uuid: record.id)',
          '\(uuid: record.userId)',
          '\(raw: record.appVersion)',
          \(nullable: record.customName),
          '\(escaping: record.modelIdentifier)',
          '\(escaping: record.username)',
          '\(escaping: record.fullUsername)',
          \(literal: record.numericId),
          '\(raw: record.serialNumber)',
          '\(timestamp: record.createdAt)',
          '\(timestamp: record.updatedAt)'
        );
        """
      )
    }
  }

  let deviceAdminIdFk = Constraint.foreignKey(
    from: Device.M3.self,
    to: Admin.M1.self,
    thru: Device.M11.adminId,
    onDelete: .cascade
  )

  func createNewDevicesTable(_ sql: SQLDatabase) async throws {
    try await sql.create(table: Device.M3.self) {
      Column(.id, .uuid, .primaryKey)
      Column(Device.M11.adminId, .uuid)
      Column(Device.M11.customName, .text, .nullable)
      Column(Device.M11.modelIdentifier, .text)
      Column(Device.M11.serialNumber, .text)
      Column(Device.M11.appReleaseChannel, .enum(ReleaseChannel.self))
      Column(.createdAt, .timestampWithTimezone)
      Column(.updatedAt, .timestampWithTimezone)
    }

    try await sql.add(constraint: self.deviceAdminIdFk)
    try await sql.add(constraint: .unique(Device.M3.self, Device.M11.serialNumber))
  }

  func undoCreateNewDevicesTable(_ sql: SQLDatabase) async throws {
    try await sql.drop(table: Device.M3.self)
  }

  func convertDeviceTableToUserDeviceTable(_ sql: SQLDatabase) async throws {
    try await sql.renameTable(from: Device.M3.self, to: UserDevice.M11.self)

    try await sql.dropColumn(Device.M3.serialNumber, on: UserDevice.M11.self)
    try await sql.dropColumn(Device.M3.customName, on: UserDevice.M11.self)
    try await sql.dropColumn(Device.M3.hostname, on: UserDevice.M11.self)
    try await sql.dropColumn(Device.M3.modelIdentifier, on: UserDevice.M11.self)

    try await sql.addColumn(
      UserDevice.M11.deviceId,
      on: UserDevice.M11.self,
      type: .uuid,
      // temporary device id, will replace later, and add FK
      default: .uuid(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    )
  }

  func undoConvertDeviceTableToUserDeviceTable(_ sql: SQLDatabase) async throws {
    try await sql.dropColumn(UserDevice.M11.deviceId, on: UserDevice.M11.self)

    try await sql.addColumn(
      Device.M3.customName,
      on: UserDevice.M11.self,
      type: .text,
      nullable: true
    )
    try await sql.addColumn(
      Device.M3.hostname,
      on: UserDevice.M11.self,
      type: .text,
      nullable: true
    )
    try await sql.addColumn(
      Device.M3.modelIdentifier,
      on: UserDevice.M11.self,
      type: .text,
      default: .text("temp")
    )
    try await sql.addColumn(
      Device.M3.serialNumber,
      on: UserDevice.M11.self,
      type: .text,
      default: .text("temp")
    )

    try await sql.dropDefault(from: Device.M3.modelIdentifier, on: UserDevice.M11.self)
    try await sql.dropDefault(from: Device.M3.serialNumber, on: UserDevice.M11.self)
    try await sql.renameTable(from: UserDevice.M11.self, to: Device.M3.self)
  }

  func dropDeviceIdForeignKeys(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: RequestTables().networkDecisionDeviceFk)
    try await sql.drop(constraint: RequestTables().unlockRequestDeviceFk)
    try await sql.drop(constraint: RequestTables().suspendFilterRequestFk)
    try await sql.drop(constraint: InterestingEventsTable().deviceIdFk)
    try await sql.drop(constraint: ActivityTables().screenshotsFk)
    try await sql.drop(constraint: ActivityTables().keystrokeLinesFk)
    try await sql.drop(constraint: UserTables().userTokensDeviceFk)
  }

  func undoDropDeviceIdForeignKeys(_ sql: SQLDatabase) async throws {
    try await sql.add(constraint: RequestTables().networkDecisionDeviceFk)
    try await sql.add(constraint: RequestTables().unlockRequestDeviceFk)
    try await sql.add(constraint: RequestTables().suspendFilterRequestFk)
    try await sql.add(constraint: InterestingEventsTable().deviceIdFk)
    try await sql.add(constraint: ActivityTables().screenshotsFk)
    try await sql.add(constraint: ActivityTables().keystrokeLinesFk)
    try await sql.add(constraint: UserTables().userTokensDeviceFk)
  }

  let networkDecisionFk = Constraint.foreignKey(
    from: Deleted.NetworkDecisionTable.M5.self,
    to: UserDevice.M11.self,
    thru: Deleted.NetworkDecisionTable.M11.userDeviceId,
    onDelete: .cascade
  )

  let unlockRequestFk = Constraint.foreignKey(
    from: UnlockRequest.M5.self,
    to: UserDevice.M11.self,
    thru: UnlockRequest.M11.userDeviceId,
    onDelete: .cascade
  )

  let suspendFilterRequestFk = Constraint.foreignKey(
    from: SuspendFilterRequest.M5.self,
    to: UserDevice.M11.self,
    thru: SuspendFilterRequest.M11.userDeviceId,
    onDelete: .cascade
  )

  let interestingEventFk = Constraint.foreignKey(
    from: InterestingEvent.M8.self,
    to: UserDevice.M11.self,
    thru: InterestingEvent.M11.userDeviceId,
    onDelete: .cascade
  )

  let screenshotFk = Constraint.foreignKey(
    from: Screenshot.M4.self,
    to: UserDevice.M11.self,
    thru: Screenshot.M11.userDeviceId,
    onDelete: .cascade
  )

  let keystrokeLineFk = Constraint.foreignKey(
    from: KeystrokeLine.M4.self,
    to: UserDevice.M11.self,
    thru: KeystrokeLine.M11.userDeviceId,
    onDelete: .cascade
  )

  let userTokenFk = Constraint.foreignKey(
    from: UserToken.M3.self,
    to: UserDevice.M11.self,
    thru: UserToken.M11.userDeviceId,
    onDelete: .cascade
  )

  func setNewConstraints(_ sql: SQLDatabase) async throws {
    try await sql.add(constraint: self.networkDecisionFk)
    try await sql.add(constraint: self.unlockRequestFk)
    try await sql.add(constraint: self.suspendFilterRequestFk)
    try await sql.add(constraint: self.interestingEventFk)
    try await sql.add(constraint: self.screenshotFk)
    try await sql.add(constraint: self.keystrokeLineFk)
    try await sql.add(constraint: self.userTokenFk)
    try await sql.dropDefault(from: UserDevice.M11.deviceId, on: UserDevice.M11.self)
  }

  func undoSetNewConstraints(_ sql: SQLDatabase) async throws {
    try await sql.drop(constraint: self.networkDecisionFk)
    try await sql.drop(constraint: self.unlockRequestFk)
    try await sql.drop(constraint: self.suspendFilterRequestFk)
    try await sql.drop(constraint: self.interestingEventFk)
    try await sql.drop(constraint: self.screenshotFk)
    try await sql.drop(constraint: self.keystrokeLineFk)
    try await sql.drop(constraint: self.userTokenFk)
    try await sql.addDefault(
      of: .uuid(.init(uuidString: "00000000-0000-0000-0000-000000000000")!),
      to: UserDevice.M11.deviceId,
      on: UserDevice.M11.self
    )
  }

  func renameDeviceIdColumns(_ sql: SQLDatabase) async throws {
    try await sql.renameColumn(
      on: InterestingEvent.M8.self,
      from: InterestingEvent.M8.deviceId,
      to: InterestingEvent.M11.userDeviceId
    )
    try await sql.renameColumn(
      on: KeystrokeLine.M4.self,
      from: KeystrokeLine.M4.deviceId,
      to: KeystrokeLine.M11.userDeviceId
    )
    try await sql.renameColumn(
      on: Screenshot.M4.self,
      from: Screenshot.M4.deviceId,
      to: Screenshot.M11.userDeviceId
    )
    try await sql.renameColumn(
      on: Deleted.NetworkDecisionTable.M5.self,
      from: Deleted.NetworkDecisionTable.M5.deviceId,
      to: Deleted.NetworkDecisionTable.M11.userDeviceId
    )
    try await sql.renameColumn(
      on: UnlockRequest.M5.self,
      from: UnlockRequest.M5.deviceId,
      to: UnlockRequest.M11.userDeviceId
    )
    try await sql.renameColumn(
      on: SuspendFilterRequest.M5.self,
      from: SuspendFilterRequest.M5.deviceId,
      to: SuspendFilterRequest.M11.userDeviceId
    )
    try await sql.renameColumn(
      on: UserToken.M3.self,
      from: UserToken.M3.deviceId,
      to: UserToken.M11.userDeviceId
    )
  }

  func undoRenameDeviceIdColumns(_ sql: SQLDatabase) async throws {
    try await sql.renameColumn(
      on: InterestingEvent.M8.self,
      from: InterestingEvent.M11.userDeviceId,
      to: InterestingEvent.M8.deviceId
    )
    try await sql.renameColumn(
      on: KeystrokeLine.M4.self,
      from: KeystrokeLine.M11.userDeviceId,
      to: KeystrokeLine.M4.deviceId
    )
    try await sql.renameColumn(
      on: Screenshot.M4.self,
      from: Screenshot.M11.userDeviceId,
      to: Screenshot.M4.deviceId
    )
    try await sql.renameColumn(
      on: Deleted.NetworkDecisionTable.M5.self,
      from: Deleted.NetworkDecisionTable.M11.userDeviceId,
      to: Deleted.NetworkDecisionTable.M5.deviceId
    )
    try await sql.renameColumn(
      on: UnlockRequest.M5.self,
      from: UnlockRequest.M11.userDeviceId,
      to: UnlockRequest.M5.deviceId
    )
    try await sql.renameColumn(
      on: SuspendFilterRequest.M5.self,
      from: SuspendFilterRequest.M11.userDeviceId,
      to: SuspendFilterRequest.M5.deviceId
    )
    try await sql.renameColumn(
      on: UserToken.M3.self,
      from: UserToken.M11.userDeviceId,
      to: UserToken.M3.deviceId
    )
  }
}

// data conversion helpers

private struct PreMigrationDeviceData: Codable {
  var id: UUID
  var adminId: UUID
  var customName: String?
  var modelIdentifier: String
  var serialNumber: String
  var createdAt: Date
  var updatedAt: Date
}

private func getPreMigrationDeviceData(_ sql: SQLDatabase) async throws
  -> [PreMigrationDeviceData] {
  let rows = try await sql.execute("""
    SELECT devices.*, users.admin_id FROM devices
    LEFT JOIN users ON users.id = user_id;
  """)

  return try rows.map { try $0.decode(
    model: PreMigrationDeviceData.self,
    prefix: nil,
    keyDecodingStrategy: .convertFromSnakeCase
  ) }
}

private struct PostMigrationDeviceData: Codable {
  var id: UUID
  var userId: UUID
  var appVersion: String
  var username: String
  var fullUsername: String
  var numericId: Int
  var modelIdentifier: String
  var serialNumber: String
  var customName: String?
  var createdAt: Date
  var updatedAt: Date
}

private func getPostMigrationDeviceData(_ sql: SQLDatabase) async throws
  -> [PostMigrationDeviceData] {
  let rows = try await sql.execute("""
    SELECT
      user_devices.*,
      devices.model_identifier, devices.serial_number, devices.custom_name
    FROM user_devices
    LEFT JOIN devices ON user_devices.device_id = devices.id;
  """)

  return try rows.map { try $0.decode(
    model: PostMigrationDeviceData.self,
    prefix: nil,
    keyDecodingStrategy: .convertFromSnakeCase
  ) }
}

// migration extensions

extension UserDevice {
  enum M11: TableNamingMigration {
    static let tableName = "user_devices"
    static let userId = FieldKey("user_id")
    static let deviceId = FieldKey("device_id")
    static let appVersion = FieldKey("app_version")
    static let username = FieldKey("username")
    static let fullUsername = FieldKey("full_username")
    static let numericId = FieldKey("numeric_id")
  }
}

extension Device {
  enum M11 {
    static let adminId = FieldKey("admin_id")
    static let customName = FieldKey("custom_name")
    static let hostname = FieldKey("hostname")
    static let modelIdentifier = FieldKey("model_identifier")
    static let serialNumber = FieldKey("serial_number")
    static let appReleaseChannel = FieldKey("app_release_channel")
  }
}

extension InterestingEvent {
  enum M11 {
    static let userDeviceId = FieldKey("user_device_id")
  }
}

extension KeystrokeLine {
  enum M11 {
    static let userDeviceId = FieldKey("user_device_id")
  }
}

extension Screenshot {
  enum M11 {
    static let userDeviceId = FieldKey("user_device_id")
  }
}

extension Deleted.NetworkDecisionTable {
  enum M11 {
    static let userDeviceId = FieldKey("user_device_id")
  }
}

extension UnlockRequest {
  enum M11 {
    static let userDeviceId = FieldKey("user_device_id")
  }
}

extension SuspendFilterRequest {
  enum M11 {
    static let userDeviceId = FieldKey("user_device_id")
  }
}

extension UserToken {
  enum M11 {
    static let userDeviceId = FieldKey("user_device_id")
  }
}
