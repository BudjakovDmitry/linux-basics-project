# Подготовка инфраструктуры

Инфраструктура:

* Cервер с Nginx
* Сервер backend.01 (Gunicorn, Django app)
* Сервер backend.02 (Gunicorn, Django app)
* БД source (MySQL)
* БД replica (MySQL)
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


2. Создаем пользователя для репликации

```
sudo -i -u postgres
createuser --replication -P replication_user
```

3. Настройка PostgreSQL

Добавить в `/etc/postgresql/14/main/pg_hba.conf`:

```
# IPv4 remote connections
host    all             all             192.168.122.102/32      scram-sha-256
host    all             all             192.168.122.103/32      scram-sha-256
host    all             all             192.168.0.103/32        scram-sha-256
# Allow replication connections from remote hosts, by a user with the
# replication privileges.
host    replication_user  all           192.168.122.105/32      scram-sha-256
```

В файл `/etc/postgresql/14/main/postgresql.conf` внести изменения:

```
listen_addresses = '*'
wal_level = logical
```

Перезупусстить PostgreSQL

```
systemctl restart postgresql
```

Создаем базу данных

```
su -i -u postgres
psql
CREATE DATABASE polls;
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

## Настройка публикации и подписки

На стороне source сервера создать публикацию

```
CREATE PUBLICATION db_pub FOR ALL TABLES;
```

На стороне реплики создать подписку

```
CREATE SUBSCRIPTION db_sub CONNECTION 'host=192.168.122.104 dbname=polls' PUBLICATION db_pub;
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
