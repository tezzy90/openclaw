# Slack Setup Guide for OpenClaw

## Step 1: Create a Slack App

1. Go to https://api.slack.com/apps
2. Click **Create New App** > **From scratch**
3. Name it whatever you want (e.g., "My Agent")
4. Select your workspace
5. Click **Create App**

## Step 2: Configure Bot Permissions

1. In the left sidebar, click **OAuth & Permissions**
2. Scroll to **Scopes** > **Bot Token Scopes**
3. Add these scopes:
   - `chat:write` (send messages)
   - `chat:write.public` (send to channels without joining)
   - `app_mentions:read` (respond when @mentioned)
   - `channels:history` (read channel messages)
   - `channels:read` (list channels)
   - `groups:history` (read private channel messages)
   - `groups:read` (list private channels)
   - `im:history` (read DMs)
   - `im:read` (list DMs)
   - `im:write` (send DMs)
   - `files:write` (upload files/images)
   - `reactions:write` (add emoji reactions)
   - `users:read` (read user profiles)

## Step 3: Enable Socket Mode

1. In the left sidebar, click **Socket Mode**
2. Toggle **Enable Socket Mode** to ON
3. It will ask you to create an App-Level Token
4. Name it "socket" and add scope `connections:write`
5. Click **Generate**
6. Copy the token (starts with `xapp-`) — this is your `SLACK_APP_TOKEN`

## Step 4: Enable Events

1. In the left sidebar, click **Event Subscriptions**
2. Toggle **Enable Events** to ON
3. Under **Subscribe to bot events**, add:
   - `app_mention` (when someone @mentions your bot)
   - `message.channels` (messages in public channels)
   - `message.groups` (messages in private channels)
   - `message.im` (direct messages to your bot)
4. Click **Save Changes**

## Step 5: Install to Workspace

1. In the left sidebar, click **Install App**
2. Click **Install to Workspace**
3. Click **Allow**
4. Copy the **Bot User OAuth Token** (starts with `xoxb-`) — this is your `SLACK_BOT_TOKEN`

## Step 6: Add Tokens to .env

Open your `deploy/.env` file and add:

```
SLACK_BOT_TOKEN=xoxb-your-token-here
SLACK_APP_TOKEN=xapp-your-token-here
```

## Step 7: Add Slack Channel in OpenClaw

After starting OpenClaw:

```bash
./start.sh --cli channels add --channel slack
```

## Step 8: Invite Your Bot

In Slack:
1. Go to the channel where you want your agent
2. Type `/invite @YourBotName`
3. Send a message mentioning your bot: `@YourBotName hello`

Your agent should respond.

## Tips

- **DMs work too**: Just open a DM with your bot and type normally
- **Threads**: The bot respects Slack threads — reply in a thread to keep
  conversations organized
- **Multiple channels**: Invite the bot to different channels for different
  agent personas (bind agents to channels via `openclaw agents add`)
