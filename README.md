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

## Подготовка сервера БД (Source)

1. Установка PostgreSQL

```
apt install -y postgresql postgresql-contrib
```

2. Создаем базу

```
sudo -i -u postgres
createdb todos
```

3. Задать пароль для postgres

```
sudo -i -u postgres
psql
ALTER USER postgres WITH password 'postgres';
```


3. Настройка PostgreSQL

В файл `/etc/postgresql/14/main/postgresql.conf` внести изменения:

```
listen_addresses = '*'
wal_level = logical
```

Добавить в `/etc/postgresql/14/main/pg_hba.conf`:

```
# IPv4 remote connections
host    all             all             192.168.122.102/32      scram-sha-256
host    all             all             192.168.122.103/32      scram-sha-256
host    all             all             192.168.0.103/32        scram-sha-256
# Allow replication connections from remote hosts, by a user with the
# replication privileges.
host    todos           postgres        192.168.122.105/32      trust
```

Перезупусстить PostgreSQL

```
systemctl restart postgresql
```

На стороне source сервера создать публикацию

```
sudo -i -u postgres
psql
CREATE PUBLICATION db_pub FOR ALL TABLES;
```

## Настройка сервера БД (replica)

1. Установка PostgreSQL

```
apt install -y postgresql postgresql-contrib
```

2. Настройка PostgreSQL

В файле `/etc/postgresql/14/main/postgresql.conf` указать:

```
listen_addresses = '*'
```

Перезупусстить PostgreSQL

```
systemctl restart postgresql
```

На стороне реплики создать подписку

```
sudo -i -u postgres
psql
CREATE SUBSCRIPTION db_sub CONNECTION 'host=192.168.122.104 dbname=todos' PUBLICATION db_pub;
```

Сделать дамп базы с мастера

```
sudo -i -u postgres
pg_dump --dbname todos --host 192.168.122.104 --no-password --create --schema-only | psql
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
