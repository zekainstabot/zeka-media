import { createHash, randomBytes } from "crypto";
import { NextResponse } from "next/server";
import { db } from "@/lib/db";

export const runtime = "nodejs";

export async function POST() {
  try {
    const username = process.env.NEXT_PUBLIC_TELEGRAM_BOT_USERNAME
      ?.replace(/^@/, "")
      .trim();

    if (!username || !/^[A-Za-z0-9_]{5,32}$/.test(username)) {
      return NextResponse.json({ error: "BOT_USERNAME_NOT_CONFIGURED" }, { status: 503 });
    }

    const token = randomBytes(32).toString("base64url");
    const tokenHash = createHash("sha256").update(token).digest("hex");

    await db.query(
      `
        INSERT INTO web_login_challenges (token_hash, expires_at)
        VALUES ($1, NOW() + INTERVAL '10 minutes')
      `,
      [tokenHash]
    );

    return NextResponse.json({
      success: true,
      token,
      botUrl: `https://t.me/${username}?start=web_${token}`,
      expiresIn: 600,
    });
  } catch (error) {
    console.error("Web login challenge creation failed:", error);
    return NextResponse.json({ error: "LOGIN_UNAVAILABLE" }, { status: 500 });
  }
}
