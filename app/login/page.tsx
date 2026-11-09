"use client";

import { useEffect, useRef, useState } from "react";

declare global {
  interface Window {
    onTelegramAuth?: (user: Record<string, unknown>) => void;
  }
}

export default function LoginPage() {
  const widgetContainer = useRef<HTMLDivElement>(null);
  const [status, setStatus] = useState("برای ورود، حساب تلگرام خود را انتخاب کنید.");
  const [loading, setLoading] = useState(false);
  const botUsername = process.env.NEXT_PUBLIC_TELEGRAM_BOT_USERNAME?.replace(/^@/, "").trim();

  useEffect(() => {
    window.onTelegramAuth = async (telegramUser) => {
      setLoading(true);
      setStatus("در حال بررسی حساب تلگرام...");
      try {
        const response = await fetch("/api/auth/telegram", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(telegramUser),
        });
        const data = await response.json();

        if (!response.ok) {
          if (data.error === "BOT_ACCOUNT_REQUIRED") {
            setStatus("ابتدا ربات زکا را در تلگرام Start کنید و سپس دوباره وارد شوید.");
          } else {
            setStatus("ورود تأیید نشد. دوباره تلاش کنید.");
          }
          return;
        }

        window.location.href = "/dashboard";
      } catch {
        setStatus("ارتباط با سرور برقرار نشد.");
      } finally {
        setLoading(false);
      }
    };

    const container = widgetContainer.current;
    if (container && botUsername) {
      container.replaceChildren();
      const script = document.createElement("script");
      script.async = true;
      script.src = "https://telegram.org/js/telegram-widget.js?22";
      script.setAttribute("data-telegram-login", botUsername);
      script.setAttribute("data-size", "large");
      script.setAttribute("data-radius", "10");
      script.setAttribute("data-userpic", "false");
      script.setAttribute("data-request-access", "write");
      script.setAttribute("data-onauth", "onTelegramAuth(user)");
      container.appendChild(script);
    }

    return () => {
      if (container) container.replaceChildren();
      delete window.onTelegramAuth;
    };
  }, [botUsername]);

  return (
    <main className="auth-page">
      <section className="auth-card">
        <a className="brand auth-brand" href="/">
          <span className="brand-mark">Z</span>
          <span>zeka<span className="brand-light">media</span></span>
        </a>
        <div className="auth-symbol">✦</div>
        <p className="auth-kicker">ورود امن و یکپارچه</p>
        <h1 className="auth-title">به زکا مدیا خوش آمدی</h1>
        <p className="auth-description">
          با همان حساب تلگرامی که در ربات زکا استفاده می‌کنی وارد شو.
          اطلاعات حساب و وضعیت اشتراک از حساب اصلی خوانده می‌شود.
        </p>

        {botUsername ? (
          <div className="telegram-login" ref={widgetContainer} />
        ) : (
          <p className="auth-status error">نام کاربری ربات در تنظیمات سرور ثبت نشده است.</p>
        )}

        <p className={`auth-status ${loading ? "loading" : ""}`}>{status}</p>
        <a className="back-link" href="/">بازگشت به صفحه اصلی</a>
        <div className="auth-security">اتصال رمزنگاری‌شده · بدون دریافت رمز عبور تلگرام</div>
      </section>
    </main>
  );
}
