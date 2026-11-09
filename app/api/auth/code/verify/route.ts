import { createHash, createHmac, timingSafeEqual } from "crypto";
import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { createUserSession } from "@/lib/session";

export const runtime = "nodejs";

function hashCode(token: string, code: string) {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  if (!botToken) throw new Error("TELEGRAM_BOT_TOKEN is not configured");
  return createHmac("sha256", botToken).update(`${token}:${code}`).digest();
}

export async function POST(request: Request) {
  const client = await db.connect();
  let committed = false;

  try {
    const body = await request.json();
    const token = typeof body?.token === "string" ? body.token : "";
    const code = typeof body?.code === "string" ? body.code.trim() : "";

    if (!/^[A-Za-z0-9_-]{43}$/.test(token) || !/^\d{6}$/.test(code)) {
      return NextResponse.json({ error: "INVALID_CODE_FORMAT" }, { status: 400 });
    }

    const tokenHash = createHash("sha256").update(token).digest("hex");
    const expectedCodeHash = hashCode(token, code);

    await client.query("BEGIN");

    const result = await client.query(
      `
        SELECT user_id, code_hash, attempts, expires_at, verified_at
        FROM web_login_challenges
        WHERE token_hash = $1
        FOR UPDATE
      `,
      [tokenHash]
    );

    const challenge = result.rows[0];

    if (!challenge || challenge.verified_at || new Date(challenge.expires_at).getTime() <= Date.now()) {
      await client.query("COMMIT");
      committed = true;
      return NextResponse.json({ error: "CHALLENGE_EXPIRED" }, { status: 410 });
    }

    if (Number(challenge.attempts) >= 5) {
      await client.query("COMMIT");
      committed = true;
      return NextResponse.json({ error: "TOO_MANY_ATTEMPTS" }, { status: 429 });
    }

    if (!challenge.user_id || !challenge.code_hash) {
      await client.query("COMMIT");
      committed = true;
      return NextResponse.json({ error: "CODE_NOT_SENT" }, { status: 409 });
    }

    const storedHash = Buffer.from(String(challenge.code_hash).trim(), "hex");
    const valid = storedHash.length === expectedCodeHash.length &&
      timingSafeEqual(storedHash, expectedCodeHash);

    if (!valid) {
      await client.query(
        "UPDATE web_login_challenges SET attempts = attempts + 1 WHERE token_hash = $1",
        [tokenHash]
      );
      await client.query("COMMIT");
      committed = true;
      return NextResponse.json({ error: "INVALID_CODE" }, { status: 401 });
    }

    await client.query(
      "UPDATE web_login_challenges SET verified_at = NOW() WHERE token_hash = $1",
      [tokenHash]
    );
    await client.query("COMMIT");
    committed = true;

    await createUserSession(String(challenge.user_id), request);
    return NextResponse.json({ success: true });
  } catch (error) {
    if (!committed) {
      try { await client.query("ROLLBACK"); } catch {}
    }
    console.error("Web login verification failed:", error);
    return NextResponse.json({ error: "LOGIN_UNAVAILABLE" }, { status: 500 });
  } finally {
    client.release();
  }
}
