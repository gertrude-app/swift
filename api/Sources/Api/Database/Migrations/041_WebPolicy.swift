import Dependencies
import FluentSQL

struct WebPolicy: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE iosapp.web_policies (
        id uuid NOT NULL,
        device_id uuid NOT NULL,
        web_policy jsonb NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.web_policies
      ADD CONSTRAINT web_policies_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.web_policies
      ADD CONSTRAINT fk_web_policies_device_id
      FOREIGN KEY (device_id)
      REFERENCES child.ios_devices(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      CREATE INDEX idx_web_policies_device_id
      ON iosapp.web_policies USING btree (device_id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP TABLE iosapp.web_policies;
    """)
  }
}
