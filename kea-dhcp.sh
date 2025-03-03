#!/bin/bash
clear


# Instalacion de paquetes Necesarios 

if ! dpkg -l | grep -q kea-dhcp4-server; then
    apt update
    apt upgrade -y
    apt install -y kea-dhcp4-server 
fi
clear



# Configuracion de la red

interfaces=$(ip a |  grep "<" | cut -d: -f2)

echo "############ Configuracion de Red ##################"
echo "##### Interfaces :  #####"
echo "$interfaces"
read -p "Introduzca la interfaz de red a configurar: " interfaz
read -p "Introduzca la direccion IP: " ip
read -p "Introduzca la mascara de red: " mask
read -p "Introduzca la ip de red: " red


echo "# Interfaz red del servidor Kea-dhcp " >> /etc/network/interfaces
echo "auto $interfaz" >> /etc/network/interfaces
echo "iface $interfaz inet static" >> /etc/network/interfaces
echo "address $ip" >> /etc/network/interfaces
echo "netmask $mask" >> /etc/network/interfaces
echo "netowork $red" >> /etc/network/interfaces

systemctl restart networking



# Configuracion del servidor DHCP

echo "############ Configuracion del Servidor DHCP ##################"

cp /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.backup
echo ' ' > /etc/kea/kea-dhcp4.conf


read -p "Introduzca el subnet: (192.168.1.0/24) : " subnet
read -p "Introduza el rango de direcciones IP: (192.168.1.100 - 192.168.1.200) : " rango




cat > /etc/kea/kea-dhcp4.conf <<EOF
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [ "$interfaz" ]
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
        "subnet": "$subnet",
        "pools": [ { "pool": "$rango" } ],
        "option-data": [
          {
            "name": "routers",
            "data": "$red"
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
EOF



# Fichero Log
touch /var/log/kea-dhcp4.log
chown _kea:_kea /var/log/kea-dhcp4.log


# IP Forwading
echo "net.ipv4.ip_forward=1" | tee -a /etc/sysctl.conf


# Aplicamos los cambios 
systemctl enable kea-dhcp4-server
systemctl restart kea-dhcp4-server
systemctl status kea-dhcp4-server

