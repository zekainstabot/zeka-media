import { NextResponse } from "next/server";
import { getCurrentWebUser } from "@/lib/session";

export const runtime = "nodejs";

export async function GET() {
  try {
    const user = await getCurrentWebUser();
    if (!user) {
      return NextResponse.json({ authenticated: false }, { status: 401 });
    }

    return NextResponse.json({ authenticated: true, user });
  } catch (error) {
    console.error("Web session lookup failed:", error);
    return NextResponse.json({ error: "SESSION_UNAVAILABLE" }, { status: 500 });
  }
}
