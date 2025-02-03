import DuetSQL
import FluentSQL
import Foundation

struct MultipleSchemas: GertieMigration {
  func up(sql: SQLDatabase) async throws {
    do {
      try await sql.execute("SELECT id FROM admins LIMIT 1;")
    } catch {
      // we don't have legacy data, so we can skip this migration
      return
    }
    do {
      try await sql.execute("BEGIN;")

      // create schemas
      try await sql.execute("CREATE SCHEMA IF NOT EXISTS parent;")
      try await sql.execute("CREATE SCHEMA IF NOT EXISTS child;")
      try await sql.execute("CREATE SCHEMA IF NOT EXISTS macapp;")
      try await sql.execute("CREATE SCHEMA IF NOT EXISTS iosapp;")
      try await sql.execute("CREATE SCHEMA IF NOT EXISTS macos;")
      try await sql.execute("CREATE SCHEMA IF NOT EXISTS system;")

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

      // rename tables, moving into correct schemas
      try await sql.execute("ALTER TABLE admins RENAME TO parents;")
      try await sql.execute("ALTER TABLE parents SET SCHEMA parent;")
      try await sql.execute("ALTER TABLE users RENAME TO children;")
      try await sql.execute("ALTER TABLE children SET SCHEMA parent;")
      try await sql.execute("ALTER TABLE admin_notifications RENAME TO notifications;")
      try await sql.execute("ALTER TABLE notifications SET SCHEMA parent;")
      try await sql.execute(
        "ALTER TABLE admin_verified_notification_methods RENAME TO verified_notification_methods;"
      )
      try await sql.execute("ALTER TABLE verified_notification_methods SET SCHEMA parent;")
      try await sql.execute("ALTER TABLE admin_tokens RENAME TO dash_tokens;")
      try await sql.execute("ALTER TABLE dash_tokens SET SCHEMA parent;")
      try await sql.execute("ALTER TABLE devices RENAME TO computers;")
      try await sql.execute("ALTER TABLE computers SET SCHEMA parent;")
      try await sql.execute("ALTER TABLE keychains SET SCHEMA parent;")
      try await sql.execute("ALTER TABLE keys SET SCHEMA parent;")
      try await sql.execute("ALTER TABLE blocked_apps RENAME TO blocked_mac_apps;")
      try await sql.execute("ALTER TABLE blocked_mac_apps SET SCHEMA child;")
      try await sql.execute("ALTER TABLE user_keychain RENAME TO keychains;")
      try await sql.execute("ALTER TABLE keychains SET SCHEMA child;")
      try await sql.execute("ALTER TABLE user_tokens RENAME TO macapp_tokens;")
      try await sql.execute("ALTER TABLE macapp_tokens SET SCHEMA child;")
      try await sql.execute("ALTER TABLE user_devices RENAME TO computer_users;")
      try await sql.execute("ALTER TABLE computer_users SET SCHEMA child;")
      try await sql.execute("ALTER TABLE interesting_events SET SCHEMA system;")
      try await sql.execute("ALTER TABLE keystroke_lines SET SCHEMA macapp;")
      try await sql.execute("ALTER TABLE screenshots SET SCHEMA macapp;")
      try await sql.execute("ALTER TABLE releases SET SCHEMA macapp;")
      try await sql.execute("ALTER TABLE suspend_filter_requests SET SCHEMA macapp;")
      try await sql.execute("ALTER TABLE unlock_requests SET SCHEMA macapp;")
      try await sql.execute("ALTER TABLE ios_block_rules RENAME TO block_rules;")
      try await sql.execute("ALTER TABLE block_rules SET SCHEMA iosapp;")
      try await sql.execute("ALTER TABLE browsers SET SCHEMA macos;")
      try await sql.execute("ALTER TABLE app_categories SET SCHEMA macos;")
      try await sql.execute("ALTER TABLE identified_apps SET SCHEMA macos;")
      try await sql.execute("ALTER TABLE app_bundle_ids SET SCHEMA macos;")
      try await sql.execute("ALTER TABLE unidentified_apps SET SCHEMA macos;")
      try await sql.execute("ALTER TABLE deleted_entities SET SCHEMA system;")
      try await sql.execute("ALTER TABLE stripe_events SET SCHEMA system;")
      try await sql.execute("ALTER TABLE security_events SET SCHEMA system;")

      // rename columns, restore FK constrains, rename indexes
      try await sql.execute("""
        ALTER TABLE parent.notifications RENAME COLUMN admin_id TO parent_id;
      """)
      try await sql.execute("""
        ALTER TABLE parent.notifications
        ADD CONSTRAINT fk_notifications_parent_id
        FOREIGN KEY (parent_id)
        REFERENCES parent.parents(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE parent.notifications
        ADD CONSTRAINT fk_notifications_method_id
        FOREIGN KEY (method_id)
        REFERENCES parent.verified_notification_methods(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE parent.notifications
        RENAME CONSTRAINT admin_notifications_pkey TO uq_notifications;
      """)
      try await sql.execute("""
        ALTER TABLE parent.notifications
        RENAME CONSTRAINT "uq:admin_notifications.admin_id+method_id+trigger" TO uq_parent_notification;
      """)
      try await sql.execute("""
        ALTER TYPE enum_admin_notification_trigger RENAME TO enum_parent_notification_trigger;
      """)
      try await sql.execute("""
        ALTER TABLE parent.dash_tokens RENAME COLUMN admin_id TO parent_id;
      """)
      try await sql.execute("""
        ALTER TABLE parent.dash_tokens
        ADD CONSTRAINT fk_dash_tokens_parent_id
        FOREIGN KEY (parent_id)
        REFERENCES parent.parents(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE parent.dash_tokens
        RENAME CONSTRAINT admin_tokens_pkey TO uq_dash_tokens;
      """)
      try await sql.execute("""
      ALTER TABLE parent.verified_notification_methods RENAME COLUMN admin_id TO parent_id;
      """)
      try await sql.execute("""
        ALTER TABLE parent.verified_notification_methods
        ADD CONSTRAINT fk_verified_notification_methods_parent_id
        FOREIGN KEY (parent_id)
        REFERENCES parent.parents(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE parent.verified_notification_methods
        RENAME CONSTRAINT admin_verified_notification_methods_pkey TO verified_notification_methods_pkey;
      """)
      try await sql.execute("""
        ALTER TABLE parent.verified_notification_methods
        RENAME CONSTRAINT "uq:admin_verified_notification_methods.admin_id+config" TO uq_notification_method;
      """)
      try await sql.execute("""
        ALTER TABLE parent.parents
        RENAME CONSTRAINT admins_pkey TO parents_pkey;
      """)
      try await sql.execute("""
        ALTER TABLE parent.parents
        RENAME CONSTRAINT admins_email_key TO uq_parents_email;
      """)
      try await sql.execute("""
        ALTER TABLE macos.app_bundle_ids
        ADD CONSTRAINT fk_app_bundle_ids_identified_app_id
        FOREIGN KEY (identified_app_id)
        REFERENCES macos.identified_apps(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE macos.app_bundle_ids
        RENAME CONSTRAINT app_bundle_ids_bundle_id_key TO uq_app_bundle_ids_bundle_id;
      """)
      try await sql.execute("""
        ALTER TABLE macos.app_categories
        RENAME CONSTRAINT app_categories_name_key TO uq_app_categories_name;
      """)
      try await sql.execute("""
        ALTER TABLE macos.app_categories
        RENAME CONSTRAINT app_categories_slug_key TO uq_app_categories_slug;
      """)
      try await sql.execute("""
        ALTER TABLE child.blocked_mac_apps RENAME COLUMN user_id TO child_id;
      """)
      try await sql.execute("""
        ALTER TABLE child.blocked_mac_apps
        ADD CONSTRAINT fk_blocked_mac_apps_child_id
        FOREIGN KEY (child_id)
        REFERENCES parent.children(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE child.blocked_mac_apps
        RENAME CONSTRAINT blocked_apps_pkey TO blocked_mac_apps_pkey;
      """)
      try await sql.execute("""
        ALTER TABLE macos.browsers
        RENAME CONSTRAINT browsers_match_key TO uq_browsers_match;
      """)
      try await sql.execute("""
        ALTER TABLE parent.computers RENAME COLUMN admin_id TO parent_id;
      """)
      try await sql.execute("""
        ALTER TABLE parent.computers
        ADD CONSTRAINT fk_computers_parent_id
        FOREIGN KEY (parent_id)
        REFERENCES parent.parents(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER INDEX parent.devices_pkey1 RENAME TO computers_pkey;
      """)
      try await sql.execute("""
        ALTER TABLE parent.computers
        RENAME CONSTRAINT "uq:devices.serial_number" TO uq_computers_serial_number;
      """)
      try await sql.execute("""
        ALTER TABLE macos.identified_apps
        ADD CONSTRAINT fk_identified_apps_category_id
        FOREIGN KEY (category_id)
        REFERENCES macos.app_categories(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE macos.identified_apps
        RENAME CONSTRAINT identified_apps_name_key TO uq_identified_apps_name;
      """)
      try await sql.execute("""
        ALTER TABLE macos.identified_apps
        RENAME CONSTRAINT identified_apps_slug_key TO uq_identified_apps_slug;
      """)
      try await sql.execute("""
        ALTER TABLE system.interesting_events
        RENAME COLUMN admin_id TO parent_id;
      """)
      try await sql.execute("""
        ALTER TABLE system.interesting_events
        RENAME COLUMN user_device_id TO computer_user_id;
      """)
      try await sql.execute("""
        ALTER TABLE system.interesting_events
        ADD CONSTRAINT fk_interesting_events_parent_id
        FOREIGN KEY (parent_id)
        REFERENCES parent.parents(id) ON DELETE SET NULL;
      """)
      try await sql.execute("""
        ALTER TABLE system.interesting_events
        ADD CONSTRAINT fk_interesting_events_child_computer_id
        FOREIGN KEY (computer_user_id)
        REFERENCES child.computer_users(id) ON DELETE SET NULL;
      """)
      try await sql.execute("""
        ALTER TABLE iosapp.block_rules
        RENAME CONSTRAINT ios_block_rules_pkey TO block_rules_pkey;
      """)
      try await sql.execute("""
        ALTER INDEX iosapp.idx_ios_block_rules_vendor_id
        RENAME TO idx_block_rules_vendor_id;
      """)
      try await sql.execute("""
        ALTER TABLE parent.keychains RENAME COLUMN author_id TO parent_id;
      """)
      try await sql.execute("""
        ALTER TABLE parent.keychains
        ADD CONSTRAINT fk_keychains_parent_id
        FOREIGN KEY (parent_id)
        REFERENCES parent.parents(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE parent.keys
        ADD CONSTRAINT fk_keys_keychain_id
        FOREIGN KEY (keychain_id)
        REFERENCES parent.keychains(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE macapp.keystroke_lines
        RENAME COLUMN user_device_id TO computer_user_id;
      """)
      try await sql.execute("""
        ALTER TABLE macapp.keystroke_lines
        ADD CONSTRAINT fk_keystroke_lines_computer_user_id
        FOREIGN KEY (computer_user_id)
        REFERENCES child.computer_users(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE macapp.releases
        RENAME CONSTRAINT releases_semver_key TO uq_releases_semver;
      """)
      try await sql.execute("""
        ALTER TABLE macapp.screenshots
        RENAME COLUMN user_device_id TO computer_user_id;
      """)
      try await sql.execute("""
        ALTER TABLE macapp.screenshots
        ADD CONSTRAINT fk_screenshots_computer_user_id
        FOREIGN KEY (computer_user_id)
        REFERENCES child.computer_users(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE system.security_events RENAME COLUMN admin_id TO parent_id;
      """)
      try await sql.execute("""
        ALTER TABLE system.security_events RENAME COLUMN user_device_id TO computer_user_id;
      """)
      try await sql.execute("""
        ALTER TABLE system.security_events
        ADD CONSTRAINT fk_security_events_parent_id
        FOREIGN KEY (parent_id)
        REFERENCES parent.parents(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE system.security_events
        ADD CONSTRAINT fk_security_events_computer_user_id
        FOREIGN KEY (computer_user_id)
        REFERENCES child.computer_users(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE macapp.suspend_filter_requests
        RENAME COLUMN user_device_id TO computer_user_id;
      """)
      try await sql.execute("""
        ALTER TABLE macapp.suspend_filter_requests
        ADD CONSTRAINT fk_suspend_filter_requests_computer_user_id
        FOREIGN KEY (computer_user_id)
        REFERENCES child.computer_users(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE macos.unidentified_apps
        RENAME CONSTRAINT unidentified_apps_bundle_id_key TO uq_unidentified_apps_bundle_id;
      """)
      try await sql.execute("""
        ALTER TABLE macapp.unlock_requests
        RENAME COLUMN user_device_id TO computer_user_id;
      """)
      try await sql.execute("""
        ALTER TABLE macapp.unlock_requests
        ADD CONSTRAINT fk_unlock_requests_computer_user_id
        FOREIGN KEY (computer_user_id)
        REFERENCES child.computer_users(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE child.computer_users RENAME COLUMN user_id TO child_id;
      """)
      try await sql.execute("""
        ALTER TABLE child.computer_users RENAME COLUMN device_id TO computer_id;
      """)
      try await sql.execute("""
        ALTER TABLE child.computer_users
        ADD CONSTRAINT fk_computer_users_child_id
        FOREIGN KEY (child_id)
        REFERENCES parent.children(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE child.computer_users
        ADD CONSTRAINT fk_computer_users_computer_id
        FOREIGN KEY (computer_id)
        REFERENCES parent.computers(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE child.computer_users
        RENAME CONSTRAINT devices_pkey TO computer_users_pkey;
      """)
      try await sql.execute("""
        ALTER TABLE child.keychains RENAME COLUMN user_id TO child_id;
      """)
      try await sql.execute("""
        ALTER TABLE child.keychains
        ADD CONSTRAINT fk_keychains_child_id
        FOREIGN KEY (child_id)
        REFERENCES parent.children(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE child.keychains
        ADD CONSTRAINT fk_keychains_keychain_id
        FOREIGN KEY (keychain_id)
        REFERENCES parent.keychains(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE child.keychains
        RENAME CONSTRAINT user_keychain_pkey TO keychains_pkey;
      """)
      try await sql.execute("""
        ALTER TABLE child.keychains
        RENAME CONSTRAINT "uq:user_keychain.keychain_id+user_id" TO uq_keychain_id_child_id;
      """)
      try await sql.execute("""
        ALTER TABLE child.macapp_tokens RENAME COLUMN user_id TO child_id;
      """)
      try await sql.execute("""
        ALTER TABLE child.macapp_tokens RENAME COLUMN user_device_id TO computer_user_id;
      """)
      try await sql.execute("""
        ALTER TABLE child.macapp_tokens
        ADD CONSTRAINT fk_macapp_tokens_child_id
        FOREIGN KEY (child_id)
        REFERENCES parent.children(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE child.macapp_tokens
        ADD CONSTRAINT fk_macapp_tokens_computer_user_id
        FOREIGN KEY (computer_user_id)
        REFERENCES child.computer_users(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE child.macapp_tokens
        RENAME CONSTRAINT user_tokens_pkey TO macapp_tokens_pkey;
      """)
      try await sql.execute("""
        ALTER TABLE child.macapp_tokens
        RENAME CONSTRAINT user_tokens_value_key TO uq_macapp_tokens_value;
      """)
      try await sql.execute("""
        ALTER TABLE parent.children RENAME COLUMN admin_id TO parent_id;
      """)
      try await sql.execute("""
        ALTER TABLE parent.children
        ADD CONSTRAINT fk_children_parent_id
        FOREIGN KEY (parent_id)
        REFERENCES parent.parents(id) ON DELETE CASCADE;
      """)
      try await sql.execute("""
        ALTER TABLE parent.children
        RENAME CONSTRAINT users_pkey TO children_pkey;
      """)

      try await sql.execute("COMMIT;")
    } catch {
      try await sql.execute("ROLLBACK;")
      throw error
    }
  }

  func down(sql: SQLDatabase) async throws {
    // ¯\_(ツ)_/¯
  }
}

extension Admin {
  enum M33: TableNamingMigration {
    static let tableName = "parents"
    static let schemaName = "parent"
  }
}

extension AdminNotification {
  enum M33 {
    static let triggerTypeName = "enum_parent_notification_trigger"

    enum Trigger: String, Codable, CaseIterable, PostgresEnum {
      var typeName: String { AdminNotification.M33.triggerTypeName }
      case unlockRequestSubmitted
      case suspendFilterRequestSubmitted
    }
  }
}

extension AppBundleId {
  enum M33: TableNamingMigration {
    static let tableName = "app_bundle_ids"
    static let schemaName = "macos"
  }
}
