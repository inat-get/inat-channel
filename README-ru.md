
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


```shell
$ inat-channel --help
Usage: inat-channel [options]
    -c, --config FILE                Config file (default: inat-channel.yml)
    -l, --log-level LEVEL            Log level (default: warn)
        --debug                      Set log level to debug
        --version                    Show version info and exit
    -h, --help                       Show help and exit
```