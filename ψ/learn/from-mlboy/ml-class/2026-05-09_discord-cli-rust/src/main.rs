//! discord-read — minimal CLI to read Discord messages via REST API v10.
//!
//! Wraps the same wire protocol the MCP plugin uses. Token resolution
//! follows local-first per P'Nat's class guidance:
//!   1. `--token` flag
//!   2. `DISCORD_BOT_TOKEN` env var
//!   3. `.env` file in current dir (loaded via dotenvy)
//!   4. `.discord-state/.env` (mlboy project convention)
//!
//! Usage examples:
//!   discord-read messages --channel 1500775333283237970 --limit 5
//!   discord-read messages -c 1500775333283237970 -l 3 --format json

use anyhow::{anyhow, Context, Result};
use clap::{Parser, Subcommand, ValueEnum};
use serde::Deserialize;

#[derive(Parser, Debug)]
#[command(name = "discord-read", version, about = "Read Discord messages via REST API")]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,

    /// Bot token (overrides env / dotenv)
    #[arg(long, global = true, env = "DISCORD_BOT_TOKEN", hide_env_values = true)]
    token: Option<String>,
}

#[derive(Subcommand, Debug)]
enum Cmd {
    /// Fetch recent messages from a channel
    Messages {
        /// Discord channel ID
        #[arg(short, long)]
        channel: String,

        /// Number of messages (1..=100)
        #[arg(short, long, default_value_t = 5, value_parser = clap::value_parser!(u32).range(1..=100))]
        limit: u32,

        /// Output format
        #[arg(short, long, value_enum, default_value_t = Format::Pretty)]
        format: Format,
    },
}

#[derive(Copy, Clone, Debug, ValueEnum)]
enum Format {
    Pretty,
    Json,
}

#[derive(Deserialize, Debug)]
struct DiscordMessage {
    id: String,
    timestamp: String,
    content: String,
    author: Author,
}

#[derive(Deserialize, Debug)]
struct Author {
    username: String,
    #[allow(dead_code)]
    id: String,
}

fn load_token(flag: Option<String>) -> Result<String> {
    if let Some(t) = flag {
        return Ok(t);
    }
    // Local-first dotenv resolution (P'Nat class rule)
    let _ = dotenvy::dotenv();
    let _ = dotenvy::from_filename(".discord-state/.env");
    std::env::var("DISCORD_BOT_TOKEN")
        .map_err(|_| anyhow!("token not found — pass --token, or set DISCORD_BOT_TOKEN in .env / .discord-state/.env"))
}

async fn fetch_messages(token: &str, channel: &str, limit: u32) -> Result<Vec<DiscordMessage>> {
    let url = format!(
        "https://discord.com/api/v10/channels/{channel}/messages?limit={limit}"
    );
    let client = reqwest::Client::new();
    let res = client
        .get(&url)
        .header("Authorization", format!("Bot {token}"))
        .header("User-Agent", "discord-read/0.1.0 (mlboy class proof)")
        .send()
        .await
        .context("HTTP request failed")?;

    let status = res.status();
    let body = res.text().await.context("read body failed")?;

    if !status.is_success() {
        return Err(anyhow!("Discord API {status}: {body}"));
    }
    serde_json::from_str(&body).context("parse JSON failed")
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    let token = load_token(cli.token)?;

    match cli.cmd {
        Cmd::Messages { channel, limit, format } => {
            let mut msgs = fetch_messages(&token, &channel, limit).await?;
            msgs.reverse(); // oldest-first for readability

            match format {
                Format::Json => println!("{}", serde_json::to_string_pretty(&serde_json::json!({
                    "channel": channel,
                    "count": msgs.len(),
                    "messages": msgs.iter().map(|m| serde_json::json!({
                        "id": m.id,
                        "ts": m.timestamp,
                        "user": m.author.username,
                        "content": m.content,
                    })).collect::<Vec<_>>(),
                }))?),
                Format::Pretty => {
                    for m in &msgs {
                        let ts = m.timestamp.get(0..19).unwrap_or(&m.timestamp).replace('T', " ");
                        let preview = m.content.replace('\n', " ");
                        let preview = preview.chars().take(80).collect::<String>();
                        println!("[{}] {}: {}", ts, m.author.username, preview);
                    }
                }
            }
        }
    }
    Ok(())
}
