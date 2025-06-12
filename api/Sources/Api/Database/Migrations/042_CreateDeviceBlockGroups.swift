import Dependencies
import FluentSQL
import Foundation

struct CreateDeviceBlockGroups: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE iosapp.device_block_groups (
        id uuid NOT NULL,
        device_id uuid NOT NULL,
        block_group_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.device_block_groups
      ADD CONSTRAINT device_block_groups_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.device_block_groups
      ADD CONSTRAINT fk_device_block_groups_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.device_block_groups
      ADD CONSTRAINT fk_device_block_groups_block_group_id
      FOREIGN KEY (block_group_id)
      REFERENCES iosapp.block_groups(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      CREATE INDEX idx_device_block_groups_device_id
      ON iosapp.device_block_groups USING btree (device_id);
    """)

    try await sql.execute("""
      CREATE INDEX idx_device_block_groups_block_group_id
      ON iosapp.device_block_groups USING btree (block_group_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP TABLE iosapp.device_block_groups;
    """)
  }
}
