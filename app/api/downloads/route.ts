import { NextResponse } from "next/server";
import { getCurrentWebUser } from "@/lib/session";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function botConfig() {
  const base = process.env.ZEKA_BOT_API_URL?.replace(/\/+$/, "");
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

    const search = new URL(request.url).searchParams;
    const jobId = search.get("id");
    if (!jobId || !/^\d+$/.test(jobId)) return NextResponse.json({ error: "INVALID_ID" }, { status: 400 });

    const { base, secret } = botConfig();
    const fileRequested = search.get("file") === "1";
    const previewRequested = search.get("preview") === "1";
    const streamRequested = fileRequested || previewRequested;
    const endpoint = streamRequested
      ? `${base}/api/web/downloads/${encodeURIComponent(jobId)}/file?userId=${encodeURIComponent(user.id)}${previewRequested ? "&preview=1" : ""}`
      : `${base}/api/web/downloads/${encodeURIComponent(jobId)}?userId=${encodeURIComponent(user.id)}`;

    const requestHeaders: Record<string, string> = {
      "X-Zeka-Web-Secret": secret,
    };
    const range = request.headers.get("range");
    if (streamRequested && range) {
      requestHeaders.Range = range;
    }

    const response = await fetch(endpoint, {
      headers: requestHeaders,
      cache: "no-store",
      signal: AbortSignal.timeout(streamRequested ? 60000 : 10000),
    });

    if (streamRequested && response.ok && response.body) {
      const headers = new Headers({
        "Cache-Control": "private, no-store",
        "X-Content-Type-Options": "nosniff",
      });
      for (const name of [
        "content-type",
        "content-length",
        "content-disposition",
        "accept-ranges",
        "content-range",
      ]) {
        const value = response.headers.get(name);
        if (value) headers.set(name, value);
      }
      return new Response(response.body, {
        status: response.status,
        headers,
      });
    }

    const data = await response.json().catch(() => ({}));
    return NextResponse.json(data, { status: response.status, headers: { "Cache-Control": "no-store" } });
  } catch (error) {
    console.error("Website download status/file request failed:", error);
    return NextResponse.json({ error: "DOWNLOAD_SERVICE_UNAVAILABLE" }, { status: 503 });
  }
}
