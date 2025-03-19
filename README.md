# Подготовка инфраструктуры

Инфраструктура:

* Сервер мониторинга (Prometeus, Grafana)
* Сервер логирования (Elastic search, Kibana)
* Сервер сбора бэкапа

Бэкап БД снимается со слейва.

Конфигурация сети:

Service          | ip
-----------------|----------------
nginx            | 192.168.122.101
backend.01       | 192.168.122.102
backend.02       | 192.168.122.103
database.source  | 192.168.122.104
database.replica | 192.168.155.105

## Подготовка сервера БД (Primary)

1. Установка PostgreSQL

```
apt install -y postgresql postgresql-contrib
```


2. Задать пароль для postgres

```
sudo -i -u postgres
psql
ALTER USER postgres WITH password 'postgres';
```

3. Настройка

В файле `/etc/postgresql/14/main/postgresql.conf` указываем параметры

```
listen_addresses = '*'
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1024MB
```

В файл `/etc/postgresql/14/main/pg_hba.conf` добавляем строчку

```
host replication replicator 192.168.122.105/24 md5
```

Перезапускаем Postgres

```
systemctl restart postgresql
```

4. Создаем пользователя для репликации

```
psql -U postgres -h localhost -c "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator';"
```

## Настройка сервера БД (Standby Node)

1. Установка PostgreSQL

```
apt install -y postgresql postgresql-contrib
```

2. Настройка PostgreSQL

Остановить Postgres

```
systemctl stop postgresql
```

Очищаем директорию с данными

```
rm -rf /var/lib/postgresql/14/main/*
```

Выгружаем в эту директорию бэкап из основного сервера

```
pg_basebackup -h 192.168.122.104 -U replicator -D /var/lib/postgresql/14/main -Fp -Xs -P
```

Создаем standby.signal

```
touch /var/lib/postgresql/14/main/standby.signal
```

Меняем владельца

```
chown postgres:postgres /var/lib/postgresql/14/main/* -R
```

В файле `/etc/postgresql/14/main/postgresql.conf` указать:

```
listen_addresses = '*'
primary_conninfo = 'host=192.168.122.104 port=5432 user=replicator password=replicator'
hot_standby = on
```

Запусстить PostgreSQL

```
systemctl start postgresql
```

## Backend 1

Для установки mysqlclient
sudo apt-get install python3-dev default-libmysqlclient-dev build-essential pkg-config

sudo apt install python3-pip
sudo python3 -m pip install Django

# Что бэкапить

### Database (Source)

/etc/postgresql/14/main/pg_hba.conf
/etc/postgresql/14/main/postgresql.conf
