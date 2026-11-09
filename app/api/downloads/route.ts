import { NextResponse } from "next/server";
import { getCurrentWebUser } from "@/lib/session";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function botConfig() {
  const base = process.env.ZEKA_BOT_API_URL?.replace(/\\/+$/, "");
  const secret = process.env.ZEKA_WEB_API_SECRET;
  if (!base || !secret) throw new Error("BOT_API_NOT_CONFIGURED");
  return { base, secret };
}

export async function POST(request: Request) {
  try {
    const user = await getCurrentWebUser();
    if (!user) return NextResponse.json({ error: "UNAUTHORIZED" }, { status: 401 });

    const body = await request.json();
    const url = String(body?.url || "").trim();
    if (!url || url.length > 2048) return NextResponse.json({ error: "INVALID_URL" }, { status: 400 });

    const { base, secret } = botConfig();
    const response = await fetch(`${base}/api/web/downloads`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Zeka-Web-Secret": secret },
      body: JSON.stringify({ userId: user.id, url }),
      cache: "no-store",
      signal: AbortSignal.timeout(15000),
    });
    const data = await response.json().catch(() => ({}));
    return NextResponse.json(data, { status: response.status, headers: { "Cache-Control": "no-store" } });
  } catch (error) {
    console.error("Website download submit failed:", error);
    return NextResponse.json({ error: "DOWNLOAD_SERVICE_UNAVAILABLE" }, { status: 503 });
  }
}

export async function GET(request: Request) {
  try {
    const user = await getCurrentWebUser();
    if (!user) return NextResponse.json({ error: "UNAUTHORIZED" }, { status: 401 });

    const jobId = new URL(request.url).searchParams.get("id");
    if (!jobId || !/^\\d+$/.test(jobId)) return NextResponse.json({ error: "INVALID_ID" }, { status: 400 });

    const { base, secret } = botConfig();
    const response = await fetch(`${base}/api/web/downloads/${encodeURIComponent(jobId)}?userId=${encodeURIComponent(user.id)}`, {
      headers: { "X-Zeka-Web-Secret": secret },
      cache: "no-store",
      signal: AbortSignal.timeout(10000),
    });
    const data = await response.json().catch(() => ({}));
    return NextResponse.json(data, { status: response.status, headers: { "Cache-Control": "no-store" } });
  } catch (error) {
    console.error("Website download status failed:", error);
    return NextResponse.json({ error: "DOWNLOAD_SERVICE_UNAVAILABLE" }, { status: 503 });
  }
}
