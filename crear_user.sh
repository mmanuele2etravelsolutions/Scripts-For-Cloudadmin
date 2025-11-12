#!/bin/bash

read -p "Desea crear/borrar un usuario? " opcion

if [ "$opcion" = "borrar" ]; then
    cat /etc/passwd | grep '/home' | cut -d: -f1
    read -p "Introduzca usuario a borrar: " usuariob
    userdel -r "$usuariob"
    echo "Se borró el usuario seleccionado"
elif [ "$opcion" = "crear" ]; then
    read -p "Introduzca usuario: " usuario
    read -p "Introduzca password: " passw

    # Crea usuarios a partir de la variable "usuario"
    sudo useradd -d "/home/$usuario" -m -s /bin/bash "$usuario"

    # Asigna contraseña definida en la variable passw a usuario
    echo "$usuario:$passw" | chpasswd

    # Creación de la carpeta .ssh
    # Cambiar NAMES3 por nombre de S3
    read -p "El usuario tiene key ssh? si/no " condicion
    if [ "$condicion" = "no" ]; then
        echo "Creando key ssh"
        echo "Dando permisos"
        mkdir "/home/$usuario/.ssh"
        chmod 700 "/home/$usuario/.ssh"
        cd "/home/$usuario/.ssh" || exit
        echo "Generando ssh-key"
        ssh-keygen -t rsa -P "$passw" -f "/home/$usuario/.ssh/$usuario" -q && cat "/home/$usuario/.ssh/$usuario.pub" > "/home/$usuario/.ssh/authorized_keys"
        echo "Se terminó de crear la key, se procederá a copiarla."
        aws s3 cp "/home/$usuario/.ssh/$usuario" s3://NAMES3/
        aws s3 cp "/home/$usuario/.ssh/$usuario.pub" s3://NAMES3/
        usermod -a -G www-data "$usuario"
        chown -R "$usuario:$usuario" "/home/$usuario/.ssh/"
        echo "Usuario y key-ssh listos"
    elif [ "$condicion" = "si" ]; then
        echo "Se omite la creación, se procederá a copiar la key-ssh existente."
        aws s3 cp "s3://NAMES3/$usuario.pub" "/home/$usuario/.ssh/"
        cat "/home/$usuario/.ssh/"*.pub > "/home/$usuario/.ssh/authorized_keys"
        chown -R "$usuario:$usuario" "/home/$usuario/.ssh/"
        if [ -f "/home/$usuario/.ssh/*" ]; then
            chmod 600 "/home/$usuario/.ssh/*"
        fi
        usermod -a -G www-data "$usuario"
        echo "Se terminó de copiar la key-ssh existente."
    fi
fi
