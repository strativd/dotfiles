# Slack

Use this resource only when the user asked for a Slack bot, slash command,
channel notification, or Slack-thread workflow.

Prefer a web form, seeded data, or manual copy/paste if Slack setup would slow
the launch.

Whenever the user must do something in the Slack UI, give click-by-click
instructions. Do not say only "update Slack" or "configure Slack."

## Build Shape

- Stay on Vite. NEVER switch to Next.js because a vendor sample uses it.
- Copy `resources/slack-webhook/api/webhooks/slack.ts` from this skill's
  directory to `api/webhooks/slack.ts` in the app. That route verifies Slack
  signatures, answers URL verification, and replies in-thread to `@mentions`.
- Deploy to Vercel before Slack app setup so the webhook URL exists.

Ask which Slack workspace to install into. Use the domain they give
(`example.slack.com`). Do not assume a company workspace.

Webhook URL:

```text
https://<deployment-domain>/api/webhooks/slack
```

Google sign-in leaves `/api/webhooks/` public. Slack signing verifies those
requests. Do not put other handlers under `/api/webhooks/` unless they verify
their own signatures.

## Slack App Setup

1. Open [api.slack.com/apps](https://api.slack.com/apps).
2. Click **Create New App**.
3. Choose **From an app manifest**.
4. Select the workspace they named.
5. Paste a manifest like this, replacing the name and using the deployed
   webhook URL:

   ```yaml
   display_information:
     name: My Bot
     description: A Slack bot for the app
   features:
     bot_user:
       display_name: My Bot
       always_online: true
   oauth_config:
     scopes:
       bot:
         - app_mentions:read
         - channels:history
         - channels:read
         - chat:write
         - groups:history
         - groups:read
         - im:history
         - im:read
         - mpim:history
         - mpim:read
         - users:read
   settings:
     event_subscriptions:
       request_url: https://<deployment-domain>/api/webhooks/slack
       bot_events:
         - app_mention
         - message.channels
         - message.groups
         - message.im
         - message.mpim
     interactivity:
       is_enabled: true
       request_url: https://<deployment-domain>/api/webhooks/slack
     org_deploy_enabled: false
     socket_mode_enabled: false
     token_rotation_enabled: false
   ```

6. Click **Create**.
7. Click **Install App** in the left sidebar.
8. Click **Install App** and install it to the chosen workspace.
9. Approve the permissions.
10. Stay on **Install App** and copy **Bot User OAuth Token**.
11. Go to **Basic Information** in the left sidebar.
12. Scroll to **App Credentials** and copy **Signing Secret**.
13. Save those values in 1Password using [`secrets.md`](secrets.md):

    - `<app-name> Slack bot token`
    - `<app-name> Slack signing secret`

    Then load them into Vercel env from those items. Do not paste tokens into
    chat.

Do not commit Slack tokens, signing secrets, `.env.local`, or copied
credentials.

## Slack Bot Icon

When Slack integration is requested, start a background agent to generate a
512x512 PNG icon while the main build continues.

Requirements:

- Match the app name and purpose.
- Avoid Slack and company logos unless the user provides approved assets.
- Save to `<project-dir>/assets/slack-icon/slack-app-icon.png`.

When ready, tell the user the folder path and how to upload it:

1. Open [api.slack.com/apps](https://api.slack.com/apps).
2. Click the app name.
3. Open **Basic Information**.
4. Scroll to **Display Information**.
5. In **App icon & Preview**, click **+ Add App Icon** or **Replace**.
6. Choose `slack-app-icon.png` from `<project-dir>/assets/slack-icon/`.
7. Crop if prompted, then click **Save Changes**.

## Project Setup

Copy the webhook before creating the Slack app:

```text
api/webhooks/slack.ts
```

`@vercel/functions` is already required for hosting middleware. The webhook
uses `waitUntil` from that package so Slack gets an immediate `ok` while the
reply posts.

## Vercel Environment

Set production env vars from 1Password:

```bash
secret_value() {
  op item get "$1" --fields password --reveal 2>/dev/null \
    || op item get "$1" --fields credential --reveal
}

SLACK_BOT_TOKEN="$(secret_value "$APP_NAME Slack bot token")"
SLACK_SIGNING_SECRET="$(secret_value "$APP_NAME Slack signing secret")"
bunx vercel env add SLACK_BOT_TOKEN production --value "$SLACK_BOT_TOKEN" --yes --force
bunx vercel env add SLACK_SIGNING_SECRET production --value "$SLACK_SIGNING_SECRET" --yes --force
unset SLACK_BOT_TOKEN SLACK_SIGNING_SECRET
```

## Updating Existing Slack URLs

Use the deployed webhook URL for both **Event Subscriptions** and
**Interactivity & Shortcuts**.

Event Subscriptions:

1. Open [api.slack.com/apps](https://api.slack.com/apps).
2. Click the app name.
3. Open **Event Subscriptions**.
4. Turn **Enable Events** on.
5. Paste the webhook URL into **Request URL**.
6. Wait for **Verified**.
7. Click **Save Changes**.

Interactivity:

1. Open [api.slack.com/apps](https://api.slack.com/apps).
2. Click the app name.
3. Open **Interactivity & Shortcuts**.
4. Turn **Interactivity** on.
5. Paste the webhook URL into **Request URL**.
6. Click **Save Changes**.

## Local Test

1. Start the app locally.
2. Expose it with a tunnel, for example `ngrok http 3000`.
3. Set Slack's Request URL to `https://<tunnel-domain>/api/webhooks/slack`.
4. Invite the bot to a channel with `/invite @My Bot`.
5. Mention the bot and confirm it replies in the thread.

## Done When

- Slack app is installed in the workspace the user named.
- `SLACK_BOT_TOKEN` and `SLACK_SIGNING_SECRET` are set in Vercel.
- Event Subscriptions points at deployed `/api/webhooks/slack`.
- Interactivity points at the same deployed URL if enabled.
- The bot replies to a real @mention.

## Troubleshooting

- Rejected Request URL: confirm the endpoint is deployed or tunneled, returns
  the `challenge` JSON, and is not blocked by Google sign-in middleware.
- No @mention response: confirm `app_mentions:read`, `chat:write`, Request URL,
  and channel invite status.
- Webhook verification failure: recopy `SLACK_SIGNING_SECRET` from **Basic
  Information**.
