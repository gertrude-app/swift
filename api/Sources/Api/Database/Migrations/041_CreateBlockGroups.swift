import Dependencies
import FluentSQL
import Foundation

struct CreateBlockGroups: GertieMigration {
  struct GroupIds {
    let ads = UUID(uuidString: "1ea5f1b8-1b14-4894-9913-56cfee98bd48")!
    let aiFeatures = UUID(uuidString: "c15351df-ff54-4b75-8f7e-2b522a3a0dae")!
    let appStoreImages = UUID(uuidString: "283a29ec-13eb-4bd3-9211-eb920bd85158")!
    let appleMapsImages = UUID(uuidString: "baecbdda-49c0-43ec-a931-777810f34c13")!
    let appleWebsite = UUID(uuidString: "9cd776c0-f1a6-43c2-861b-f6c6ec8cf513")!
    let gifs = UUID(uuidString: "087628b2-742c-4164-a3cc-717c4ac72c1a")!
    let spotlightSearches = UUID(uuidString: "df7fb156-488a-497b-aa12-c585d3fa4e6c")!
    let whatsAppFeatures = UUID(uuidString: "8e337c3c-2efb-404a-8eb3-781661231844")!
  }

  let ids = GroupIds()

  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      CREATE TABLE iosapp.block_groups (
        id uuid NOT NULL,
        name text NOT NULL,
        description text NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL
      );
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.block_groups
      ADD CONSTRAINT block_groups_pkey PRIMARY KEY (id);
    """)

    try await sql.execute("""
      CREATE INDEX idx_block_groups_name
      ON iosapp.block_groups USING btree (name);
    """)

    try await self.addGroups(sql)

    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      ADD COLUMN group_id uuid;
    """)

    try await sql.execute("""
      ALTER TABLE ONLY iosapp.block_rules
      ADD CONSTRAINT fk_block_rules_group_id
      FOREIGN KEY (group_id)
      REFERENCES iosapp.block_groups(id) ON DELETE CASCADE;
    """)

    try await sql.execute("""
      CREATE INDEX idx_block_rules_group_id
      ON iosapp.block_rules USING btree (group_id);
    """)

    try await self.setGroupIds(sql)

    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      DROP COLUMN "group";
    """)
  }

  func setGroupIds(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET group_id = '\(uuid: self.ids.ads)'
      WHERE "group" = 'ads';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET group_id = '\(uuid: self.ids.aiFeatures)'
      WHERE "group" = 'aiFeatures';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET group_id = '\(uuid: self.ids.appStoreImages)'
      WHERE "group" = 'appStoreImages';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET group_id = '\(uuid: self.ids.appleMapsImages)'
      WHERE "group" = 'appleMapsImages';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET group_id = '\(uuid: self.ids.appleWebsite)'
      WHERE "group" = 'appleWebsite';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET group_id = '\(uuid: self.ids.gifs)'
      WHERE "group" = 'gifs';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET group_id = '\(uuid: self.ids.spotlightSearches)'
      WHERE "group" = 'spotlightSearches';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET group_id = '\(uuid: self.ids.whatsAppFeatures)'
      WHERE "group" = 'whatsAppFeatures';
    """)
  }

  func addGroups(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      INSERT INTO iosapp.block_groups (name, description, id, created_at, updated_at)
      VALUES
      (
        'Ads', 'Block the most common ad providers across all apps.',
        '\(uuid: self.ids.ads)', NOW(), NOW()
      ),
      (
        'AI features', 'Block certain cloud-based AI features like image recognition.',
        '\(uuid: self.ids.aiFeatures)', NOW(), NOW()
      ),
      (
        'App store images', 'Block images from the App Store.',
        '\(uuid: self.ids.appStoreImages)', NOW(), NOW()
      ),
      (
        'Apple Maps images', 'Block all images from Apple Maps business listings.',
        '\(uuid: self.ids.appleMapsImages)', NOW(), NOW()
      ),
      (
        'apple.com', 'Block web access to apple.com and linked sites.',
        '\(uuid: self.ids.appleWebsite)', NOW(), NOW()
      ),
      (
        'GIFs', 'Block GIFs in Messages #images, WhatsApp, Signal, and more.',
        '\(uuid: self.ids.gifs)', NOW(), NOW()
      ),
      (
        'Spotlight', 'Block internet searches through Spotlight.',
        '\(uuid: self.ids.spotlightSearches)', NOW(), NOW()
      ),
      (
        'WhatsApp', 'Block some parts of WhatsApp, including media content.',
        '\(uuid: self.ids.whatsAppFeatures)', NOW(), NOW()
      );
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      ADD COLUMN "group" text;
    """)

    try await self.restoreGroupValues(sql)

    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      DROP CONSTRAINT fk_block_rules_group_id;
    """)

    try await sql.execute("""
      DROP INDEX iosapp.idx_block_rules_group_id;
    """)

    try await sql.execute("""
      ALTER TABLE iosapp.block_rules
      DROP COLUMN group_id;
    """)

    try await sql.execute("""
      DROP TABLE iosapp.block_groups;
    """)
  }

  func restoreGroupValues(_ sql: SQLDatabase) async throws {
    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET "group" = 'ads'
      WHERE group_id = '\(uuid: self.ids.ads)';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET "group" = 'aiFeatures'
      WHERE group_id = '\(uuid: self.ids.aiFeatures)';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET "group" = 'appStoreImages'
      WHERE group_id = '\(uuid: self.ids.appStoreImages)';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET "group" = 'appleMapsImages'
      WHERE group_id = '\(uuid: self.ids.appleMapsImages)';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET "group" = 'appleWebsite'
      WHERE group_id = '\(uuid: self.ids.appleWebsite)';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET "group" = 'gifs'
      WHERE group_id = '\(uuid: self.ids.gifs)';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET "group" = 'spotlightSearches'
      WHERE group_id = '\(uuid: self.ids.spotlightSearches)';
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET "group" = 'whatsAppFeatures'
      WHERE group_id = '\(uuid: self.ids.whatsAppFeatures)';
    """)
  }
}
