# iNat Telegram Poster (DRAFT!)

[![Ruby](https://img.shields.io/badge/Ruby-3.4%2B-red.svg)](https://www.ruby-lang.org/)
[![Telegram Bot](https://img.shields.io/badge/Telegram-Bot-blue.svg)](https://core.telegram.org/bots)
[![iNaturalist API v2](https://img.shields.io/badge/iNaturalist-APIv2-green.svg)](https://www.inaturalist.org/pages/api+reference)

**Automated daily poster** that shares random **popular iNaturalist observations** to Telegram channels.

## ✨ Features

- **Flexible queries**: `base_query` for projects, taxa, places, users, etc.
- **Smart posting**: Fresh → pool → sent archive (no duplicates!)
- **Rich media**: Up to 10 photos + geolocation pins
- **Taxon hierarchy**: Emojis + ancestor hashtags
- **Regional links**: Auto-detect places/projects
- **Safe concurrency**: Lock-file protection
- **Reliable**: Retries, admin alerts, logging

## 🚀 Quick Start

```
# 1. Install
bundle install

# 2. Configure (config.yaml)
cat > config.yaml << EOF
base_query: 
  project_id: 12345
  popular: true
  quality_grade: research
  locale: ru
days_back: 30
chat_id: -1001234567890
retries: 5
EOF

# 3. Set ENV
export TELEGRAM_BOT_TOKEN="your_bot_token"
export ADMIN_TELEGRAM_ID="your_admin_id"

# 4. Run
bin/inat-channel -c config.yaml

# 5. Cron (daily 9AM)
echo "0 9 * * * cd /path/to/bot && bin/inat-channel -c config.yaml >> log/cron.log 2>&1" | crontab -
```

## 🔧 Configuration

```
base_query:          # iNat API params (Hash)
  project_id: 12345
  popular: true
  quality_grade: research
  locale: ru
days_back: 30        # Past N days (Integer, >0)
chat_id: -1001234567890  # Telegram channel/group
retries: 5           # API/Telegram retries

# Optional data paths (отдельные папки для разных конфигов!)
pool_file: "data/pool.json"
sent_file: "data/sent.json"  
lock_file: "data/bot.lock"   # Авто: dirname(pool_file)/bot.lock

places:               # Auto-links by place_ids
  group:
    - place_ids:[1][2]
      link: "https://inaturalist.org/projects/12345"
      text: "Moscow Region Project"
```

## 🔒 Multiple Configurations (параллельный запуск)

**Разные конфиги → работают параллельно!**

```
config/
├── moscow.yaml      # data/moscow_pool.json + moscow.lock
└── spb.yaml         # data/spb_pool.json + spb.lock

# Запуск 1
bin/inat-channel -c config/moscow.yaml

# Запуск 2 (ПАРАЛЛЕЛЬНО!)
bin/inat-channel -c config/spb.yaml
```

**⚠️ ВАЖНО**: `pool_file`/`sent_file` должны быть **разными** между конфигами!

```
❌ Плохо (race condition!):
moscow.yaml: pool_file: "data/pool.json"
spb.yaml:    pool_file: "data/pool.json"

✅ Хорошо:
moscow.yaml: pool_file: "data/moscow_pool.json"
spb.yaml:    pool_file: "data/spb_pool.json"
```

## 📁 File Structure

```
├── config.yaml          # Settings
├── data/
│   ├── pool.json        # Backup UUIDs
│   ├── sent.json        # Sent UUIDs + msg_id
│   └── bot.lock         # Active process lock
├── log/                 # Daily logs (auto)
└── bin/inat-channel     # Main executable
```

## 🛡️ Concurrency Protection

- **Lock-файл** с TTL 30мин (автоочистка stale locks)
- **Graceful shutdown** (SIGINT/SIGTERM)
- **PID + timestamp** в lock-файле
- **Ошибка при дублирующемся запуске** на одном конфиге

```
$ bin/inat-channel -c config.yaml    # PID 12345 захватил lock
$ bin/inat-channel -c config.yaml    # Error: Another instance is already running (PID: 12345)
```

## 📊 Example Post

```
🪶 <b>Обыкновенный снегирь</b> <i>(Pyrrhula pyrrhula)</i>
📷 #123456 — 👤 <a href="...">Ivan Ivanov</a> @ 📅 2025-11-15
🗺️ <a href="...">Moscow Region Project</a>

↳ 🗺️ 55.7558°N, 37.6173°E [Location pin]
#Animalia -  #Aves -  #Pyrrhula_pyrrhula
```

## 🛠️ CLI Options

```
bin/inat-channel --help
# -c, --config FILE     Config file (default: inat-channel.yaml)
# -l, --log-level LEVEL Log level (debug/info/warn/error)
# --debug               Set log level to debug
```

## ❤️ Acknowledgments

- [iNaturalist API v2](https://www.inaturalist.org/pages/api+reference)
- [Telegram Bot Ruby](https://github.com/telegram-bot-rb/telegram-bot)
- [Faraday HTTP](https://github.com/lostisland/faraday)

**License**: [GPLv3](LICENSE)
