# Teleport Service로 관리하기

## 그냥 실행
```sh
    ## 실행
    ./teleport start --config="/etc/teleport.yaml"

    ## 백그라운드 실행
    ./teleport start --config="/etc/teleport.yaml" &
```

## Script 구성

```sh
    ## /usr/local/bin/teleport.sh

    #!/bin/sh
    /usr/local/bin/teleport start --config="/etc/teleport.yaml"
```

## Service로 구동

```sh

    ## systemc
    cd /etc/systemd/system

    ## teleport-https.service

    [Unit]
    Description=Teleport HTTPS Service

    [Service]
    ExecStart=/bin/sh /usr/local/bin/teleport.sh

    [Install]
    WantedBy=multi-user.target    
```

## Service 등록 / 실행

```sh
    ## sudo systemctl daemon-reload
    sudo systemctl enable teleport-https
    sudo systemctl start teleport-https
    sudo systemctl status teleport-https
```