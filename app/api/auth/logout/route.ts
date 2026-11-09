import { NextResponse } from "next/server";
import { revokeCurrentWebSession } from "@/lib/session";

export const runtime = "nodejs";

export async function POST() {
  try {
    await revokeCurrentWebSession();
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Web logout failed:", error);
    return NextResponse.json({ error: "LOGOUT_UNAVAILABLE" }, { status: 500 });
  }
}
