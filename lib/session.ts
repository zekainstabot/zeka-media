import { createHash, randomBytes } from "crypto";
import { cookies } from "next/headers";
import { db } from "./db";

const COOKIE_NAME = "zeka_session";
const SESSION_DAYS = 30;

export function hashSessionToken(token: string) {
  return createHash("sha256").update(token).digest("hex");
}

export async function createUserSession(
  userId: string,
  request: Request
) {
  const token = randomBytes(32).toString("hex");
  const sessionHash = hashSessionToken(token);
  const expiresAt = new Date(Date.now() + SESSION_DAYS * 24 * 60 * 60 * 1000);
  const userAgent = request.headers.get("user-agent")?.slice(0, 1000) || null;
  const forwardedFor = request.headers.get("x-forwarded-for");
  const ipAddress = forwardedFor?.split(",")[0]?.trim() || null;

  await db.query(
    `
      INSERT INTO sessions (
        user_id,
        session_id,
        device_type,
        device_name,
        ip_address,
        user_agent,
        status,
        last_active_at,
        expires_at
      )
      VALUES ($1, $2, 'WEB', 'Zeka Media Web', $3, $4, 'ACTIVE', NOW(), $5)
    `,
    [userId, sessionHash, ipAddress, userAgent, expiresAt]
  );

  const cookieStore = await cookies();
  cookieStore.set(COOKIE_NAME, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    expires: expiresAt,
  });
}

export async function getCurrentWebUser() {
  const cookieStore = await cookies();
  const token = cookieStore.get(COOKIE_NAME)?.value;

  if (!token || !/^[a-f0-9]{64}$/.test(token)) {
    return null;
  }

  const sessionHash = hashSessionToken(token);
  const result = await db.query(
    `
      SELECT
        u.id,
        u.telegram_user_id,
        u.username,
        u.display_name,
        u.language,
        u.is_pro,
        u.pro_expires_at,
        s.id AS session_row_id
      FROM sessions s
      INNER JOIN users u ON u.id = s.user_id
      WHERE s.session_id = $1
        AND s.status = 'ACTIVE'
        AND s.revoked_at IS NULL
        AND s.expires_at > NOW()
      LIMIT 1
    `,
    [sessionHash]
  );

  const user = result.rows[0];
  if (!user) return null;

  await db.query(
    "UPDATE sessions SET last_active_at = NOW() WHERE id = $1",
    [user.session_row_id]
  );

  return {
    id: String(user.id),
    telegramUserId: String(user.telegram_user_id),
    username: user.username,
    displayName: user.display_name,
    language: user.language,
    isPro: Boolean(user.is_pro) &&
      (!user.pro_expires_at || new Date(user.pro_expires_at).getTime() > Date.now()),
    proExpiresAt: user.pro_expires_at,
  };
}

export async function revokeCurrentWebSession() {
  const cookieStore = await cookies();
  const token = cookieStore.get(COOKIE_NAME)?.value;

  if (token && /^[a-f0-9]{64}$/.test(token)) {
    await db.query(
      `
        UPDATE sessions
        SET status = 'REVOKED', revoked_at = NOW()
        WHERE session_id = $1 AND status = 'ACTIVE'
      `,
      [hashSessionToken(token)]
    );
  }

  cookieStore.delete(COOKIE_NAME);
}
