import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Zeka Media | زکا مدیا",
  description: "دانلود و مدیریت محتوای شبکه‌های اجتماعی با زکا مدیا",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="fa" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
