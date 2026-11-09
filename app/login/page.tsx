"use client";

import { FormEvent, useState } from "react";

export default function LoginPage() {
  const [token, setToken] = useState("");
  const [botUrl, setBotUrl] = useState("");
  const [code, setCode] = useState("");
  const [step, setStep] = useState<"start" | "code">("start");
  const [status, setStatus] = useState("");
  const [loading, setLoading] = useState(false);

  async function requestCode() {
    setLoading(true);
    setStatus("در حال ساخت لینک امن ورود...");
    try {
      const response = await fetch("/api/auth/code/start", { method: "POST" });
      const data = await response.json();
      if (!response.ok) throw new Error("ساخت لینک ورود انجام نشد. دوباره تلاش کن.");
      setToken(data.token);
      setBotUrl(data.botUrl);
      setStep("code");
      setStatus("۱) ربات زکا را باز کن و Start را بزن. ۲) کد ارسال‌شده را اینجا وارد کن.");
    } catch (error) {
      setStatus(error instanceof Error ? error.message : "خطا در ارتباط با سرور.");
    } finally {
      setLoading(false);
    }
  }

  async function verifyCode(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setStatus("در حال بررسی کد...");
    try {
      const response = await fetch("/api/auth/code/verify", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token, code }),
      });
      const data = await response.json();

      if (!response.ok) {
        const messages: Record<string, string> = {
          CODE_NOT_SENT: "هنوز کدی دریافت نشده؛ ابتدا لینک ربات را باز کن و Start را بزن.",
          INVALID_CODE: "کد اشتباه است. دوباره بررسی کن.",
          CHALLENGE_EXPIRED: "مهلت کد تمام شده؛ کد جدید بگیر.",
          TOO_MANY_ATTEMPTS: "تعداد تلاش‌ها بیش از حد مجاز است؛ کد جدید بگیر.",
        };
        throw new Error(messages[data.error] || "ورود تأیید نشد.");
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
          برای ورود، ربات رسمی زکا یک کد یک‌بارمصرف برایت می‌فرستد.
          ما شماره تلفن، رمز عبور یا کد ورود تلگرام را نمی‌خواهیم.
        </p>

        {step === "start" ? (
          <button className="auth-action" type="button" onClick={requestCode} disabled={loading}>
            {loading ? "لطفاً صبر کن..." : "دریافت کد از ربات زکا"}
          </button>
        ) : (
          <>
            <a className="telegram-start-link" href={botUrl} target="_blank" rel="noreferrer">
              باز کردن ربات زکا و دریافت کد
            </a>
            <form className="login-code-form" onSubmit={verifyCode}>
              <label htmlFor="login-code">کد ۶ رقمی ارسال‌شده در ربات</label>
              <input
                id="login-code"
                className="login-code-input"
                inputMode="numeric"
                autoComplete="one-time-code"
                pattern="[0-9]{6}"
                maxLength={6}
                placeholder="مثلاً ۱۲۳۴۵۶"
                value={code}
                onChange={(event) => setCode(event.target.value.replace(/\D/g, "").slice(0, 6))}
                required
              />
              <button className="auth-action" type="submit" disabled={loading || code.length !== 6}>
                {loading ? "در حال بررسی..." : "تأیید کد و ورود"}
              </button>
            </form>
            <button
              className="auth-resend"
              type="button"
              disabled={loading}
              onClick={() => { setStep("start"); setToken(""); setBotUrl(""); setCode(""); setStatus(""); }}
            >
              دریافت کد جدید
            </button>
          </>
        )}

        <p className="auth-status">{status}</p>
        <a className="back-link" href="/">بازگشت به صفحه اصلی</a>
        <div className="auth-security">
          کد فقط برای همین ورود است · اعتبار ۱۰ دقیقه · هرگز کد را در اختیار دیگران نگذار
        </div>
      </section>
    </main>
  );
}
