# shellcheck shell=bash disable=SC2164

bunConfigHook() {
    echo "Executing bunConfigHook"

    if [ -n "${bunRoot-}" ]; then
      pushd "$bunRoot"
    fi

    if [ -z "${bunDeps-}" ]; then
      echo "Error: 'bunDeps' must be set when using bunConfigHook."
      exit 1
    fi

    # `bunDeps` is an offline npm registry mirror served by prefetch-bun-deps.
    echo "Starting local bun registry server"
    local serverLog
    serverLog=$(mktemp)
    prefetch-bun-deps serve "$bunDeps" >"$serverLog" &
    local serverPid=$!

    local serverPort=""
    local attempts=0
    while [ -z "$serverPort" ] && [ "$attempts" -lt 100 ]; do
        serverPort=$(sed -n 's/^PORT=//p' "$serverLog")
        if [ -z "$serverPort" ]; then
            sleep 0.1
            attempts=$((attempts + 1))
        fi
    done
    if [ -z "$serverPort" ]; then
        echo "Error: local bun registry server did not start"
        cat "$serverLog"
        kill $serverPid 2>/dev/null
        exit 1
    fi

    local -a bunInstallFlags=()
    if [[ -n "${bunWorkspaces-}" ]]; then
        local ws
        for ws in $bunWorkspaces; do
            bunInstallFlags+=(--filter="$ws")
        done
    fi

    runHook preBunInstall

    echo "Installing dependencies"
    if bun install \
        --registry="http://127.0.0.1:$serverPort" \
        --ignore-scripts \
        "${bunInstallFlags[@]}" \
        --frozen-lockfile
    then
        echo "Patching scripts"
        patchShebangs node_modules/{*,.*}
    else
        kill $serverPid 2>/dev/null
        exit 1
    fi

    kill $serverPid 2>/dev/null

    if [ -n "${bunRoot-}" ]; then
      popd
    fi

    echo "Finished bunConfigHook"
}

postConfigureHooks+=(bunConfigHook)
