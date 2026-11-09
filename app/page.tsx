const features = [
  { number: "01", title: "دانلود سریع", description: "دریافت محتوای اینستاگرام با چند کلیک ساده." },
  { number: "02", title: "مدیریت یکپارچه", description: "ابزارهای موردنیاز زکا مدیا در یک فضای مرتب." },
  { number: "03", title: "حساب کاربری", description: "مسیر ورود به امکانات و اشتراک زکا در یک پنل." },
];

export default function HomePage() {
  return (
    <main className="site-shell">
      <header className="topbar">
        <a className="brand" href="/" aria-label="صفحه اصلی زکا مدیا">
          <span className="brand-mark">Z</span>
          <span>zeka<span className="brand-light">media</span></span>
        </a>
        <nav className="nav-links" aria-label="منوی اصلی">
          <a href="#features">امکانات</a>
          <a href="#about">درباره ما</a>
        </nav>
        <a className="login-link" href="/login">ورود به حساب <span>↗</span></a>
      </header>

      <section className="hero" id="about">
        <div className="hero-glow" />
        <div className="hero-copy">
          <div className="eyebrow"><span className="status-dot" /> نسل تازه ابزارهای محتوایی</div>
          <h1>محتوای موردعلاقه‌ات،<br /><span>یک قدم نزدیک‌تر.</span></h1>
          <p className="hero-description">
            زکا مدیا، فضای ساده و سریع برای دریافت و مدیریت محتوای شبکه‌های اجتماعی.
            بدون پیچیدگی، با تجربه‌ای یکپارچه.
          </p>
          <div className="hero-actions">
            <a className="primary-button" href="/dashboard">ورود به زکا مدیا <span>←</span></a>
            <a className="secondary-button" href="#features">آشنایی با امکانات</a>
          </div>
          <div className="hero-note"><span className="note-icon">✦</span> متصل به تجربه زکا</div>
        </div>

        <div className="preview-wrap" aria-label="پیش‌نمایش پنل زکا مدیا">
          <div className="preview-card">
            <div className="preview-top"><span className="preview-logo">Z</span><span className="preview-label">فضای کاری شما</span><span className="preview-menu">•••</span></div>
            <div className="preview-heading">خوش اومدی 👋</div>
            <div className="preview-subtitle">امروز چه محتوایی نیاز داری؟</div>
            <div className="download-box"><div className="download-icon">↓</div><div><strong>دریافت محتوای جدید</strong><small>لینک پست یا ویدیو را وارد کن</small></div><span className="arrow">←</span></div>
            <div className="preview-stats"><div><small>وضعیت حساب</small><strong className="active-status">آماده استفاده</strong></div><div><small>سرویس</small><strong>Zeka Media</strong></div></div>
            <div className="preview-progress"><span /></div>
            <div className="preview-footer"><span>قدرت گرفته از زکا</span><span className="footer-spark">✦</span></div>
          </div>
          <div className="floating-chip"><span>✦</span> ساده، سریع، یکپارچه</div>
        </div>
      </section>

      <section className="features-section" id="features">
        <div className="section-heading"><span>امکانات زکا مدیا</span><h2>همه‌چیز برای یک تجربه روان</h2></div>
        <div className="feature-grid">
          {features.map((feature) => (
            <article className="feature-card" key={feature.number}>
              <span className="feature-number">{feature.number}</span>
              <h3>{feature.title}</h3>
              <p>{feature.description}</p>
              <span className="feature-arrow">↙</span>
            </article>
          ))}
        </div>
      </section>
      <footer><span className="footer-brand">zeka<span>media</span></span><span>© {new Date().getFullYear()} Zeka Media</span></footer>
    </main>
  );
}
