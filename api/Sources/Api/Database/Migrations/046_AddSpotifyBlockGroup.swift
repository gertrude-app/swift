import Dependencies
import FluentSQL
import Foundation

struct AddSpotifyBlockGroup: GertieMigration {
  let spotifyImagesId = CreateBlockGroups.GroupIds().spotifyImages

  func up(sql: SQLDatabase) async throws {
    try await sql.execute("""
      INSERT INTO iosapp.block_groups (name, description, id, created_at, updated_at)
      VALUES (
        'Spotify images',
        'Block images from the Spotify app.',
        '\(uuid: self.spotifyImagesId)',
        NOW(),
        NOW()
      );
    """)

    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET group_id = '\(uuid: self.spotifyImagesId)'
      WHERE comment = 'spotify';
    """)
  }

  func down(sql: SQLDatabase) async throws {
    try await sql.execute("""
      UPDATE iosapp.block_rules
      SET group_id = NULL
      WHERE group_id = '\(uuid: self.spotifyImagesId)';
    """)

    try await sql.execute("""
      DELETE FROM iosapp.block_groups
      WHERE id = '\(uuid: self.spotifyImagesId)';
    """)
  }
}
