import Dependencies
import FluentSQL
import Foundation

struct IOSConnection: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await self.screenshotsUp(sql)
    try await self.tokensUp(sql)
    try await self.suspendRequestsUp(sql)
    try await self.blockRuleDeviceIdUp(sql)
  }

  func down(sql: SQLDatabase) async throws {
    if get(dependency: \.env).mode == .prod {
      let rows = try await sql.execute("""
        SELECT COUNT(*) FROM child.screenshots
        WHERE computer_user_id IS NULL;
      """)
      let decoded = try rows[0].decode(model: Count.self)
      guard decoded.count == 0 else {
        fatalError("Halting to prevent ios screenshots data loss")
      }
    }
    try await self.blockRuleDeviceIdDown(sql)
    try await self.suspendRequestsDown(sql)
    try await self.tokensDown(sql)
    try await self.screenshotsDown(sql)
  }

  func blockRuleDeviceIdUp(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      ADD COLUMN device_id UUID;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.block_rules
      ADD CONSTRAINT fk_block_rules_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)
  }

  func blockRuleDeviceIdDown(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      DROP COLUMN device_id;
    """)
  }

  func suspendRequestsUp(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE iosapp.suspend_filter_requests (
        id uuid NOT NULL,
        device_id uuid NOT NULL,
        status public.enum_shared_request_status NOT NULL,
        duration bigint NOT NULL,
        request_comment text,
        response_comment text,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.suspend_filter_requests
      ADD CONSTRAINT iosapp_suspend_filter_requests_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.suspend_filter_requests
      ADD CONSTRAINT fk_suspend_filter_requests_iosapp_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)
  }

  func suspendRequestsDown(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP TABLE iosapp.suspend_filter_requests;
    """)
  }

  func tokensUp(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE child.iosapp_tokens (
        id uuid NOT NULL,
        value uuid NOT NULL,
        device_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.iosapp_tokens
      ADD CONSTRAINT iosapp_tokens_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.iosapp_tokens
      ADD CONSTRAINT uq_iosapp_tokens_value UNIQUE (value);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.iosapp_tokens
      ADD CONSTRAINT fk_iosapp_tokens_ios_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)
  }

  func tokensDown(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP TABLE child.iosapp_tokens;
    """)
  }

  func screenshotsUp(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE child.ios_devices (
        id uuid NOT NULL,
        child_id uuid NOT NULL,
        vendor_id uuid NOT NULL,
        device_type varchar(32) NOT NULL,
        app_version varchar(32) NOT NULL,
        ios_version varchar(32) NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.ios_devices
      ADD CONSTRAINT ios_devices_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.ios_devices
      ADD CONSTRAINT fk_ios_devices_child_id
      FOREIGN KEY (child_id)
      REFERENCES parent.children(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE macapp.screenshots
      SET SCHEMA child;
    """)

    try await sql.execute("""
      ALTER TABLE child.screenshots
      ADD COLUMN ios_device_id UUID;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.screenshots
      ADD CONSTRAINT fk_screenshots_ios_device_id
      FOREIGN KEY (ios_device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE child.screenshots
      ALTER COLUMN computer_user_id DROP NOT NULL;
    """)
  }

  func screenshotsDown(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      DELETE FROM child.screenshots
      WHERE computer_user_id IS NULL;
    """)

    try await sql.execute("""
      ALTER TABLE child.screenshots
      DROP COLUMN ios_device_id;
    """)

    try await sql.execute("""
      DROP TABLE child.ios_devices;
    """)

    try await sql.execute("""
      ALTER TABLE child.screenshots
      SET SCHEMA macapp;
    """)

    try await sql.execute("""
      ALTER TABLE macapp.screenshots
      ALTER COLUMN computer_user_id SET NOT NULL;
    """)
  }
}

private struct Count: Decodable {
  var count: Int
}
