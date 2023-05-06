#!/bin/bash

# Get file locations for user and admin lists
read -p "Enter file location for user list: " USER_FILE
read -p "Enter file location for admin list: " ADMIN_FILE

# Declare arrays for users and admins
declare -a USERS
declare -a ADMINS

# Read user and admin lists into arrays
mapfile -t USERS < "$USER_FILE"
mapfile -t ADMINS < "$ADMIN_FILE"

# Set password for new users
NEW_USER_PASSWORD="password"

# Remove leading/trailing whitespace from users and admins arrays
USERS=("${USERS[@]/#/}")
USERS=("${USERS[@]/%/}")
ADMINS=("${ADMINS[@]/#/}")
ADMINS=("${ADMINS[@]/%/}")

# Remove duplicate entries from users and admins arrays
USERS=($(echo "${USERS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
ADMINS=($(echo "${ADMINS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

# Get current list of users and remove leading/trailing whitespace
CURRENT_USERS=($(awk -F: '$3 >= 1000 && $3 <= 60000 {print $1}' /etc/passwd))
CURRENT_USERS=("${CURRENT_USERS[@]/#/}")
CURRENT_USERS=("${CURRENT_USERS[@]/%/}")

# Filter out users who are admins
NON_ADMIN_USERS=()
for user in "${CURRENT_USERS[@]}"; do
    if [[ ! " ${ADMINS[@]} " =~ " $user " ]]; then
        NON_ADMIN_USERS+=("$user")
    fi
done

# Identify users to be added
TO_BE_ADDED=()
for user in "${USERS[@]}"; do
    if [[ ! " ${CURRENT_USERS[@]} " =~ " $user " ]]; then
        TO_BE_ADDED+=("$user")
    fi
done

# Identify users to be deleted
TO_BE_DELETED=()
for user in "${NON_ADMIN_USERS[@]}"; do
    if [[ ! " ${USERS[@]} " =~ " $user " ]]; then
        TO_BE_DELETED+=("$user")
    fi
done

# Identify users to be made admins
TO_BE_ADMIN=()
for user in "${USERS[@]}"; do
    if [[ " ${ADMINS[@]} " =~ " $user " ]]; then
        TO_BE_ADMIN+=("$user")
    fi
done

# Identify users to be demoted from admin
TO_BE_NON_ADMIN=()
for user in "${ADMINS[@]}"; do
    if [[ ! " ${USERS[@]} " =~ " $user " ]]; then
        TO_BE_NON_ADMIN+=("$user")
    fi
done

# Display summary of changes
echo "Current users: ${CURRENT_USERS[@]}"
echo "Users to be added: ${TO_BE_ADDED[@]}"
echo "Users to be deleted: ${TO_BE_DELETED[@]}"
echo "Users to be made admins: ${TO_BE_ADMIN[@]}"
echo "Users to be demoted from admin: ${TO_BE_NON_ADMIN[@]}"

# Ask for confirmation before proceeding
read -p "Do you want to proceed with these changes? (y/n) " CONFIRMATION

if [[ $CONFIRMATION == "y" ]]; then
    # Add new users
    for user in "${TO_BE_ADDED[@]}"; do
        useradd "$user" -p "$(openssl passwd -1 "$NEW_USER_PASSWORD")"
    done
    
    # Delete users
    for user in "${TO_BE_DELETED[@]}"; do
        userdel
