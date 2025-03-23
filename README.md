# Подготовка инфраструктуры

Инфраструктура:

Service              | ip
---------------------|----------------
nginx                | 192.168.122.101
backend.01           | 192.168.122.102
backend.02           | 192.168.122.103
database.source      | 192.168.122.104
database.replica     | 192.168.122.105
Monitoring & Logging | 192.168.122.106
Backup               | 192.168.122.110

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

1. Установка Postgresql

```
apt install -y postgresql postgresql-contrib
```

2. Настройка Postgresql

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

Запустить Postgresql

```
systemctl start postgresql
```

## Backends

1. Устанавливаем Docker

```shell
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
# apt-cache policy docker-ce
apt install -y docker-ce
```

2. Скачиваем образ приложения и запускаем

```shell
docker pull dmitrybudyakov/otus-linux-basic:latest
docker run -p 8000:8000 -d dmitrybudyakov/otus-linux-basic
```

## Nginx

Установка Nginx

```shell
sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | tee /etc/apt/preferences.d/99nginx

apt update
apt install -y nginx
```

Запуск Nginx

```shell
systemctl start nginx
```

Установка Prometheus node exporter

```shell
apt install -y prometheus-node-exporter
```

## Prometheus & Grafana

### Prometheus

```shell
apt install -y prometheus
```

После обновления конфигурации перезапустить сервер Prometheus

```
systemctl restart prometheus
```

### Grafana

```shell
apt install -y musl
dpkg -i grafana-enterprise_11.4.0_amd64.deb
```

# Что бэкапить

### Database

```
/etc/postgresql/14/main/pg_hba.conf
/etc/postgresql/14/main/postgresql.conf
```

### Nginx

```
/etc/nginx/conf.d/default.conf
```

### Monitoring

```
/etc/prometheus/prometheus.yml
```

## Инструкция по проведению аварийного восстановления

### Nginx

Зайти на сервер Gateway

```
ssh user@192.168.122.101
```

Скачать скрипт восстановления

```
git clone https://github.com/BudjakovDmitry/linux-basics-project.git restore
cd restore/
```

Добавить права на выполнение и запустить скрипт восстановления

```
sudo su
chmod u+x gateway.sh
./gateway.sh
```

### Backend

Зайти на сервер бэкенда

```
ssh user@192.168.122.102
```

Скачать скрипт восстановления

```
git clone https://github.com/BudjakovDmitry/linux-basics-project.git restore
cd restore/
```

Добавить права на выполнение и запустить скрипт восстановления

```
sudo su
chmod u+x backend.sh
./gateway.sh
```

Повторить для каждого инстанса бэкенда.
