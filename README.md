# Zeka Media

Persian RTL web application built with Next.js. The first milestone includes the landing page, Telegram Login Widget authentication, and a user dashboard.

## Requirements

- Node.js 22+
- The PostgreSQL database already used by Zeka Bot
- The existing Zeka Telegram bot username and token

## Environment variables

Set these on the website hosting service:

- `DATABASE_URL`: same PostgreSQL database connection string used by Zeka Bot.
- `DATABASE_SSL=true`: only if required by the database provider.
- `DATABASE_SSL_REJECT_UNAUTHORIZED=false`: only if the provider requires relaxed certificate verification.
- `TELEGRAM_BOT_TOKEN`: existing Zeka Bot token. Server-side only; never use a `NEXT_PUBLIC_` prefix.
- `NEXT_PUBLIC_TELEGRAM_BOT_USERNAME`: bot username without @.

## Telegram domain setup

In Telegram, open @BotFather, select the existing Zeka bot, run `/setdomain`, and set the exact public website hostname. Telegram Login Widget authentication will not work until this is configured.

## Run locally

```bash
npm install
npm run dev
```

## Account and security model

- Telegram Login Widget signatures are verified server-side with the existing bot token.
- The Telegram ID is matched to the existing `users` table. The website does not create a duplicate user.
- Web sessions use the existing `sessions` table. Only a SHA-256 hash of the browser session token is stored in PostgreSQL.
- Pro status is read from the same user record as the bot.

Phone/password login is not enabled: the current bot user schema has no verified phone or password credential fields. A separate phone-verification and account-linking flow is required before enabling it safely.
