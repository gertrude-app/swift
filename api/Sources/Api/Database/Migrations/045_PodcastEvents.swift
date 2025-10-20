import FluentSQL

struct PodcastEvents: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    try await sql.execute("CREATE SCHEMA podcasts;")

    try await sql.execute("""
      CREATE TABLE podcasts.events (
        id uuid NOT NULL,
        event_id text NOT NULL,
        kind text NOT NULL CHECK (kind IN ('error', 'unexpected', 'info', 'subscription')),
        label text NOT NULL,
        detail text,
        install_id uuid,
        device_type varchar(32) NOT NULL,
        app_version varchar(32) NOT NULL,
        ios_version varchar(32) NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY podcasts.events
      ADD CONSTRAINT podcasts_events_pkey PRIMARY KEY (id);
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("DROP TABLE podcasts.events;")
    try await sql.execute("DROP SCHEMA podcasts;")
  }
}
