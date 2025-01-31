import DuetSQL
import FluentSQL
import Foundation

struct RecreateTables: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    do {
      try await sql.execute("SELECT id FROM parent.parents LIMIT 1;")
      // we have legacy data converted by prior migrations, so skip
      return
    } catch {
      // continue, this is basically a test/dev resume point allowing us
      // to delete all the historical migrations with all their baggage
      // the code below sets up the schema exactly as if all the prior
      // migrations had been run
    }

    try await sql.execute("CREATE SCHEMA child;")
    try await sql.execute("CREATE SCHEMA iosapp;")
    try await sql.execute("CREATE SCHEMA macapp;")
    try await sql.execute("CREATE SCHEMA macos;")
    try await sql.execute("CREATE SCHEMA parent;")
    try await sql.execute("CREATE SCHEMA system;")

    try await sql.execute("""
      CREATE TYPE public.enum_parent_subscription_status AS ENUM (
        'pendingEmailVerification',
        'trialing',
        'trialExpiringSoon',
        'overdue',
        'paid',
        'unpaid',
        'pendingAccountDeletion',
        'complimentary'
      );
    """)

    try await sql.execute("""
      CREATE TYPE public.enum_parent_notification_trigger AS ENUM (
        'unlockRequestSubmitted',
        'suspendFilterRequestSubmitted',
        'adminChildSecurityEvent'
      );
    """)

    try await sql.execute("""
      CREATE TYPE public.enum_release_channels AS ENUM (
        'stable',
        'beta',
        'canary'
      );
    """)

    try await sql.execute("""
      CREATE TYPE public.enum_shared_request_status AS ENUM (
        'pending',
        'accepted',
        'rejected'
      );
    """)

    try await sql.execute("""
      CREATE TABLE child.blocked_mac_apps (
        id uuid NOT NULL,
        child_id uuid NOT NULL,
        identifier text NOT NULL,
        schedule jsonb,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE child.computer_users (
        id uuid NOT NULL,
        child_id uuid NOT NULL,
        computer_id uuid NOT NULL,
        app_version text DEFAULT '0.0.0'::text NOT NULL,
        username text NOT NULL,
        full_username text NOT NULL,
        numeric_id bigint NOT NULL,
        is_admin boolean,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE child.keychains (
        id uuid NOT NULL,
        child_id uuid NOT NULL,
        keychain_id uuid NOT NULL,
        schedule jsonb,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE child.macapp_tokens (
        id uuid NOT NULL,
        value uuid NOT NULL,
        child_id uuid NOT NULL,
        computer_user_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        deleted_at timestamp with time zone
      );
    """)

    try await sql.execute("""
      CREATE TABLE iosapp.block_rules (
        id uuid NOT NULL,
        vendor_id uuid,
        rule jsonb NOT NULL,
        "group" text,
        comment text,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE macapp.keystroke_lines (
        id uuid NOT NULL,
        computer_user_id uuid NOT NULL,
        app_name text NOT NULL,
        line text NOT NULL,
        filter_suspended boolean DEFAULT false NOT NULL,
        created_at timestamp with time zone NOT NULL,
        deleted_at timestamp with time zone
      );
    """)

    try await sql.execute("""
      CREATE TABLE macapp.releases (
        id uuid NOT NULL,
        semver text NOT NULL,
        channel public.enum_release_channels NOT NULL,
        revision text NOT NULL,
        requirement_pace integer DEFAULT 10,
        notes text,
        signature text NOT NULL,
        length bigint NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE macapp.screenshots (
        id uuid NOT NULL,
        computer_user_id uuid NOT NULL,
        url text NOT NULL,
        width bigint NOT NULL,
        height bigint NOT NULL,
        filter_suspended boolean DEFAULT false NOT NULL,
        created_at timestamp with time zone NOT NULL,
        deleted_at timestamp with time zone
      );
    """)

    try await sql.execute("""
      CREATE TABLE macapp.suspend_filter_requests (
        id uuid NOT NULL,
        computer_user_id uuid NOT NULL,
        status public.enum_shared_request_status NOT NULL,
        scope jsonb NOT NULL,
        duration bigint NOT NULL,
        request_comment text,
        response_comment text,
        extra_monitoring character varying(255),
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE macapp.unlock_requests (
        id uuid NOT NULL,
        computer_user_id uuid NOT NULL,
        status public.enum_shared_request_status NOT NULL,
        request_comment text,
        response_comment text,
        app_bundle_id text NOT NULL,
        url text,
        hostname text,
        ip_address text,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE macos.app_bundle_ids (
        id uuid NOT NULL,
        bundle_id text NOT NULL,
        identified_app_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE macos.app_categories (
        id uuid NOT NULL,
        name text NOT NULL,
        slug text NOT NULL,
        description text,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE macos.browsers (
        id uuid NOT NULL,
        match jsonb NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE macos.identified_apps (
        id uuid NOT NULL,
        category_id uuid,
        name text NOT NULL,
        slug text NOT NULL,
        launchable boolean NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE macos.unidentified_apps (
        id uuid NOT NULL,
        bundle_id text NOT NULL,
        count integer NOT NULL,
        bundle_name text,
        localized_name text,
        launchable boolean,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE parent.children (
        id uuid NOT NULL,
        name text NOT NULL,
        keylogging_enabled boolean NOT NULL,
        screenshots_enabled boolean NOT NULL,
        screenshots_resolution bigint NOT NULL,
        screenshots_frequency bigint NOT NULL,
        parent_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        show_suspension_activity boolean DEFAULT true NOT NULL,
        downtime jsonb
      );
    """)

    try await sql.execute("""
      CREATE TABLE parent.computers (
        id uuid NOT NULL,
        parent_id uuid NOT NULL,
        custom_name text,
        model_identifier text NOT NULL,
        serial_number text NOT NULL,
        app_release_channel public.enum_release_channels NOT NULL,
        filter_version character varying(12),
        os_version character varying(12),
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE parent.dash_tokens (
        id uuid NOT NULL,
        value uuid NOT NULL,
        parent_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL,
        deleted_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE parent.keychains (
        id uuid NOT NULL,
        parent_id uuid NOT NULL,
        name text NOT NULL,
        description text,
        is_public boolean NOT NULL,
        warning text,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE parent.keys (
        id uuid NOT NULL,
        keychain_id uuid NOT NULL,
        key jsonb NOT NULL,
        comment text,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        deleted_at timestamp with time zone
      );
    """)

    try await sql.execute("""
      CREATE TABLE parent.notifications (
        id uuid NOT NULL,
        trigger public.enum_parent_notification_trigger NOT NULL,
        parent_id uuid NOT NULL,
        method_id uuid NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE parent.parents (
        id uuid NOT NULL,
        email text NOT NULL,
        password text NOT NULL,
        subscription_id text,
        subscription_status public.enum_parent_subscription_status NOT NULL,
        subscription_status_expiration timestamp with time zone,
        gclid character varying(128),
        ab_test_variant character varying(255),
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE parent.verified_notification_methods (
        id uuid NOT NULL,
        parent_id uuid NOT NULL,
        config jsonb NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE system.deleted_entities (
        id uuid NOT NULL,
        type text NOT NULL,
        reason text NOT NULL,
        data text NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE system.interesting_events (
        id uuid NOT NULL,
        event_id text NOT NULL,
        kind text NOT NULL,
        context text NOT NULL,
        computer_user_id uuid,
        parent_id uuid,
        detail text,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE system.security_events (
        id uuid NOT NULL,
        parent_id uuid NOT NULL,
        computer_user_id uuid,
        event character varying(255) NOT NULL,
        detail text,
        ip_address character varying(64),
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      CREATE TABLE system.stripe_events (
        id uuid NOT NULL,
        "json" text NOT NULL,
        created_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.blocked_mac_apps
      ADD CONSTRAINT blocked_mac_apps_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.computer_users
      ADD CONSTRAINT computer_users_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.keychains
      ADD CONSTRAINT keychains_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.macapp_tokens
      ADD CONSTRAINT macapp_tokens_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.keychains
      ADD CONSTRAINT uq_keychain_id_child_id UNIQUE (keychain_id, child_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.macapp_tokens
      ADD CONSTRAINT uq_macapp_tokens_value UNIQUE (value);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.block_rules
      ADD CONSTRAINT block_rules_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macapp.keystroke_lines
      ADD CONSTRAINT keystroke_lines_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macapp.releases
      ADD CONSTRAINT releases_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macapp.screenshots
      ADD CONSTRAINT screenshots_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macapp.suspend_filter_requests
      ADD CONSTRAINT suspend_filter_requests_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macapp.unlock_requests
      ADD CONSTRAINT unlock_requests_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macapp.releases
      ADD CONSTRAINT uq_releases_semver UNIQUE (semver);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.app_bundle_ids
      ADD CONSTRAINT app_bundle_ids_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.app_categories
      ADD CONSTRAINT app_categories_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.browsers
      ADD CONSTRAINT browsers_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.identified_apps
      ADD CONSTRAINT identified_apps_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.unidentified_apps
      ADD CONSTRAINT unidentified_apps_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.app_bundle_ids
      ADD CONSTRAINT uq_app_bundle_ids_bundle_id UNIQUE (bundle_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.app_categories
      ADD CONSTRAINT uq_app_categories_name UNIQUE (name);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.app_categories
      ADD CONSTRAINT uq_app_categories_slug UNIQUE (slug);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.browsers
      ADD CONSTRAINT uq_browsers_match UNIQUE (match);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.identified_apps
      ADD CONSTRAINT uq_identified_apps_name UNIQUE (name);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.identified_apps
      ADD CONSTRAINT uq_identified_apps_slug UNIQUE (slug);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.unidentified_apps
      ADD CONSTRAINT uq_unidentified_apps_bundle_id UNIQUE (bundle_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.children
      ADD CONSTRAINT children_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.computers
      ADD CONSTRAINT computers_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.keychains
      ADD CONSTRAINT keychains_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.keys
      ADD CONSTRAINT keys_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.parents
      ADD CONSTRAINT parents_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.computers
      ADD CONSTRAINT uq_computers_serial_number UNIQUE (serial_number);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.dash_tokens
      ADD CONSTRAINT uq_dash_tokens PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.verified_notification_methods
      ADD CONSTRAINT uq_notification_method UNIQUE (config, parent_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.notifications
      ADD CONSTRAINT uq_notifications PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.notifications
      ADD CONSTRAINT uq_parent_notification UNIQUE (parent_id, method_id, trigger);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.parents
      ADD CONSTRAINT uq_parents_email UNIQUE (email);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.verified_notification_methods
      ADD CONSTRAINT verified_notification_methods_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY system.deleted_entities
      ADD CONSTRAINT deleted_entities_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY system.interesting_events
      ADD CONSTRAINT interesting_events_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY system.security_events
      ADD CONSTRAINT security_events_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY system.stripe_events
      ADD CONSTRAINT stripe_events_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      CREATE INDEX idx_block_rules_vendor_id
      ON iosapp.block_rules USING btree (vendor_id);
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.blocked_mac_apps
      ADD CONSTRAINT fk_blocked_mac_apps_child_id
      FOREIGN KEY (child_id)
      REFERENCES parent.children(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.computer_users
      ADD CONSTRAINT fk_computer_users_child_id
      FOREIGN KEY (child_id)
      REFERENCES parent.children(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.computer_users
      ADD CONSTRAINT fk_computer_users_computer_id
      FOREIGN KEY (computer_id)
      REFERENCES parent.computers(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.keychains
      ADD CONSTRAINT fk_keychains_child_id
      FOREIGN KEY (child_id)
      REFERENCES parent.children(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.keychains
      ADD CONSTRAINT fk_keychains_keychain_id
      FOREIGN KEY (keychain_id)
      REFERENCES parent.keychains(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.macapp_tokens
      ADD CONSTRAINT fk_macapp_tokens_child_id
      FOREIGN KEY (child_id)
      REFERENCES parent.children(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY child.macapp_tokens
      ADD CONSTRAINT fk_macapp_tokens_computer_user_id
      FOREIGN KEY (computer_user_id)
      REFERENCES child.computer_users(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macapp.keystroke_lines
      ADD CONSTRAINT fk_keystroke_lines_computer_user_id
      FOREIGN KEY (computer_user_id)
      REFERENCES child.computer_users(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macapp.screenshots
      ADD CONSTRAINT fk_screenshots_computer_user_id
      FOREIGN KEY (computer_user_id)
      REFERENCES child.computer_users(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macapp.suspend_filter_requests
      ADD CONSTRAINT fk_suspend_filter_requests_computer_user_id
      FOREIGN KEY (computer_user_id)
      REFERENCES child.computer_users(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macapp.unlock_requests
      ADD CONSTRAINT fk_unlock_requests_computer_user_id
      FOREIGN KEY (computer_user_id)
      REFERENCES child.computer_users(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.app_bundle_ids
      ADD CONSTRAINT fk_app_bundle_ids_identified_app_id
      FOREIGN KEY (identified_app_id)
      REFERENCES macos.identified_apps(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY macos.identified_apps
      ADD CONSTRAINT fk_identified_apps_category_id
      FOREIGN KEY (category_id)
      REFERENCES macos.app_categories(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.children
      ADD CONSTRAINT fk_children_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES parent.parents(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.computers
      ADD CONSTRAINT fk_computers_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES parent.parents(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.dash_tokens
      ADD CONSTRAINT fk_dash_tokens_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES parent.parents(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.keychains
      ADD CONSTRAINT fk_keychains_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES parent.parents(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.keys
      ADD CONSTRAINT fk_keys_keychain_id
      FOREIGN KEY (keychain_id)
      REFERENCES parent.keychains(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.notifications
      ADD CONSTRAINT fk_notifications_method_id
      FOREIGN KEY (method_id)
      REFERENCES parent.verified_notification_methods(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.notifications
      ADD CONSTRAINT fk_notifications_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES parent.parents(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY parent.verified_notification_methods
      ADD CONSTRAINT fk_verified_notification_methods_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES parent.parents(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY system.interesting_events
      ADD CONSTRAINT fk_interesting_events_computer_user_id
      FOREIGN KEY (computer_user_id)
      REFERENCES child.computer_users(id) ON DELETE SET NULL;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY system.interesting_events
      ADD CONSTRAINT fk_interesting_events_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES parent.parents(id) ON DELETE SET NULL;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY system.security_events
      ADD CONSTRAINT fk_security_events_computer_user_id
      FOREIGN KEY (computer_user_id)
      REFERENCES child.computer_users(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY system.security_events
      ADD CONSTRAINT fk_security_events_parent_id
      FOREIGN KEY (parent_id)
      REFERENCES parent.parents(id) ON DELETE CASCADE;
    """)
  }

  func down(sql: SQLDatabase) async throws {
    guard get(dependency: \.env.mode) != .prod else {
      return
    }
    // drop all foreign keys
    try await sql.execute("""
      DO $$
      DECLARE
        row RECORD;
      BEGIN
        FOR row IN
          SELECT table_schema, table_name, constraint_name
          FROM information_schema.table_constraints
          WHERE constraint_type = 'FOREIGN KEY'
        LOOP
          EXECUTE 'ALTER TABLE ' || row.table_schema || '.' || row.table_name ||
                  ' DROP CONSTRAINT ' || quote_ident(row.constraint_name) || ';';
        END LOOP;
      END;
      $$;
    """)
    try await sql.execute("DROP TABLE child.blocked_mac_apps;")
    try await sql.execute("DROP TABLE child.macapp_tokens;")
    try await sql.execute("DROP TABLE child.keychains;")
    try await sql.execute("DROP TABLE child.computer_users;")
    try await sql.execute("DROP TABLE iosapp.block_rules;")
    try await sql.execute("DROP TABLE macapp.keystroke_lines;")
    try await sql.execute("DROP TABLE macapp.releases;")
    try await sql.execute("DROP TABLE macapp.screenshots;")
    try await sql.execute("DROP TABLE macapp.suspend_filter_requests;")
    try await sql.execute("DROP TABLE macapp.unlock_requests;")
    try await sql.execute("DROP TABLE macos.app_bundle_ids;")
    try await sql.execute("DROP TABLE macos.app_categories;")
    try await sql.execute("DROP TABLE macos.browsers;")
    try await sql.execute("DROP TABLE macos.identified_apps;")
    try await sql.execute("DROP TABLE macos.unidentified_apps;")
    try await sql.execute("DROP TABLE parent.children;")
    try await sql.execute("DROP TABLE parent.computers;")
    try await sql.execute("DROP TABLE parent.dash_tokens;")
    try await sql.execute("DROP TABLE parent.keychains;")
    try await sql.execute("DROP TABLE parent.keys;")
    try await sql.execute("DROP TABLE parent.notifications;")
    try await sql.execute("DROP TABLE parent.verified_notification_methods;")
    try await sql.execute("DROP TABLE parent.parents;")
    try await sql.execute("DROP TABLE system.deleted_entities;")
    try await sql.execute("DROP TABLE system.interesting_events;")
    try await sql.execute("DROP TABLE system.security_events;")
    try await sql.execute("DROP TABLE system.stripe_events;")
    try await sql.execute("DROP TYPE public.enum_parent_subscription_status;")
    try await sql.execute("DROP TYPE public.enum_parent_notification_trigger;")
    try await sql.execute("DROP TYPE public.enum_release_channels;")
    try await sql.execute("DROP TYPE public.enum_shared_request_status;")
    try await sql.execute("DROP SCHEMA child;")
    try await sql.execute("DROP SCHEMA iosapp;")
    try await sql.execute("DROP SCHEMA macapp;")
    try await sql.execute("DROP SCHEMA macos;")
    try await sql.execute("DROP SCHEMA parent;")
    try await sql.execute("DROP SCHEMA system;")
  }
}
