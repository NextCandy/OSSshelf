CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'user',
  storage_quota INTEGER NOT NULL DEFAULT 10737418240,
  storage_used INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS storage_buckets (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  provider TEXT NOT NULL,
  bucket_name TEXT NOT NULL,
  endpoint TEXT,
  region TEXT,
  access_key_id TEXT NOT NULL,
  secret_access_key TEXT NOT NULL,
  path_style INTEGER NOT NULL DEFAULT 0,
  is_default INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  storage_used INTEGER NOT NULL DEFAULT 0,
  file_count INTEGER NOT NULL DEFAULT 0,
  storage_quota INTEGER,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_storage_buckets_user_default
  ON storage_buckets(user_id)
  WHERE is_default = 1;
CREATE INDEX IF NOT EXISTS idx_buckets_user_active
  ON storage_buckets(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_buckets_provider
  ON storage_buckets(provider);

CREATE TABLE IF NOT EXISTS files (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_id TEXT,
  name TEXT NOT NULL,
  path TEXT NOT NULL,
  type TEXT,
  size INTEGER NOT NULL DEFAULT 0,
  r2_key TEXT NOT NULL,
  mime_type TEXT,
  hash TEXT,
  is_folder INTEGER NOT NULL DEFAULT 0,
  allowed_mime_types TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT,
  bucket_id TEXT REFERENCES storage_buckets(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_files_user_parent_active
  ON files(user_id, parent_id);
CREATE INDEX IF NOT EXISTS idx_files_user_deleted
  ON files(user_id, deleted_at);
CREATE INDEX IF NOT EXISTS idx_files_user_type
  ON files(user_id, type);
CREATE INDEX IF NOT EXISTS idx_files_user_mime
  ON files(user_id, mime_type);
CREATE INDEX IF NOT EXISTS idx_files_user_created
  ON files(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_files_user_updated
  ON files(user_id, updated_at);
CREATE INDEX IF NOT EXISTS idx_files_user_size
  ON files(user_id, size);
CREATE INDEX IF NOT EXISTS idx_files_hash
  ON files(hash);
CREATE INDEX IF NOT EXISTS idx_files_allowed_mime
  ON files(user_id, allowed_mime_types);

CREATE TABLE IF NOT EXISTS shares (
  id TEXT PRIMARY KEY,
  file_id TEXT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  password TEXT,
  expires_at TEXT,
  download_limit INTEGER,
  download_count INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_shares_expires
  ON shares(expires_at);
CREATE INDEX IF NOT EXISTS idx_shares_user_created
  ON shares(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_shares_file_active
  ON shares(file_id, expires_at);

CREATE TABLE IF NOT EXISTS webdav_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expires_at TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_webdav_expires
  ON webdav_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_webdav_user
  ON webdav_sessions(user_id, expires_at);

CREATE TABLE IF NOT EXISTS file_tags (
  id TEXT PRIMARY KEY,
  file_id TEXT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT DEFAULT '#6366f1',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_file_tags_file
  ON file_tags(file_id);
CREATE INDEX IF NOT EXISTS idx_file_tags_user_name
  ON file_tags(user_id, name);
CREATE UNIQUE INDEX IF NOT EXISTS idx_file_tags_unique
  ON file_tags(file_id, name);

CREATE TABLE IF NOT EXISTS file_permissions (
  id TEXT PRIMARY KEY,
  file_id TEXT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission TEXT NOT NULL DEFAULT 'read',
  granted_by TEXT NOT NULL REFERENCES users(id),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_file_permissions_file
  ON file_permissions(file_id);
CREATE INDEX IF NOT EXISTS idx_file_permissions_user
  ON file_permissions(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_file_permissions_unique
  ON file_permissions(file_id, user_id);

CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  details TEXT,
  ip_address TEXT,
  user_agent TEXT,
  status TEXT DEFAULT 'success',
  error_message TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user
  ON audit_logs(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action
  ON audit_logs(action, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource
  ON audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created
  ON audit_logs(created_at);

CREATE TABLE IF NOT EXISTS login_attempts (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  ip_address TEXT NOT NULL,
  success INTEGER NOT NULL DEFAULT 0,
  user_agent TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_login_attempts_email
  ON login_attempts(email, created_at);
CREATE INDEX IF NOT EXISTS idx_login_attempts_ip
  ON login_attempts(ip_address, created_at);

CREATE TABLE IF NOT EXISTS user_devices (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  device_name TEXT,
  device_type TEXT,
  ip_address TEXT,
  user_agent TEXT,
  last_active TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_devices_user
  ON user_devices(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_devices_unique
  ON user_devices(user_id, device_id);

CREATE TABLE IF NOT EXISTS upload_tasks (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  mime_type TEXT,
  parent_id TEXT,
  bucket_id TEXT,
  r2_key TEXT NOT NULL,
  upload_id TEXT NOT NULL,
  total_parts INTEGER NOT NULL,
  uploaded_parts TEXT DEFAULT '[]',
  status TEXT DEFAULT 'pending',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_upload_tasks_user
  ON upload_tasks(user_id, status);
CREATE INDEX IF NOT EXISTS idx_upload_tasks_expires
  ON upload_tasks(expires_at);

CREATE TABLE IF NOT EXISTS download_tasks (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  file_name TEXT,
  file_size INTEGER,
  parent_id TEXT,
  bucket_id TEXT,
  status TEXT DEFAULT 'pending',
  progress INTEGER DEFAULT 0,
  error_message TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_download_tasks_user
  ON download_tasks(user_id, status);
CREATE INDEX IF NOT EXISTS idx_download_tasks_status
  ON download_tasks(status, created_at);
