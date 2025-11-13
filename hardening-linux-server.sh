#!/bin/bash
# =====================================================================
#  Hardening Linux For All - Script automático de endurecimiento Linux
#  Autor: MManuel 
#  Basado en la Checklist Hardening del PDF de Cristopher Mejía
# =====================================================================

# ------------------------- COLORES -------------------------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# ------------------------- VALIDACIÓN -------------------------
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Debes ejecutar este script como root.${RESET}"
    exit 1
fi

echo -e "${BLUE}
===========================================
   HARDENING LINUX SERVER - AUTOMÁTICO
===========================================
${RESET}"

sleep 1

# ------------------------- STEP 1: UPDATE -------------------------
echo -e "${YELLOW}[1] Actualizando el sistema...${RESET}"
apt update && apt upgrade -y
echo -e "${GREEN}✓ Sistema actualizado${RESET}"
sleep 1


# ------------------------- STEP 2: FIREWALL (UFW) -------------------------
echo -e "${YELLOW}[2] Configurando firewall UFW...${RESET}"

ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow ssh

echo -e "${YELLOW}Habilitar UFW ahora? (S/N)${RESET}"
read -r RESP

if [[ "$RESP" =~ ^[Ss]$ ]]; then
    ufw enable
else
    echo -e "${RED}⚠ Recuerda habilitar UFW manualmente luego.${RESET}"
fi

ufw status
echo -e "${GREEN}✓ Firewall configurado${RESET}"
sleep 1


# ------------------------- STEP 3: DISABLE ROOT LOGIN -------------------------
echo -e "${YELLOW}[3] Deshabilitando login SSH del usuario root${RESET}"

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

echo -e "${GREEN}✓ Root login deshabilitado${RESET}"
sleep 1


# ------------------------- STEP 4: SSH KEYS + DISABLE PASSWORD -------------------------

echo -e "${YELLOW}[4] Autenticación SSH mediante llaves${RESET}"
echo -e "${BLUE}¿Quieres generar una clave SSH nueva? (S/N)${RESET}"
read -r GENKEY

if [[ "$GENKEY" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Escribe tu email para la clave:${RESET}"
    read -r EMAIL
    ssh-keygen -t ed25519 -C "$EMAIL"
fi

echo -e "${YELLOW}¿Quieres copiar la clave a otro servidor? (S/N)${RESET}"
read -r COPYKEY

if [[ "$COPYKEY" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Ingresa usuario@IP del servidor destino:${RESET}"
    read -r DEST
    ssh-copy-id "$DEST"
fi

# Deshabilitar password y challenge
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

echo -e "${GREEN}✓ Autenticación por contraseña deshabilitada${RESET}"
systemctl restart ssh
sleep 1


# ------------------------- STEP 5: FAIL2BAN -------------------------

echo -e "${YELLOW}[5] Instalando y configurando Fail2Ban...${RESET}"

apt install fail2ban -y

tee /etc/fail2ban/jail.local >/dev/null <<'EOF'
[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 1h
findtime = 10m
EOF

systemctl enable --now fail2ban

echo -e "${GREEN}✓ Fail2Ban activo${RESET}"
fail2ban-client status sshd
sleep 1


# ------------------------- STEP 6: REMOVE UNNECESSARY SERVICES -------------------------

echo -e "${YELLOW}[6] Servicios innecesarios${RESET}"

systemctl list-units --type=service --state=running

echo -e "${YELLOW}¿Deseas desactivar algún servicio? (S/N)${RESET}"
read -r DS

if [[ "$DS" =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}Ingresa nombre del servicio a desactivar:${RESET}"
    read -r SRV
    systemctl disable --now "$SRV"
    echo -e "${GREEN}✓ Servicio desactivado${RESET}"
fi


# ------------------------- STEP 7: AUDIT PERMISSIONS -------------------------

echo -e "${YELLOW}[7] Buscando archivos con permisos peligrosos...${RESET}"

find / -type f -perm -o+w 2>/dev/null | head
find / -type d -perm -o+w 2>/dev/null | head

sleep 1


# ------------------------- STEP 8: AUDIT PORTS & PROCESSES -------------------------

echo -e "${YELLOW}[8] Puertos abiertos y procesos activos${RESET}"

ss -tulpn
ps aux --sort=-%cpu | head

sleep 1


# ------------------------- STEP 9: LOGGING & MONITORING -------------------------

echo -e "${YELLOW}[9] Logs relevantes del sistema${RESET}"

journalctl -u ssh --since "today"
tail -f /var/log/auth.log & sleep 3; kill $!

sleep 1


# ------------------------- STEP 10: BACKUP -------------------------

echo -e "${YELLOW}[10] Creando backup automático de /etc${RESET}"

mkdir -p /backups
tar -czf /backups/etc-$(date +%F).tar.gz /etc

echo -e "${GREEN}✓ Backup generado en /backups/${RESET}"

echo -e "${YELLOW}¿Quieres configurar un cron diario de backup? (S/N)${RESET}"
read -r CRON

if [[ "$CRON" =~ ^[Ss]$ ]]; then
    (crontab -l 2>/dev/null; echo "0 2 * * * tar -czf /backups/etc-\$(date +\%F).tar.gz /etc") | crontab -
    echo -e "${GREEN}✓ Cron configurado${RESET}"
fi

# ------------------------- END -------------------------

echo -e "${BLUE}
===========================================
 HARDENING COMPLETO - SERVIDOR SEGURO
===========================================
${RESET}"
