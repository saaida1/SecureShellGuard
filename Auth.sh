#!/bin/bash

# Function to update the system
update_system() {
    read -p "Do you want to update the system? (y/n): " choice
    if [ "$choice" == "y" ]; then
        sudo apt update
        sudo apt upgrade
        echo "The system has been updated."
    else
        echo "The system has not been updated."
    fi
}


# Fonction pour sauvegarder le fichier de configuration original
backup_pam_config() {
    local pam_config_file="$1"
    cp "$pam_config_file" "$pam_config_file.bak"
}

# Fonction pour ajouter des règles PAM conformément aux recommandations de l'ANSSI
configure_pam_rules() {
    local pam_config_file="$1"
    cat <<EOL >> "$pam_config_file"
auth required pam_unix.so
auth required pam_tally2.so deny=3 unlock_time=600 onerr=fail audit even_deny_root_account silent
auth required pam_tally2.so onerr=succeed
EOL
}

# Fonction pour configurer le fichier de verrouillage de l'utilisateur
configure_pam_tally() {
    local pam_tally_config_file="$1"
    echo "deny = 3" > "$pam_tally_config_file"
    echo "no_lock_time" >> "$pam_tally_config_file"
}

# Fonction pour configurer le fichier limits.conf
configure_limits_conf() {
    local limits_conf_file="$1"
    echo "* hard core 0" >> "$limits_conf_file"
}

# Fonction pour configurer le fichier login.defs
configure_login_defs() {
    local login_defs_file="$1"
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' "$login_defs_file"
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' "$login_defs_file"
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' "$login_defs_file"
}

# Fonction pour configurer le module pam_unix
configure_pam_unix() {
    local pam_unix_file="$1"
    sed -i 's/^auth[[:space:]]*required[[:space:]]*pam_unix.so.*/auth required pam_unix.so/' "$pam_unix_file"
    sed -i 's/^password[[:space:]]*required[[:space:]]*pam_unix.so.*/password required pam_unix.so sha512/' "$pam_unix_file"
    sed -i 's/^session[[:space:]]*required[[:space:]]*pam_unix.so.*/session required pam_unix.so/' "$pam_unix_file"
}

# Fonction pour configurer le module pam_ldap
configure_pam_ldap() {
    local pam_ldap_file="$1"
    # Ajoutez ici vos configurations spécifiques pour pam_ldap
}

# Fonction principale pour effectuer la configuration complète
Authentification() {
    local pam_config_file="/etc/pam.d/common-auth"
    local pam_tally_config_file="/etc/security/pam_tally2.conf"
    local limits_conf_file="/etc/security/limits.conf"
    local login_defs_file="/etc/login.defs"
    local pam_unix_file="/etc/pam.d/common-account"
    local pam_ldap_file="/etc/pam.d/common-ldap"

    # Sauvegarde des fichiers de configuration originaux
    backup_pam_config "$pam_config_file"
    backup_pam_config "$pam_unix_file"
    backup_pam_config "$pam_ldap_file"

    # Configuration PAM
    configure_pam_rules "$pam_config_file"

    # Configuration du fichier de verrouillage de l'utilisateur
    configure_pam_tally "$pam_tally_config_file"

    # Configuration du fichier limits.conf
    configure_limits_conf "$limits_conf_file"

    # Configuration du fichier login.defs
    configure_login_defs "$login_defs_file"

    # Configuration du module pam_unix
    configure_pam_unix "$pam_unix_file"

    # Configuration du module pam_ldap
    configure_pam_ldap "$pam_ldap_file"

    # Informations complémentaires
    echo "Configuration PAM conformément aux recommandations de l'ANSSI effectuée."

    # Redémarrage du service PAM (Vous pouvez ajuster cela en fonction de votre système)
    service pam restart
}






# Main menu
echo "Linux Authentification Configuration"
echo "0. Update system"
echo "1. PAM modules configuration"
echo "2. Quit!"
read -p "Choose the number of the configuration: " choice
case $choice in
    0)
        echo "Update the system"
                update_system
        ;;
    1)
        echo "PAM modules configuration."
                Authentification
        ;;
    2)
        echo "Quit!"
        ;;
    *)
        echo "Invalid choice. Quit!"
        ;;
esac

