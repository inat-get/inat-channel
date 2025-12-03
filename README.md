# iNat Telegram Poster (DRAFT!)

[![Ruby](https://img.shields.io/badge/Ruby-3.4%2B-red.svg)](https://www.ruby-lang.org/)
[![Telegram Bot](https://img.shields.io/badge/Telegram-Bot-blue.svg)](https://core.telegram.org/bots)
[![iNaturalist API v2](https://img.shields.io/badge/iNaturalist-APIv2-green.svg)](https://www.inaturalist.org/pages/api+reference)

**Automated daily poster** that shares random **popular iNaturalist observations** (faves > 0) to Telegram channels. Supports **arbitrary API queries**, taxon hierarchy with emojis, precise geolocation, and regional project links.

## ✨ Features

- **Flexible queries**: `base_query` for projects, taxa, places, users, etc.
- **Smart posting**: Fresh observations (past N days) → backup pool → sent archive
- **Rich media**: Up to 10 full-size photos + interactive geolocation pins
- **Taxon emojis**: 🐦🌿🍄🦋 for iconic taxa
- **Place links**: Auto-detects regions/projects with custom URLs
- **Reliable**: Retry logic (3-5), admin alerts, daily logging
- **Rate-limit safe**: Optimized API calls (UUIDs first, details second)

## 📸 Example Post

```
📸 [Photos album]
📅 2025-11-15
📍 Moscow, Russia
👤 Ivan Ivanov
🐦 #Animalia -  #Aves -  #Pyrrhula_pyrrhula
🔗 Losiny Ostrov Project

↳ 🗺️ 55.7558°N, 37.6173°E [Map pin]
```

## 🚀 Quick Start

```
# 1. Install
bundle install

# 2. Configure (config.yaml)
cat > config.yaml << EOF
base_query: "project_id=12345&popular=true&quality_grade=research"
days_back: 30
chat_id: -1001234567890
retries: 5
places:
  - ids:[21]
    link: "https://inaturalist.org/projects/12345"
    text: "Moscow Region Project"
EOF

# 3. Set ENV
export TELEGRAM_BOT_TOKEN="your_bot_token"
export ADMIN_TELEGRAM_ID="your_admin_id"

# 4. Run
ruby inat_telegram_bot.rb

# 5. Cron (daily 9AM)
echo "0 9 * * * cd /path/to/bot && ruby inat_telegram_bot.rb >> log/cron.log 2>&1" | crontab -
```

## 🔧 Configuration

```
base_query: "taxon_id=47227&place_id=11&popular=true"  # Any iNat API params
days_back: 30                                          # Past N days
chat_id: -1001234567890                               # Channel/group ID
retries: 5                                            # API/Telegram retries
places:                                                # Auto-links
  - ids:                                    # place_ids from API[21]
    link: "https://inaturalist.org/projects/12345"
    text: "Regional Project"
```

## 📁 Files

```
├── inat_telegram_bot.rb     # Main script (~150 lines)
├── config.yaml             # Settings
├── sent.json              # Sent UUIDs + Telegram msg_id
├── backup.json            # Backup pool UUIDs
├── log/                   # Daily logs
└── Gemfile.lock           # Dependencies locked
```

## 🛠️ Dependencies

```
# Gemfile
gem 'httpclient'          # iNat API
gem 'telegram-bot-ruby'   # Telegram Bot API
gem 'retryable'           # Retry logic
gem 'yaml'                # Config
gem 'logger'              # Logging
gem 'json'                # Storage
```

## 🌍 API Examples

```
# Project
base_query: "project_id=12345&popular=true"

# Birds in Moscow
base_query: "taxon_name=Aves&place_id=11&popular=true"

# User's popular observations
base_query: "user_id=ivanov&popular=true&quality_grade=research"
```

## ❤️ Acknowledgments

- [iNaturalist API v2](https://www.inaturalist.org/pages/api+reference) [web:1]
- [Telegram Bot Ruby](https://github.com/telegram-bot-rb/telegram-bot) [web:79]
- iNat community for inspiration

**License**: [GPLv3](LICENSE)
