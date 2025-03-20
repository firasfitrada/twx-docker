#!/bin/bash
# twx.sh
# https://github.com/firasfitrada

set -o allexport
source .env
set +o allexport

create_thingworx_docker() {
    echo -e "\033[33;5m[----- Create ThingWorx Docker -----]\033[0m";
    if [ ! -d "${DB_PLATFORM}_${PROJECT_NAME}" ]; then
        cp -r staging/compose/${DB_PLATFORM} ${DB_PLATFORM}_${PROJECT_NAME};
        cp staging/entrypoint/${DB_PLATFORM}/docker-entrypoint.sh ${DB_PLATFORM}_${PROJECT_NAME};
    else
        echo -e "\033[32;5m[✔]\033[0m The \033[33;${DB_PLATFORM}_${PROJECT_NAME}\033[0m folder already exists.";
    fi
    deploy_thingworx;
}

check_thingworx_license(){
    if [[ "$PTC_AUTO_LICENSE" == "true" ]]; then
        sudo sed -i -E 's/^[ \t]*#([ \t]*- "[^"]*LS_USER[^"]*")/\1/' "${DB_PLATFORM}_${PROJECT_NAME}/docker-compose.yml"
        sudo sed -i -E 's/^[ \t]*#([ \t]*- "[^"]*LS_PASS[^"]*")/\1/' "${DB_PLATFORM}_${PROJECT_NAME}/docker-compose.yml"
        echo -e "\033[32;5m[✔]\033[0m ThingWorx license using Connected Mode"
    else
        echo -e "\033[32;5m[✔]\033[0m ThingWorx license using Disconnected Mode"
        if [ -f "${DB_PLATFORM}_${PROJECT_NAME}/license.bin" ]; then
            echo -e "\033[32;5m[✔]\033[0m The license.bin file was found."
            sudo sed -i 's/^[ \t]*#\([ \t]*- \..*license.bin.*\)/\1/' "${DB_PLATFORM}_${PROJECT_NAME}/docker-compose.yml"
        else
            echo -e "\033[32;5m[✔]\033[0m ThingWorx will be using a trial license."
        fi
    fi
}

deploy_thingworx(){
    USERNAME="twadmin"
    UID_NUMBER=1337
    GID_NUMBER=1337

    if ! getent group $GID_NUMBER >/dev/null; then
        sudo groupadd -g $GID_NUMBER $USERNAME
    fi

    if ! id "$USERNAME" >/dev/null 2>&1; then
        sudo useradd -u $UID_NUMBER -g $GID_NUMBER -M -N -r -s /bin/bash $USERNAME
        echo "User $USERNAME already created with UID: $UID_NUMBER and GID: $GID_NUMBER."
    else
        echo "User $USERNAME already exists."
    fi

    if [ -d "${DB_PLATFORM}_${PROJECT_NAME}/ThingWorxFoundation" ]; then
        echo -e "\033[32;5m[✔]\033[0m Skipping creation, \033[33;1mThingWorxFoundation\033[0m directory already exists.";
    else
        sudo mkdir -p ${DB_PLATFORM}_${PROJECT_NAME}/ThingWorxFoundation/ThingworxStorage;
        sudo mkdir -p ${DB_PLATFORM}_${PROJECT_NAME}/ThingWorxFoundation/ThingworxPlatform;
        sudo mkdir -p ${DB_PLATFORM}_${PROJECT_NAME}/ThingWorxFoundation/ThingworxBackupStorage;
        sudo mkdir -p ${DB_PLATFORM}_${PROJECT_NAME}/ThingWorxFoundation/tomcat;
        sudo chown -R ${UID_NUMBER}:${GID_NUMBER} ${DB_PLATFORM}_${PROJECT_NAME};
        echo -e "\033[32;5m[✔]\033[0m \033[33;1mThingWorxFoundation\033[0m directory has been sucessfully created.";
    fi

    check_thingworx_license;
    docker compose -f ${DB_PLATFORM}_${PROJECT_NAME}/docker-compose.yml up -d;
    echo -e "\033[32;5m[✔]\033[0m ThingWorx docker \033[32;1m$PROJECT_NAME\033[0m project has been created.";
}

recreate_thingworx_docker(){
    echo -e "\033[33;5m[----- Rereate ThingWorx Docker -----]\033[0m";
    check_thingworx_license;
    sudo sed -i 's/^[ \t]*#\([ \t]*- \..*docker-entrypoint.sh.*\)/\1/' "${DB_PLATFORM}_${PROJECT_NAME}/docker-compose.yml"
    docker compose -f ${DB_PLATFORM}_${PROJECT_NAME}/docker-compose.yml up -d;
}

status_thingworx_docker() {
    echo -e "\033[33;5m[----- ThingWorx Docker Status -----]\033[0m";
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "ID|$TWX_VERSION.*$PROJECT_NAME" | sed '';
}

delete_thingworx_docker() {
    echo -e "\033[33;5m[----- Delete ThingWorx Docker -----]\033[0m";
    echo -ne "\033[33;5m[?]\033[0m Are you sure you want to delete the ThingWorx \033[31;1m$PROJECT_NAME\033[0m container? (Y/N) : ";
    read confirm_delete
    if [ "$confirm_delete" == "y" ] || [ "$confirm_delete" == "Y" ]; then
        docker compose -f ${DB_PLATFORM}_${PROJECT_NAME}/docker-compose.yml down -v;

        if [ ! -d "archive" ]; then
            sudo mkdir archive;
        else
            echo -e "\033[32;5m[✔]\033[0m The \033[33;5marchive\033[0m folder has been created.";
        fi

        sudo mv ${DB_PLATFORM}_${PROJECT_NAME} archive/${DB_PLATFORM}_${PROJECT_NAME}_$(date +"%d%m%y%H%M");
        echo -e "\033[32;5m[✔]\033[0m ThingWorx \033[31;1m$PROJECT_NAME\033[0m has been deleted.";
    else
        echo -e "\033[31;5m[✘]\033[0m Aborted.";
        exit
    fi
}

delete_archive_thingworx_docker() {
    echo -e "\033[33;5m[----- Delete ThingWorx Archive -----]\033[0m";
    echo -ne "\033[33;5m[?]\033[0m Are you sure you want to delete the \033[31;1marchive\033[0m folder? (Y/N) : ";
    read confirm_delete
    if [ "$confirm_delete" == "y" ] || [ "$confirm_delete" == "Y" ]; then
        sudo rm -r archive;
    else
        echo -e "\033[31;5m[✘]\033[0m Aborted.";
        exit
    fi
}

stop_thingworx_docker() {
    echo -e "\033[33;5m[----- Stop ThingWorx Docker -----]\033[0m";
    docker stop ${PROJECT_NAME}_platform ${PROJECT_NAME}_db ${PROJECT_NAME}_init;
    echo -e "\033[32;5m[✔]\033[0m ThingWorx \033[31;1m$PROJECT_NAME\033[0m has been stopped.";
    status_thingworx_docker;
}

start_thingworx_docker() {
    echo -e "\033[33;5m[----- Start ThingWorx Docker -----]\033[0m";
    docker start ${PROJECT_NAME}_platform ${PROJECT_NAME}_db ${PROJECT_NAME}_init;
    echo -e "\033[32;5m[✔]\033[0m ThingWorx \033[32;1m$PROJECT_NAME\033[0m has been started.";
    status_thingworx_docker;
}

if [ "$1" == "create" ]; then create_thingworx_docker;
elif [ "$1" == "status" ]; then status_thingworx_docker;
elif [ "$1" == "delete" ]; then delete_thingworx_docker;
elif [ "$1" == "delete-archive" ]; then delete_archive_thingworx_docker;
elif [ "$1" == "recreate" ]; then recreate_thingworx_docker;
elif [ "$1" == "stop" ]; then stop_thingworx_docker;
elif [ "$1" == "start" ]; then start_thingworx_docker;
elif [ "$1" == "restart" ]; then stop_thingworx_docker; start_thingworx_docker;
else
    echo -e "\033[31;5m[✘]\033[0m Invalid Command /twx.sh \033[31;1m$1\033[0m"; \
    echo "[----- Command Options -----]";
    echo -e "\033[32;1m./twx.sh \033[35;1m create \033[0m";
    echo -e "\033[32;1m./twx.sh \033[35;1m status \033[0m";
    echo -e "\033[32;1m./twx.sh \033[35;1m delete \033[0m";
    echo -e "\033[32;1m./twx.sh \033[35;1m delete-archive \033[0m";
    echo -e "\033[32;1m./twx.sh \033[35;1m recreate \033[0m";
    echo -e "\033[32;1m./twx.sh \033[35;1m start \033[0m";
    echo -e "\033[32;1m./twx.sh \033[35;1m stop \033[0m";
    echo -e "\033[32;1m./twx.sh \033[35;1m restart \033[0m";
fi