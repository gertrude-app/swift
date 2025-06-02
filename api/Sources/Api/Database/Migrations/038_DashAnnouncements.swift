import Dependencies
import FluentSQL
import Foundation

struct DashAnnouncements: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE parent.dash_announcements (
        id UUID NOT NULL,
        parent_id UUID NOT NULL,
        icon VARCHAR(64),
        html TEXT NOT NULL,
        learn_more_url VARCHAR(255),
        created_at TIMESTAMP WITH TIME ZONE NOT NULL,
        deleted_at TIMESTAMP WITH TIME ZONE
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.dash_announcements
      ADD CONSTRAINT dash_announcements_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.dash_announcements
      ADD CONSTRAINT fk_dash_announcements_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES parent.parents(id) ON DELETE CASCADE;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      DROP TABLE parent.dash_announcements;
    """)
  }
}
