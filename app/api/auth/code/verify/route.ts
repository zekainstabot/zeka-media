import { createHash, timingSafeEqual } from "crypto";
import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { createUserSession } from "@/lib/session";

export const runtime = "nodejs";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const code = typeof body?.code === "string"
      ? body.code.replace(/\s/g, "").toUpperCase()
      : "";

    if (!/^[A-Z0-9_-]{20,32}$/.test(code)) {
      return NextResponse.json({ error: "INVALID_CODE_FORMAT" }, { status: 400 });
    }

    const codeHash = createHash("sha256").update(code).digest("hex");
    const result = await db.query(
      `
        SELECT u.id
        FROM web_login_credentials c
        INNER JOIN users u ON u.id = c.user_id
        WHERE c.code_hash = $1
          AND c.revoked_at IS NULL
        LIMIT 1
      `,
      [codeHash]
    );

    const user = result.rows[0];
    if (!user) {
      return NextResponse.json({ error: "INVALID_CODE" }, { status: 401 });
    }

    await createUserSession(String(user.id), request);
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Persistent web login failed:", error);
    return NextResponse.json({ error: "LOGIN_UNAVAILABLE" }, { status: 500 });
  }
}
