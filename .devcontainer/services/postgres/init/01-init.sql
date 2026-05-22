-- Runs automatically when the postgres container starts fresh
-- Add any schemas, extensions, or seed data here

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- fuzzy text search

-- Example: CREATE TABLE users ( id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), ... );
