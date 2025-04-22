# shellcheck disable=SC2148,SC1091

source /includes/colors.sh
source /includes/rcon.sh
source /includes/webhook.sh

function start_server() {
    cd "$GAME_ROOT" || exit
    setup_configs
    ei ">>> Preparing to start the gameserver"
    START_OPTIONS=()
    if [[ -n $COMMUNITY_SERVER ]] && [[ $COMMUNITY_SERVER == "true" ]]; then
        e "> Setting Community-Mode to enabled"
        START_OPTIONS+=("-publiclobby")
    fi
    if [[ -n $MULTITHREAD_ENABLED ]] && [[ $MULTITHREAD_ENABLED == "true" ]]; then
        e "> Setting Multi-Core-Enhancements to enabled"
        START_OPTIONS+=("-useperfthreads" "-NoAsyncLoadingThread" "-UseMultithreadForDS")
    fi
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_start_notification
    fi
    es ">>> Starting the gameserver"

    # Check if we are using UE4SS and preload libUE4SS.so else start normal
#     if [[ "$UE4SS_ENABLED" == "true" ]]; then
#     	ew ">> MODED STARTUP (MODDED)"
#     	LD_PRELOAD=./Pal/Binaries/Linux/libUE4SS.so ./PalServer.sh "${START_OPTIONS[@]}"
#     else
#     	ew ">> NORMAL STARTUP (NON MODDED)"
#     	./PalServer.sh "${START_OPTIONS[@]}"
#     fi
	es "Moded startup. Bypass PalServer.sh as we cant send custom preloads"

	export LD_PRELOAD="$(realpath ./Pal/Binaries/Linux/libUE4SS.so)"
	chmod +x ./Pal/Binaries/Linux/PalServer-Linux-Shipping
	./Pal/Binaries/Linux/PalServer-Linux-Shipping Pal "${START_OPTIONS[@]}"
}

function stop_server() {
    ew ">>> Stopping server..."
    kill -SIGTERM "${PLAYER_DETECTION_PID}"
    if [[ -n $RCON_ENABLED ]] && [[ $RCON_ENABLED == "true" ]]; then
        save_and_shutdown_server
    fi
	kill -SIGTERM "$(pidof PalServer-Linux-Shipping)"
	tail --pid="$(pidof PalServer-Linux-Shipping)" -f 2>/dev/null
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_stop_notification
    fi
    ew ">>> Server stopped gracefully"
    exit 143;
}

function fresh_install_server() {
    ei ">>> Doing a fresh install of the gameserver..."
    if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
        send_install_notification
    fi
    "${STEAMCMD_PATH}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
    es "> Done installing the gameserver"
}

function update_server() {
    # Workaround fix for 0x6 error
    ei ">>> Applying workaround fix for 'Error! App '2394010' state is 0x6 after update job.' message, since update 0.3.X..."
    rm -f /palworld/steamapps/appmanifest_2394010.acf
    if [[ -n $STEAMCMD_VALIDATE_FILES ]] && [[ $STEAMCMD_VALIDATE_FILES == "true" ]]; then
        ei ">>> Doing an update with validation of the gameserver files..."
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_update_notification
        fi
        "${STEAMCMD_PATH}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 validate +quit
        es ">>> Done updating and validating the gameserver files"
    else
        ei ">>> Doing an update of the gameserver files..."
        if [[ -n $WEBHOOK_ENABLED ]] && [[ $WEBHOOK_ENABLED == "true" ]]; then
            send_update_notification
        fi
        "${STEAMCMD_PATH}"/steamcmd.sh +force_install_dir "$GAME_ROOT" +login anonymous +app_update 2394010 +quit
        es ">>> Done updating the gameserver files"
    fi
}
