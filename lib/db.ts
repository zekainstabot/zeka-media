import { Pool } from "pg";

declare global {
  // eslint-disable-next-line no-var
  var zekaMediaPool: Pool | undefined;
}

function createPool() {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error("DATABASE_URL is not configured");
  }

  return new Pool({
    connectionString,
    max: 5,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 10_000,
    ssl: process.env.DATABASE_SSL === "true"
      ? { rejectUnauthorized: process.env.DATABASE_SSL_REJECT_UNAUTHORIZED !== "false" }
      : undefined,
  });
}

export const db = global.zekaMediaPool ?? createPool();

if (process.env.NODE_ENV !== "production") {
  global.zekaMediaPool = db;
}
