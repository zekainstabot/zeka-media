"use client";

import { FormEvent, useState } from "react";

export default function LoginPage() {
  const [code, setCode] = useState("");
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState("کد اختصاصی را از دکمه «اتصال به زکا مدیا» در ربات دریافت کن.");

  async function verifyCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setStatus("در حال بررسی کد اتصال...");
    try {
      const response = await fetch("/api/auth/code/verify", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code }),
      });
      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error === "INVALID_CODE"
          ? "کد اتصال اشتباه یا باطل شده است. کد را از ربات بررسی کن."
          : "ورود انجام نشد. دوباره تلاش کن.");
      }

      window.location.href = "/dashboard";
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "خطا در ارتباط با سرور.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="auth-page">
      <section className="auth-card">
        <a className="brand auth-brand" href="/">
          <span className="brand-mark">Z</span>
          <span>zeka<span className="brand-light">media</span></span>
        </a>
        <div className="auth-symbol">✦</div>
        <p className="auth-kicker">ورود امن بدون شماره تلفن</p>
        <h1 className="auth-title">ورود به زکا مدیا</h1>
        <p className="auth-description">
          در ربات زکا وارد بخش «🌐 اتصال به زکا مدیا» شو و کد اختصاصی خودت را دریافت کن.
          همان کد برای ورودهای بعدی هم معتبر می‌ماند.
        </p>

        <form className="login-code-form" onSubmit={verifyCode}>
          <label htmlFor="login-code">کد اختصاصی اتصال</label>
          <input
            id="login-code"
            className="login-code-input"
            type="text"
            inputMode="text"
            autoComplete="off"
            spellCheck={false}
            maxLength={32}
            placeholder="کد دریافتی از ربات"
            value={code}
            onChange={(event) => setCode(event.target.value.replace(/\s/g, "").toUpperCase())}
            required
          />
          <button className="auth-action" type="submit" disabled={loading || code.length < 20}>
            {loading ? "در حال بررسی..." : "ورود به زکا مدیا"}
          </button>
        </form>

        <p className="auth-status">{status}</p>
        <a className="back-link" href="/">بازگشت به صفحه اصلی</a>
        <div className="auth-security">
          بدون شماره تلفن و رمز تلگرام · کد اتصال را محرمانه نگه دار
        </div>
      </section>
    </main>
  );
}
