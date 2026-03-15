-- Migration: add soft-delete support to files table
-- Apply with: wrangler d1 execute r2shelf --file=migrations/0002_soft_delete.sql

ALTER TABLE files ADD COLUMN deleted_at TEXT;

CREATE INDEX IF NOT EXISTS idx_files_deleted_at ON files(user_id, deleted_at);
