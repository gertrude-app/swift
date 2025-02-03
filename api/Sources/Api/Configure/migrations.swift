import QueuesFluentDriver
import Vapor

extension Configure {
  static func migrations(_ app: Application) throws {
    app.migrations.add(AdminTables())
    app.migrations.add(KeychainTables())
    app.migrations.add(UserTables())
    app.migrations.add(ActivityTables())
    app.migrations.add(RequestTables())
    app.migrations.add(AppTables())
    app.migrations.add(MiscTables())
    app.migrations.add(JobMetadataMigrate())
    app.migrations.add(InterestingEventsTable())
    app.migrations.add(AddReleaseRequirementPace())
    app.migrations.add(DropWaitlistedAdmins())
    app.migrations.add(DeviceRefactor())
    app.migrations.add(AddReleaseNotes())
    app.migrations.add(DeviceIdForeignKey())
    app.migrations.add(DeviceFilterVersion())
    app.migrations.add(DuringSuspensionActivity())
    app.migrations.add(ReworkPayments())
    app.migrations.add(AddUserShowSuspensionActivity())
    app.migrations.add(EliminateNetworkDecisionsTable())
    app.migrations.add(AddAdminGclid())
    app.migrations.add(BrowsersTable())
    app.migrations.add(SecurityEvents())
    app.migrations.add(ABTestVariants())
    app.migrations.add(ModifySecurityEventsTable())
    app.migrations.add(AddExtraMonitoring())
    app.migrations.add(RemoveSoftDeletes())
    app.migrations.add(RemoveUserTokenNullable())
    app.migrations.add(ScreenshotDisplayId())
    app.migrations.add(RevertScreenshotDisplayId())
    app.migrations.add(UnidentifiedApps())
    app.migrations.add(ScheduleFeatures())
    app.migrations.add(AppBlockingFeature())
    app.migrations.add(IOSBlockRules())
    app.migrations.add(KeychainWarning())
    // not deleted after here...
    app.migrations.add(MultipleSchemas())
    app.migrations.add(RecreateTables())
  }
}

// deleted migrations

struct AdminTables: DeletedMigration {}
struct ActivityTables: DeletedMigration {}
struct DeviceFilterVersion: DeletedMigration {}
struct IOSBlockRules: DeletedMigration {}
struct AppBlockingFeature: DeletedMigration {}
struct AddExtraMonitoring: DeletedMigration {}
struct BrowsersTable: DeletedMigration {}
struct AddReleaseNotes: DeletedMigration {}
struct KeychainTables: DeletedMigration {}
struct DeviceRefactor: DeletedMigration {}
struct ModifySecurityEventsTable: DeletedMigration {}
struct KeychainWarning: DeletedMigration {}
struct DuringSuspensionActivity: DeletedMigration {}
struct ReworkPayments: DeletedMigration {}
struct DeviceIdForeignKey: DeletedMigration {}
struct UnidentifiedApps: DeletedMigration {}
struct ABTestVariants: DeletedMigration {}
struct EliminateNetworkDecisionsTable: DeletedMigration {}
struct RemoveUserTokenNullable: DeletedMigration {}
struct RemoveSoftDeletes: DeletedMigration {}
struct UserTables: DeletedMigration {}
struct AddUserShowSuspensionActivity: DeletedMigration {}
struct ScreenshotDisplayId: DeletedMigration {}
struct RevertScreenshotDisplayId: DeletedMigration {}
struct DropWaitlistedAdmins: DeletedMigration {}
struct InterestingEventsTable: DeletedMigration {}
struct MiscTables: DeletedMigration {}
struct AddAdminGclid: DeletedMigration {}
struct AppTables: DeletedMigration {}
struct ScheduleFeatures: DeletedMigration {}
struct RequestTables: DeletedMigration {}
struct AddReleaseRequirementPace: DeletedMigration {}
struct SecurityEvents: DeletedMigration {}
