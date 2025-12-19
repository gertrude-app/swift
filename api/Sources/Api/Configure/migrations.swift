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
    app.migrations.add(MultipleSchemas())
    // not deleted after here...
    app.migrations.add(RecreateTables())
    app.migrations.add(MarketingPrep())
    app.migrations.add(SearchPaths())
    app.migrations.add(FlaggedActivity())
    app.migrations.add(DashAnnouncements())
    app.migrations.add(IOSConnection())
    app.migrations.add(RenameParentNotifMethods())
    app.migrations.add(CreateBlockGroups())
    app.migrations.add(CreateDeviceBlockGroups())
    app.migrations.add(CreateWebPolicyDomains())
    app.migrations.add(ReencodeIOSBlockRules())
    app.migrations.add(PodcastEvents())
    app.migrations.add(AddSpotifyBlockGroup())
    app.migrations.add(ReleaseMinVersion())
    app.migrations.add(SuperAdminTokens())
    app.migrations.add(IOSEvents())
  }
}

// deleted migrations

// @see https://github.com/gertrude-app/swift/tree/833260d1
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
// @see https://github.com/gertrude-app/swift/tree/57c4073a
struct MultipleSchemas: DeletedMigration {}
