apt install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

apt install -y docker-ce

apt install -y prometheus-node-exporter

docker pull dmitrybudyakov/otus-linux-basic:latest

docker run -p 8000:8000 -d dmitrybudyakov/otus-linux-basic
