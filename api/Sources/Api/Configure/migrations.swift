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
  }
}
