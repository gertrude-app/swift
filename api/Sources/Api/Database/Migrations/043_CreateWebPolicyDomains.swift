import Dependencies
import FluentSQL
import Foundation

struct CreateWebPolicyDomains: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE iosapp.web_policy_domains (
        id uuid NOT NULL,
        device_id uuid NOT NULL,
        domain text NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.web_policy_domains
      ADD CONSTRAINT web_policy_domains_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.web_policy_domains
      ADD CONSTRAINT fk_web_policy_domains_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      CREATE INDEX idx_web_policy_domains_device_id
      ON iosapp.web_policy_domains USING btree (device_id);
    """)

    try await sql.execute("""
      ALTER TABLE child.ios_devices
      ADD COLUMN web_policy text NOT NULL DEFAULT 'blockAll';
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE child.ios_devices
      DROP COLUMN web_policy;
    """)

    try await sql.execute("""
      DROP TABLE iosapp.web_policy_domains;
    """)
  }
}
