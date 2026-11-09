import { Pool } from "pg";

declare global {
  // eslint-disable-next-line no-var
  var zekaMediaPool: Pool | undefined;
}

function getPool(): Pool {
  if (global.zekaMediaPool) {
    return global.zekaMediaPool;
  }

  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error("DATABASE_URL is not configured");
  }

  const pool = new Pool({
    connectionString,
    max: 5,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 10_000,
    ssl: process.env.DATABASE_SSL === "true"
      ? { rejectUnauthorized: process.env.DATABASE_SSL_REJECT_UNAUTHORIZED !== "false" }
      : undefined,
  });

  // Reuse one pool in every environment. Creating a new pool per query
  // leaks PostgreSQL connections in production.
  global.zekaMediaPool = pool;

  return pool;
}

// Create the connection lazily so Next.js can build without production secrets.
// DATABASE_URL is still required when an API route actually accesses the database.
export const db = new Proxy({} as Pool, {
  get(_target, property) {
    const pool = getPool();
    const value = Reflect.get(pool, property, pool);
    return typeof value === "function" ? value.bind(pool) : value;
  },
});
