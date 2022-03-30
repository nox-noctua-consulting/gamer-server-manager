#!/bin/bash

peon_check_orc(){
    # Checks of the orc container has been authorised to communicate to docker host
    if [[ $(docker ps | grep 'peon.orc') ]]; then
        hostname=$(docker container inspect -f '{{.Config.Hostname}}' peon.orc)
        if [[ $(grep $hostname ~/.ssh/authorized_keys) ]]; then
            echo " [${BLUE}authorised${STD}]"
        else
            echo " [${ORANGE}not authorised${STD}] * Please re-authorise the container."
        fi
    fi
}

peon_check_health() {
    # ToDo - Centre align
    for container in $(docker ps -a --format "{{.Names}}" | grep -i 'peon' | grep -v 'warcamp'); do
        orc_state=""
        container_state=$(docker container inspect -f '{{.State.Status}}' $container)
        case $container_state in
        "created") STATE=$BLUE ;;
        "running") STATE=$GREEN ;;
        "paused") STATE=$ORANGE ;;
        "restarting") STATE=$ORANGE ;;
        "dead") STATE=$RED_HL ;;
        "exited") STATE=$RED ;;
        *) STATE=$ORANGE ;;
        esac
        if [[ "$container" == "peon.orc" ]]; then
            orc_state="$(peon_check_orc)"
        fi
        printf " $container [${STATE}$container_state${STD}]$orc_state\n"
    done
    printf "\n"
}

peon_connect_container() {
    draw_menu_header $menu_size "$app_name" "P E O N   C O N N E C T"
    PS3="Please select a container to enter: "
    container_list=$(docker ps --format "{{.Names}}" | grep -i 'peon' | grep -v 'warcamp')
    container_count=`echo $container_list | wc -w`
    select container in $container_list; do
        case $REPLY in
        [1-$container_count])
            echo -e "Connecting to peon infrastructure container ${BLUE}$container${STD}"
            docker exec -it $container bash
            break
            ;;
        0) break ;;
        *) printf "\n ${RED_HL}*Invalid Option*${STD}\n" && sleep 0.75 ;;
        esac
    done
}

peon_start_containers() {
    draw_menu_header $menu_size "$app_name" "P E O N   S T A R T"
    echo -e "[${GREEN}Starting${STD}] peon infrastructure containers"
    docker-compose up -d
}

peon_restart_containers() {
    draw_menu_header $menu_size "$app_name" "P E O N   R E S T A R T"
    echo -e "[${RED}Stopping${STD}] peon infrastructure containers"
    docker-compose stop
    echo -e "[${GREEN}Starting${STD}] peon infrastructure containers"
    docker-compose up -d
}

peon_stop_containers() {
    draw_menu_header $menu_size "$app_name" "P E O N   S T O P"
    echo -e "[${RED}Stopping${STD}] peon infrastructure containers"
    docker-compose stop
}

peon_update_containers() {
    draw_menu_header $menu_size "$app_name" "P E O N   U P D A T E"
    echo -e "[${RED}Removing${STD}] existing infrastructure containers"
    docker-compose down
    echo -e "[${BLUE}Pulling${STD}] latest version of docker-compose."
    curl https://raw.githubusercontent.com/nox-noctua-consulting/peon/main/docker-compose.yml > docker-compose.yml
    echo -e "[${GREEN}Deploying${STD}] latest peon containers"
    docker-compose up -d 
    echo -e "[${BLUE}Authorizing${STD}] orchestrator for node control"
    ./configure_orc.sh
}

menu_peon() {
    local incomplete=true
    local choice
    while $incomplete; do
        draw_menu_header $menu_size "$app_name" "P E O N   C O N T A I N E R S"
        peon_check_health
        printf " 1. Connect to Container\n"
        printf " 2. Start Containers\n"
        printf " 3. Restart Containers\n"
        printf " 4. Stop Containers\n"
        printf " 5. Update Containers\n"
        printf " 6. Reauthorize Orchestrator\n"
        printf " 0. Main Menu\n\n"
        read -p "Enter selection: " choice
        case $choice in
        0) incomplete=false ;;
        1) peon_connect_container ;;
        2) peon_start_containers ;;
        3) peon_restart_containers ;;
        4) peon_stop_containers ;;
        5) peon_update_containers ;;
        6) ./configure_orc.sh ;;
        *) printf "\n ${RED_HL}*Invalid Option*${STD}\n" && sleep 0.75 ;;
        esac
        sleep 2
    done
}
