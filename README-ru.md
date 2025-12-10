
# inat-channel — автопостинг наблюдений


Скрипт, отправляющий в Telegram случайное наблюдение iNaturalist из некоторой выборки.

## Что делает?

+ Получает посредством [API iNaturalist](https://api.inaturalist.org/v2/docs/#/Observations/get_observations) выборку 
  по произвольному запросу (поддерживаемому API).

+ Отправляет случайное наблюдение из выборки в указанный telegram-канал, исключая уже отправленные. Если в свежей выборке 
  новых наблюдений нет, берет из сохраненного пула.

+ Неотправленные наблюдения, полученные по запросу, сохраняет в пул.

+ Уникальность таксонов и глубина пула — настраиваются.

+ При сбоях отправляет сообщение администратоу.

## Установка и запуск

### Посредством Bundler

Создаем `Gemfile` с единственной строкой:
```ruby
gem 'inat-channel', '~> 0.9.0'
```

Выполнить:
```shell
$ bundle install
```

И в дальнейшем пользоваться:
```shell
$ bundle exec inat-channel [options]
```

### Вручную

Устанавливаем:
```shell
gem install inat-channel
```

Запускаем:
```shell
inat-channel [options]
```

Параметров командной строки немного и все они необязательны:

```shell
$ inat-channel --help
Usage: inat-channel [options]
    -c, --config FILE                Config file (default: inat-channel.yml)
    -l, --log-level LEVEL            Log level (default: warn)
        --debug                      Set log level to debug
        --version                    Show version info and exit
    -h, --help                       Show help and exit
```

## Конфигурация

Основные настройки описываются в конфигурационном файле в формате YAML. Опционально можно задать ERB-шаблон сообщения и вынести
группу настроек `places` (см. далее) в отдельный YAML-файл.

Большая часть настроек имеет значения по умолчанию и может не указываться, но есть и обязательные.

### Переменные окружения

Кроме того, **два обязательных параметра** должны быть указаны **в переменных окружения**: `TELEGRAM_BOT_TOKEN` отвечает за токен телеграм-бота,
который вам выдается при его создании через [@BotFather](https://t.me/BotFather) — этого бота (вашего) нужно добавить в ваш канал администратором
и дать ему права на создание сообщений; в переменной `ADMIN_TELEGRAM_ID` следует указать ваш личный ID — по нему будут отправляться 
уведомления — этот ID можно узнать у бота [@Getmyid_bot](https://t.me/Getmyid_bot). Эти параметры не могут быть указаны в конфиг-файле
по соображениям безопасности.

### Конфигурационный файл

Пример:

```yaml

base_query:
  project_id: 175821
  locale: ru
  popular: true
  photo_license: 'cc-by,cc-by-nc,cc-by-nd,cc-by-sa,cc-by-nc-nd,cc-by-nc-sa,cc0'
  quality_grade: research
  
lock_file:
  path: data/data.lock
  ttl: 300
  
data_files:
  root: data
  pool: data/pool.json
  sent: data/sent.json
  used: data/used.json
  
days_back:
  fresh: 30
  pool: 180
  sent: 181
  used: 360
  
api:
  retries: 10
  interval: 1.0
  randomness: 0.5
  page_delay: 1.0
  per_page: 200
  
tg_bot:
  retries: 10
  interval: 1.0
  randomness: 0.5
  chat_id: '@sshh_test_channel'
  template: message.erb
  desc_limit: 512
  link_zoom: 12
  
unique_taxon: priority

log_level: info
notify_level: warn

places: places.yml
```

