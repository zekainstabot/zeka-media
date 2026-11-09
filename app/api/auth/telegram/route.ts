import { createHmac, timingSafeEqual } from "crypto";
import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { createUserSession } from "@/lib/session";

export const runtime = "nodejs";

function verifyTelegramLogin(data: Record<string, unknown>) {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  if (!botToken) throw new Error("TELEGRAM_BOT_TOKEN is not configured");

  const hash = typeof data.hash === "string" ? data.hash : "";
  const authDate = Number(data.auth_date);

  if (!/^[a-f0-9]{64}$/i.test(hash)) return false;
  if (!Number.isInteger(authDate)) return false;

  const now = Math.floor(Date.now() / 1000);
  if (authDate > now + 30 || now - authDate > 600) return false;

  const checkString = Object.entries(data)
    .filter(([key, value]) => key !== "hash" && value !== undefined && value !== null)
    .map(([key, value]) => `${key}=${String(value)}`)
    .sort()
    .join("\n");

  const secretKey = createHash("sha256").update(botToken).digest();
  const expected = createHmac("sha256", secretKey)
    .update(checkString)
    .digest();

  const received = Buffer.from(hash, "hex");
  return received.length === expected.length &&
    timingSafeEqual(received, expected);
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return NextResponse.json({ error: "INVALID_LOGIN_DATA" }, { status: 400 });
    }

    if (!verifyTelegramLogin(body)) {
      return NextResponse.json({ error: "TELEGRAM_AUTH_FAILED" }, { status: 401 });
    }

    const telegramId = String(body.id || "");
    if (!/^\d{1,20}$/.test(telegramId)) {
      return NextResponse.json({ error: "INVALID_TELEGRAM_ID" }, { status: 400 });
    }

    const result = await db.query(
      `
        SELECT id
        FROM users
        WHERE telegram_user_id = $1
        LIMIT 1
      `,
      [telegramId]
    );

    const user = result.rows[0];
    if (!user) {
      return NextResponse.json(
        { error: "BOT_ACCOUNT_REQUIRED", message: "ابتدا ربات زکا را فعال کنید." },
        { status: 403 }
      );
    }

    await createUserSession(String(user.id), request);
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Telegram web login failed:", error);
    return NextResponse.json({ error: "LOGIN_UNAVAILABLE" }, { status: 500 });
  }
}
