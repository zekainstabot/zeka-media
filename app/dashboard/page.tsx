"use client";

import { useEffect, useState } from "react";

type User = {
  telegramUserId: string;
  username: string | null;
  displayName: string | null;
  isPro: boolean;
  proExpiresAt: string | null;
};

type Download = { id: string; status: string; originalUrl?: string; errorCode?: string | null; progressPercent?: number; progressMessage?: string | null; mediaContentType?: string | null; previewAvailable?: boolean };

const statusLabels: Record<string, string> = {
  WAITING: "در صف پردازش",
  PROCESSING: "در حال آماده‌سازی",
  DOWNLOADING: "در حال دانلود",
  DOWNLOADED: "در حال آماده‌سازی فایل",
  SENDING: "در حال ارسال",
  COMPLETED: "دانلود آماده است",
  FAILED: "دانلود ناموفق بود",
  CANCELLED: "لغو شده",
};

export default function DashboardPage() {
  const [user, setUser] = useState<User | null>(null);
  const [status, setStatus] = useState("در حال دریافت اطلاعات حساب...");
  const [url, setUrl] = useState("");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState("");
  const [downloads, setDownloads] = useState<Download[]>([]);

  useEffect(() => {
    fetch("/api/auth/me", { cache: "no-store" })
      .then(async (response) => {
        if (!response.ok) { window.location.href = "/login"; return null; }
        return response.json();
      })
      .then((data) => { if (data?.user) { setUser(data.user); setStatus(""); } })
      .catch(() => setStatus("دریافت اطلاعات حساب ناموفق بود."));
  }, []);

  async function logout() {
    await fetch("/api/auth/logout", { method: "POST" });
    window.location.href = "/";
  }

  async function submitDownload(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy) return;
    setBusy(true);
    setMessage("");
    try {
      const response = await fetch("/api/downloads", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url }),
      });
      const data = await response.json();
      if (!response.ok) {
        const errors: Record<string, string> = {
          INVALID_INSTAGRAM_URL: "لینک معتبر اینستاگرام وارد کن.",
          INVALID_URL: "لینک را وارد کن.",
          DUPLICATE_ACTIVE_REQUEST: "این لینک در حال حاضر در صف دانلود است.",
          PLATFORM_DISABLED: "دانلود اینستاگرام موقتاً غیرفعال است.",
          UNAUTHORIZED: "نشست شما منقضی شده؛ دوباره وارد شو.",
        };
        throw new Error(errors[data.error] || "ثبت درخواست دانلود انجام نشد.");
      }
      setMessage("درخواست ثبت شد. وضعیت دانلود در همین صفحه به‌روزرسانی می‌شود.");
      setUrl("");
      setDownloads((current) => [{ id: data.jobId, status: data.status || "WAITING" }, ...current.filter((item) => item.id !== data.jobId)]);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "ارتباط با سرویس دانلود برقرار نشد.");
    } finally {
      setBusy(false);
    }
  }

  useEffect(() => {
    const active = downloads.filter((item) => !["COMPLETED", "FAILED", "CANCELLED"].includes(item.status));
    if (!active.length) return;
    const timer = setInterval(async () => {
      const updates = await Promise.all(active.map(async (item) => {
        try {
          const response = await fetch(`/api/downloads?id=${encodeURIComponent(item.id)}`, { cache: "no-store" });
          if (!response.ok) return null;
          return await response.json();
        } catch { return null; }
      }));
      setDownloads((current) => current.map((item) => updates.find((update) => update?.id === item.id) || item));
    }, 2500);
    return () => clearInterval(timer);
  }, [downloads]);

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
            {user.isPro && user.proExpiresAt && <p className="expiry-line">اعتبار اشتراک تا {new Date(user.proExpiresAt).toLocaleDateString("fa-IR")}</p>}
          </div>
        ) : <p className="dashboard-status">{status}</p>}

        <section className="dashboard-placeholder">
          <span>✦</span>
          <h2>دانلود از اینستاگرام</h2>
          <p>لینک پست، ریلز یا استوری عمومی را وارد کن.</p>
          <form onSubmit={submitDownload} className="download-form">
            <input type="url" dir="ltr" value={url} onChange={(event) => setUrl(event.target.value)} placeholder="https://www.instagram.com/reel/..." required maxLength={2048} />
            <button type="submit" disabled={busy}>{busy ? "در حال ثبت..." : "شروع دانلود"}</button>
          </form>
          {message && <p role="status" className="dashboard-status">{message}</p>}
        </section>

        <section className="dashboard-placeholder">
          <h2>درخواست‌های اخیر</h2>
          {downloads.length === 0 ? <p>هنوز درخواستی در این نشست ثبت نشده است.</p> : downloads.map((item) => (
            <div key={item.id} className="download-history-row">
              <span>درخواست #{item.id}</span>
              <strong>{statusLabels[item.status] || item.status}</strong>
              {item.status === "DOWNLOADING" && (
                <div className="download-progress" role="status" aria-label="درصد پیشرفت دانلود">
                  <div className="download-progress-heading">
                    <span>{item.progressMessage || "در حال دریافت فایل از اینستاگرام"}</span>
                    <strong>{Math.max(0, Math.min(99, item.progressPercent || 0))}٪</strong>
                  </div>
                  <div className="download-progress-track">
                    <span style={{ width: `${Math.max(0, Math.min(99, item.progressPercent || 0))}%` }} />
                  </div>
                </div>
              )}
              {item.status === "FAILED" && item.errorCode === "DOWNLOAD_TIMEOUT" && (
                <p className="download-error-message">دانلود زمان‌بر شد و برای جلوگیری از انتظار طولانی متوقف شد. لطفاً کمی بعد دوباره تلاش کنید.</p>
              )}
              {item.status === "COMPLETED" && (
                <div className="download-actions">
                  {item.previewAvailable && item.mediaContentType === "VIDEO" && (
                    <video className="download-preview-video" controls preload="metadata" playsInline src={`/api/downloads?id=${encodeURIComponent(item.id)}&preview=1`}>
                      مرورگر شما از پخش ویدیو پشتیبانی نمی‌کند.
                    </video>
                  )}
                  {item.previewAvailable && item.mediaContentType === "PHOTO" && (
                    <a className="download-preview-image-link" href={`/api/downloads?id=${encodeURIComponent(item.id)}&preview=1`} target="_blank" rel="noreferrer">
                      <img className="download-preview-image" src={`/api/downloads?id=${encodeURIComponent(item.id)}&preview=1`} alt="پیش‌نمایش تصویر دانلودشده" loading="lazy" />
                    </a>
                  )}
                  {!item.previewAvailable && <span className="preview-unavailable">پیش‌نمایش در دسترس نیست یا مهلت نگهداری فایل تمام شده است.</span>}
                  <a className="download-file-link" href={`/api/downloads?id=${encodeURIComponent(item.id)}&file=1`}>
                    دریافت فایل
                  </a>
                </div>
              )}
            </div>
          ))}
        </section>
      </section>
    </main>
  );
}
