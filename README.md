# Kea DHCP4


## Instalacion : 

```bash
apt update
apt upgrade -y
apt install kea-dhcp4-server -y
```


## Configuracion de red : /etc/network/interfaces 


```bash
# The loopback network interface
auto lo
iface lo inet loopback

# Interfaz para accesso al internet
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4

# Servidor DHCP
auto enp0s8
iface enp0s8 inet static
    address 172.26.0.1
    netmask 255.255.0.0
```

- Applicamos los cambios : 

```bash
systemctl restart networking
```

## Configuramos el fichero de configuracion Kea-DHCP4


- Guardamos una copia de seguridad al fichero de configuracion 

```bash
cp /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.backup
echo ' ' > /etc/kea/kea-dhcp4.conf
```

- Configuracion : 

```bash
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [ "enp0s8" ]
    },
    "lease-database": {
      "type": "memfile",
      "lfc-interval": 3600
    },
    "expired-leases-processing": {
      "reclaim-timer-wait-time": 10,
      "flush-reclaimed-timer-wait-time": 25,
      "hold-reclaimed-time": 3600,
      "max-reclaim-leases": 100,
      "max-reclaim-time": 250,
      "unwarned-reclaim-cycles": 5
    },
    "renew-timer": 900,
    "rebind-timer": 1800,
    "valid-lifetime": 3600,
    "subnet4": [
      {
        "subnet": "172.26.0.0/16",
        "pools": [ { "pool": "172.26.0.10 - 172.26.0.200" } ],
        "option-data": [
          {
            "name": "routers",
            "data": "172.26.0.1"
          },
          {
            "name": "domain-name-servers",
            "data": "8.8.8.8, 8.8.4.4"
          }
        ]
      }
    ],
    "loggers": [
      {
        "name": "kea-dhcp4",
        "output_options": [
          {
            "output": "/var/log/kea-dhcp4.log"
          }
        ],
        "severity": "INFO",
        "debuglevel": 0
      }
    ]
  }
}
```

- Creamos el fichero de logs : 

```bash
touch /var/log/kea-dhcp4.log
chown _kea:_kea /var/log/kea-dhcp4.log
```

- Habilitamos el IP Forwading para hacer un routing entre las interfaces : 

```bash
echo "net.ipv4.ip_forward=1" | tee -a /etc/sysctl.conf
```



- Aplicamos los cambios : 

```bash
systemctl enable kea-dhcp4-server
systemctl restart kea-dhcp4-server
systemctl status kea-dhcp4-server
```


## En El Cliente 

```bash
dhclient -r
dhclient -v
```

*** 

# Script de Automatizacion

- Este script instala y configura Kea DHCP4 en Debian/Ubuntu. Verifica la instalación, configura la red, genera un archivo de configuración DHCP con la subred y rango ingresados, habilita el reenvío IP y reinicia el servicio para aplicar los cambios. Para usar este script, revisa este enlace de GitHub. 
















