"use client";

import { useEffect, useState } from "react";

type User = {
  telegramUserId: string;
  username: string | null;
  displayName: string | null;
  isPro: boolean;
  proExpiresAt: string | null;
};

export default function DashboardPage() {
  const [user, setUser] = useState<User | null>(null);
  const [status, setStatus] = useState("در حال دریافت اطلاعات حساب...");

  useEffect(() => {
    fetch("/api/auth/me", { cache: "no-store" })
      .then(async (response) => {
        if (!response.ok) {
          window.location.href = "/login";
          return null;
        }
        return response.json();
      })
      .then((data) => {
        if (data?.user) {
          setUser(data.user);
          setStatus("");
        }
      })
      .catch(() => setStatus("دریافت اطلاعات حساب ناموفق بود."));
  }, []);

  async function logout() {
    await fetch("/api/auth/logout", { method: "POST" });
    window.location.href = "/";
  }

  return (
    <main className="dashboard-page">
      <header className="dashboard-topbar">
        <a className="brand" href="/"><span className="brand-mark">Z</span><span>zeka<span className="brand-light">media</span></span></a>
        <button className="logout-button" onClick={logout}>خروج از حساب</button>
      </header>
      <section className="dashboard-content">
        <p className="auth-kicker">پنل کاربری</p>
        <h1>داشبورد زکا مدیا</h1>
        {user ? (
          <div className="account-card">
            <div className="account-avatar">Z</div>
            <div className="account-info">
              <strong>{user.displayName || user.username || "کاربر زکا"}</strong>
              <span>شناسه تلگرام: {user.telegramUserId}</span>
            </div>
            <span className={user.isPro ? "pro-pill" : "free-pill"}>{user.isPro ? "Zeka Pro" : "حساب رایگان"}</span>
            {user.isPro && user.proExpiresAt && (
              <p className="expiry-line">اعتبار اشتراک تا {new Date(user.proExpiresAt).toLocaleDateString("fa-IR")}</p>
            )}
          </div>
        ) : <p className="dashboard-status">{status}</p>}
        <div className="dashboard-placeholder">
          <span>✦</span>
          <h2>فضای دانلود شما</h2>
          <p>اتصال دانلودر و تاریخچه دانلود در مرحله بعد به این بخش اضافه می‌شود.</p>
        </div>
      </section>
    </main>
  );
}
