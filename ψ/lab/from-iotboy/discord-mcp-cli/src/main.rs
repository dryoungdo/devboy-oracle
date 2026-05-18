// dmcp — Discord MCP-shaped CLI
//
// Mirrors `plugin:discord:discord__fetch_messages` MCP tool shape but skips
// the JSON-RPC daemon — talks Discord's HTTP API directly with the bot token.
// Token loaded from `.env` in CWD (per P'Nat's directive: "use .envrc / dotenv
// and local dir, not $HOME").

use anyhow::{Context, Result};
use chrono::DateTime;
use clap::{Parser, Subcommand};
use serde::Deserialize;

#[derive(Parser, Debug)]
#[command(
    name = "dmcp",
    version,
    about = "Discord MCP-shaped CLI (wraps fetch_messages, no daemon)",
    long_about = "Reads .env in CWD for DISCORD_BOT_TOKEN. Mirrors the plugin:discord:discord MCP tool shape."
)]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand, Debug)]
enum Cmd {
    /// Fetch recent messages from a channel (oldest-first, like the MCP tool)
    FetchMessages {
        /// Channel snowflake (e.g. 1500775333283237970)
        channel: String,

        /// Max messages to return (Discord caps at 100)
        #[arg(short, long, default_value_t = 20)]
        limit: u32,

        /// Emit JSON instead of human-readable lines
        #[arg(short, long)]
        json: bool,
    },
}

#[derive(Debug, Deserialize)]
struct DiscordMessage {
    id: String,
    content: String,
    timestamp: String,
    author: DiscordUser,
}

#[derive(Debug, Deserialize)]
struct DiscordUser {
    id: String,
    username: String,
}

async fn fetch_messages(token: &str, channel: &str, limit: u32) -> Result<Vec<DiscordMessage>> {
    let url = format!(
        "https://discord.com/api/v10/channels/{}/messages?limit={}",
        channel, limit
    );
    let client = reqwest::Client::new();
    let resp = client
        .get(&url)
        .header("Authorization", format!("Bot {}", token))
        .header("User-Agent", "dmcp/0.1 (iotboy)")
        .send()
        .await
        .with_context(|| format!("GET {}", url))?;

    if !resp.status().is_success() {
        let status = resp.status();
        let body = resp.text().await.unwrap_or_default();
        anyhow::bail!("Discord API error {}: {}", status, body);
    }

    // Discord returns newest-first. Reverse so the output mirrors the MCP tool
    // (which emits oldest-first).
    let mut msgs: Vec<DiscordMessage> = resp.json().await.context("parsing JSON body")?;
    msgs.reverse();
    Ok(msgs)
}

fn print_human(msgs: &[DiscordMessage]) {
    for m in msgs {
        let ts = DateTime::parse_from_rfc3339(&m.timestamp)
            .map(|t| t.format("%Y-%m-%dT%H:%M:%SZ").to_string())
            .unwrap_or_else(|_| m.timestamp.clone());
        let content = m.content.replace('\n', " ⏎ ");
        println!(
            "[{}] {}: {}  (id: {})",
            ts, m.author.username, content, m.id
        );
    }
}

fn print_json(msgs: &[DiscordMessage]) -> Result<()> {
    // Re-shape to match the MCP tool's likely on-wire schema for parity.
    let shaped: Vec<_> = msgs
        .iter()
        .map(|m| {
            serde_json::json!({
                "ts": m.timestamp,
                "id": m.id,
                "user": m.author.username,
                "user_id": m.author.id,
                "content": m.content,
            })
        })
        .collect();
    println!("{}", serde_json::to_string_pretty(&shaped)?);
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    // Load .env from CWD (per P'Nat: "local dir, not $HOME")
    let _ = dotenvy::dotenv();

    let cli = Cli::parse();

    match cli.cmd {
        Cmd::FetchMessages { channel, limit, json } => {
            let token = std::env::var("DISCORD_BOT_TOKEN")
                .context("DISCORD_BOT_TOKEN not set — put it in ./.env (per P'Nat: local dir)")?;
            let limit = limit.min(100);
            let msgs = fetch_messages(&token, &channel, limit).await?;
            if json {
                print_json(&msgs)?;
            } else {
                print_human(&msgs);
            }
        }
    }
    Ok(())
}
