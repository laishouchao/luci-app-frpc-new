#!/bin/sh
# /usr/lib/frpc/generate_toml.sh
# Generate /etc/frp/frpc.toml from UCI /etc/config/frpc
# POSIX sh compatible (no bashisms)
set -e

FRPC_CONFIG="/etc/config/frpc"
OUTPUT_FILE="/etc/frp/frpc.toml"

# ---- helpers ----

# Read a UCI option from the main section.
#   uci_get <option> [default]
uci_get() {
    local val
    val=$(uci -q get "$FRPC_CONFIG.main.$1" 2>/dev/null) || true
    [ -n "$val" ] && { echo "$val"; return; }
    [ -n "${2+x}" ] && echo "$2"
}

# Read a UCI option from the given section variable.
#   sec_get <section_id> <option> [default]
sec_get() {
    local val
    val=$(uci -q get "$FRPC_CONFIG.$1.$2" 2>/dev/null) || true
    [ -n "$val" ] && { echo "$val"; return; }
    [ -n "${3+x}" ] && echo "$3"
}

# Print a TOML key = "value" line (quoted).
emit() {
    printf '%s = "%s"\n' "$1" "$2"
}

# Print a TOML key = value line (unquoted).
emit_raw() {
    printf '%s = %s\n' "$1" "$2"
}

# Print a TOML key = integer line.
emit_int() {
    printf '%s = %d\n' "$1" "$2"
}

# Parse pipe-separated "Key:Value|Key2:Value2" into TOML inline table.
#   emit_map <section_prefix>  e.g. "[proxy.requestHeaders]"
# Each entry: Key:Value  (colon separates key from value)
emit_map() {
    local section_name="$1"
    local raw="$2"
    [ -z "$raw" ] && return 1

    printf '%s\n' "$section_name"
    echo "$raw" | tr '|' '\n' | while IFS= read -r entry; do
        entry=$(echo "$entry" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$entry" ] && continue
        local key="${entry%%:*}"
        local val="${entry#*:}"
        key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        val=$(echo "$val" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -n "$key" ] && printf '%s = "%s"\n' "$key" "$val"
    done
    return 0
}

# Parse pipe-separated list into TOML array: ["item1", "item2"]
#   emit_array <key> <pipe_separated_string>
emit_array() {
    local key="$1"
    local raw="$2"
    [ -z "$raw" ] && return 1

    local result="["
    local first=true
    echo "$raw" | tr '|' '\n' | while IFS= read -r item; do
        item=$(echo "$item" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$item" ] && continue
        if [ "$first" = true ]; then
            printf '%s = ["%s"' "$key" "$item"
            first=false
        else
            printf ', "%s"' "$item"
        fi
    done
    printf ']\n'
    return 0
}

# ---- client common ----

generate_client() {
    local server_addr tls_enable server_port
    local auth_type auth_token auth_token_source
    local user client_id auth_additional_scopes
    local transport_protocol wire_protocol tcp_mux pool_count
    local heartbeat_interval heartbeat_timeout
    local dial_server_timeout dial_server_keepalive
    local connect_server_local_ip proxy_url tcp_mux_keepalive_interval
    local log_to log_level log_max_days log_disable_print_color
    local dns_server login_fail_exit metadatas
    local nat_hole_stun_server udp_packet_size store_path
    local oidc_client_id oidc_client_secret oidc_audience oidc_scope
    local oidc_token_endpoint_url oidc_trusted_ca_file
    local oidc_insecure_skip_verify oidc_proxy_url
    local tls_disable_custom_first_byte tls_cert_file tls_key_file
    local tls_trusted_ca_file tls_server_name
    local quic_keepalive_period quic_max_idle_timeout quic_max_incoming_streams
    local web_server_addr web_server_port web_server_user web_server_password
    local web_server_assets_dir web_server_pprof_enable
    local virtual_net_address feature_gates includes_conf

    server_addr=$(uci_get server_addr "")
    tls_enable=$(uci_get tls "0")
    server_port=$(uci_get server_port 7000)
    auth_type=$(uci_get auth_type "token")
    auth_token=$(uci_get auth_token "")
    auth_token_source=$(uci_get auth_token_source "")
    user=$(uci_get user "")
    client_id=$(uci_get client_id "")

    # Transport
    transport_protocol=$(uci_get transport_protocol "")
    wire_protocol=$(uci_get wire_protocol "")
    tcp_mux=$(uci_get tcp_mux "0")
    pool_count=$(uci_get pool_count "")
    heartbeat_interval=$(uci_get heartbeat_interval "")
    heartbeat_timeout=$(uci_get heartbeat_timeout "")
    dial_server_timeout=$(uci_get dial_server_timeout "")
    dial_server_keepalive=$(uci_get dial_server_keepalive "")
    connect_server_local_ip=$(uci_get connect_server_local_ip "")
    proxy_url=$(uci_get proxy_url "")
    tcp_mux_keepalive_interval=$(uci_get tcp_mux_keepalive_interval "")

    # Log
    log_level=$(uci_get log_level "")
    log_max_days=$(uci_get log_max_days "")

    # Advanced
    dns_server=$(uci_get dns_server "")
    login_fail_exit=$(uci_get login_fail_exit "1")
    metadatas=$(uci_get metadatas "")
    nat_hole_stun_server=$(uci_get nat_hole_stun_server "")
    udp_packet_size=$(uci_get udp_packet_size "")
    store_path=$(uci_get store_path "")

    # OIDC
    oidc_client_id=$(uci_get oidc_client_id "")
    oidc_client_secret=$(uci_get oidc_client_secret "")
    oidc_audience=$(uci_get oidc_audience "")
    oidc_scope=$(uci_get oidc_scope "")
    oidc_token_endpoint_url=$(uci_get oidc_token_endpoint_url "")
    oidc_trusted_ca_file=$(uci_get oidc_trusted_ca_file "")
    oidc_insecure_skip_verify=$(uci_get oidc_insecure_skip_verify "0")
    oidc_proxy_url=$(uci_get oidc_proxy_url "")

    # TLS Advanced
    tls_disable_custom_first_byte=$(uci_get tls_disable_custom_first_byte "0")
    tls_cert_file=$(uci_get tls_cert_file "")
    tls_key_file=$(uci_get tls_key_file "")
    tls_trusted_ca_file=$(uci_get tls_trusted_ca_file "")
    tls_server_name=$(uci_get tls_server_name "")

    # QUIC
    quic_keepalive_period=$(uci_get quic_keepalive_period "")
    quic_max_idle_timeout=$(uci_get quic_max_idle_timeout "")
    quic_max_incoming_streams=$(uci_get quic_max_incoming_streams "")

    # WebServer
    web_server_addr=$(uci_get web_server_addr "")
    web_server_port=$(uci_get web_server_port "")
    web_server_user=$(uci_get web_server_user "")
    web_server_password=$(uci_get web_server_password "")
    web_server_assets_dir=$(uci_get web_server_assets_dir "")
    web_server_pprof_enable=$(uci_get web_server_pprof_enable "0")

    # Experimental
    virtual_net_address=$(uci_get virtual_net_address "")
    feature_gates=$(uci_get feature_gates "")
    includes_conf=$(uci_get includes "")
    log_to=$(uci_get log_to "")
    log_disable_print_color=$(uci_get log_disable_print_color "0")
    auth_additional_scopes=$(uci_get auth_additional_scopes "")

    # Validate required fields
    if [ -z "$server_addr" ]; then
        echo "Error: server_addr is required" >&2
        exit 1
    fi
    if [ "$auth_type" = "token" ] && [ -z "$auth_token" ] && [ -z "$auth_token_source" ]; then
        echo "Error: auth token or tokenSource is required" >&2
        exit 1
    fi

    # ---- output ----
    cat > "$OUTPUT_FILE" <<EOF
# Auto-generated by luci-app-frpc-new - do not edit manually
# $(date '+%Y-%m-%d %H:%M:%S')

serverAddr = "$server_addr"
serverPort = $server_port
loginFailExit = $([ "$login_fail_exit" = "0" ] && echo false || echo true)

EOF

    # Client identification
    [ -n "$user" ] && echo "user = \"$user\"" >> "$OUTPUT_FILE"
    [ -n "$client_id" ] && echo "clientID = \"$client_id\"" >> "$OUTPUT_FILE"

    # DNS server
    [ -n "$dns_server" ] && echo "dnsServer = \"$dns_server\"" >> "$OUTPUT_FILE"

    # STUN server
    [ -n "$nat_hole_stun_server" ] && echo "natHoleStunServer = \"$nat_hole_stun_server\"" >> "$OUTPUT_FILE"

    # UDP packet size
    [ -n "$udp_packet_size" ] && echo "udpPacketSize = $udp_packet_size" >> "$OUTPUT_FILE"

    # Auth section
    if [ "$auth_type" = "token" ]; then
        cat >> "$OUTPUT_FILE" <<EOF

[auth]
method = "token"
EOF
        if [ -n "$auth_token_source" ]; then
            cat >> "$OUTPUT_FILE" <<EOF
[auth.tokenSource]
type = "file"
[auth.tokenSource.file]
path = "$auth_token_source"
EOF
        else
            echo "token = \"$auth_token\"" >> "$OUTPUT_FILE"
        fi
    elif [ "$auth_type" = "oidc" ]; then
        cat >> "$OUTPUT_FILE" <<EOF

[auth]
method = "oidc"
[auth.oidc]
EOF
        [ -n "$oidc_client_id" ] && echo "clientID = \"$oidc_client_id\"" >> "$OUTPUT_FILE"
        [ -n "$oidc_client_secret" ] && echo "clientSecret = \"$oidc_client_secret\"" >> "$OUTPUT_FILE"
        [ -n "$oidc_audience" ] && echo "audience = \"$oidc_audience\"" >> "$OUTPUT_FILE"
        [ -n "$oidc_scope" ] && echo "scope = \"$oidc_scope\"" >> "$OUTPUT_FILE"
        [ -n "$oidc_token_endpoint_url" ] && echo "tokenEndpointURL = \"$oidc_token_endpoint_url\"" >> "$OUTPUT_FILE"
        [ -n "$oidc_trusted_ca_file" ] && echo "trustedCaFile = \"$oidc_trusted_ca_file\"" >> "$OUTPUT_FILE"
        [ "$oidc_insecure_skip_verify" = "1" ] && echo "insecureSkipVerify = true" >> "$OUTPUT_FILE"
        [ -n "$oidc_proxy_url" ] && echo "proxyURL = \"$oidc_proxy_url\"" >> "$OUTPUT_FILE"
    fi

    # Auth additional scopes (DynamicList ? TOML array)
    if [ -n "$auth_additional_scopes" ]; then
        _scopes_line="additionalScopes = ["
        _first=true
        for _scope in $auth_additional_scopes; do
            _scope=$(echo "$_scope" | sed -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//')
            [ -z "$_scope" ] && continue
            if [ "$_first" = true ]; then
                _scopes_line="$_scopes_line\"$_scope\""
                _first=false
            else
                _scopes_line="$_scopes_line, \"$_scope\""
            fi
        done
        _scopes_line="$_scopes_line]"
        echo "$_scopes_line" >> "$OUTPUT_FILE"
    fi

    # Transport section
    cat >> "$OUTPUT_FILE" <<EOF

[transport]
poolCount = ${pool_count:-1}
EOF

    # Protocol (tcp/kcp/quic/websocket/wss)
    [ -n "$transport_protocol" ] && echo "protocol = \"$transport_protocol\"" >> "$OUTPUT_FILE"

    # Wire protocol (v1/v2)
    [ -n "$wire_protocol" ] && echo "wireProtocol = \"$wire_protocol\"" >> "$OUTPUT_FILE"

    # TCP mux
    [ "$tcp_mux" = "1" ] && echo "tcpMux = true" >> "$OUTPUT_FILE"

    # Heartbeat
    [ -n "$heartbeat_interval" ] && echo "heartbeatInterval = $heartbeat_interval" >> "$OUTPUT_FILE"
    [ -n "$heartbeat_timeout" ] && echo "heartbeatTimeout = $heartbeat_timeout" >> "$OUTPUT_FILE"

    # Dial server
    [ -n "$dial_server_timeout" ] && echo "dialServerTimeout = $dial_server_timeout" >> "$OUTPUT_FILE"
    [ -n "$dial_server_keepalive" ] && echo "dialServerKeepalive = $dial_server_keepalive" >> "$OUTPUT_FILE"
    [ -n "$connect_server_local_ip" ] && echo "connectServerLocalIP = \"$connect_server_local_ip\"" >> "$OUTPUT_FILE"
    [ -n "$proxy_url" ] && echo "proxyURL = \"$proxy_url\"" >> "$OUTPUT_FILE"
    [ -n "$tcp_mux_keepalive_interval" ] && echo "tcpMuxKeepaliveInterval = $tcp_mux_keepalive_interval" >> "$OUTPUT_FILE"

    # TLS
    if [ "$tls_enable" = "1" ]; then
        cat >> "$OUTPUT_FILE" <<EOF

[transport.tls]
enable = true
EOF
        [ "$tls_disable_custom_first_byte" = "1" ] && echo "disableCustomTLSFirstByte = true" >> "$OUTPUT_FILE"
        [ -n "$tls_cert_file" ] && echo "certFile = \"$tls_cert_file\"" >> "$OUTPUT_FILE"
        [ -n "$tls_key_file" ] && echo "keyFile = \"$tls_key_file\"" >> "$OUTPUT_FILE"
        [ -n "$tls_trusted_ca_file" ] && echo "trustedCaFile = \"$tls_trusted_ca_file\"" >> "$OUTPUT_FILE"
        [ -n "$tls_server_name" ] && echo "serverName = \"$tls_server_name\"" >> "$OUTPUT_FILE"
    fi

    # QUIC options
    if [ -n "$quic_keepalive_period" ] || [ -n "$quic_max_idle_timeout" ] || [ -n "$quic_max_incoming_streams" ]; then
        echo "" >> "$OUTPUT_FILE"
        echo "[transport.quic]" >> "$OUTPUT_FILE"
        [ -n "$quic_keepalive_period" ] && echo "keepalivePeriod = $quic_keepalive_period" >> "$OUTPUT_FILE"
        [ -n "$quic_max_idle_timeout" ] && echo "maxIdleTimeout = $quic_max_idle_timeout" >> "$OUTPUT_FILE"
        [ -n "$quic_max_incoming_streams" ] && echo "maxIncomingStreams = $quic_max_incoming_streams" >> "$OUTPUT_FILE"
    fi

    # Log section
    if [ -n "$log_to" ] || [ -n "$log_level" ] || [ -n "$log_max_days" ] || [ "$log_disable_print_color" = "1" ]; then
        echo "" >> "$OUTPUT_FILE"
        echo "[log]" >> "$OUTPUT_FILE"
        [ -n "$log_to" ] && echo "to = \"$log_to\"" >> "$OUTPUT_FILE"
        [ -n "$log_level" ] && echo "level = \"$log_level\"" >> "$OUTPUT_FILE"
        [ -n "$log_max_days" ] && echo "maxDays = $log_max_days" >> "$OUTPUT_FILE"
        [ "$log_disable_print_color" = "1" ] && echo "disablePrintColor = true" >> "$OUTPUT_FILE"
    fi

    # Client metadatas
    if [ -n "$metadatas" ]; then
        emit_map "[metadatas]" "$metadatas" >> "$OUTPUT_FILE"
    fi

    # Store
    if [ -n "$store_path" ]; then
        echo "" >> "$OUTPUT_FILE"
        echo "[store]" >> "$OUTPUT_FILE"
        echo "path = \"$store_path\"" >> "$OUTPUT_FILE"
    fi

    # WebServer
    if [ -n "$web_server_port" ]; then
        echo "" >> "$OUTPUT_FILE"
        echo "[webServer]" >> "$OUTPUT_FILE"
        [ -n "$web_server_addr" ] && echo "addr = \"$web_server_addr\"" >> "$OUTPUT_FILE"
        echo "port = $web_server_port" >> "$OUTPUT_FILE"
        [ -n "$web_server_user" ] && echo "user = \"$web_server_user\"" >> "$OUTPUT_FILE"
        [ -n "$web_server_password" ] && echo "password = \"$web_server_password\"" >> "$OUTPUT_FILE"
        [ -n "$web_server_assets_dir" ] && echo "assetsDir = \"$web_server_assets_dir\"" >> "$OUTPUT_FILE"
        [ "$web_server_pprof_enable" = "1" ] && echo "pprofEnable = true" >> "$OUTPUT_FILE"
    fi

    # VirtualNet (Alpha)
    if [ -n "$virtual_net_address" ]; then
        echo "" >> "$OUTPUT_FILE"
        echo "[virtualNet]" >> "$OUTPUT_FILE"
        echo "address = \"$virtual_net_address\"" >> "$OUTPUT_FILE"
    fi

    # Feature Gates (pipe-separated Key:true|Key2:false)
    if [ -n "$feature_gates" ]; then
        echo "" >> "$OUTPUT_FILE"
        echo "[featureGates]" >> "$OUTPUT_FILE"
        echo "$feature_gates" | tr '|' '\n' | while IFS= read -r gate; do
            gate=$(echo "$gate" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            [ -z "$gate" ] && continue
            _fgk="${gate%%:*}"
            _fgv="${gate#*:}"
            _fgk=$(echo "$_fgk" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            _fgv=$(echo "$_fgv" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            [ -n "$_fgk" ] && printf '%s = %s\n' "$_fgk" "$_fgv"
        done >> "$OUTPUT_FILE"
    fi

    # Includes (pipe-separated config file paths ? single TOML array)
    if [ -n "$includes_conf" ]; then
        _inc_line="includes = ["
        _first=true
        _inc_items=$(echo "$includes_conf" | tr '|' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$')
        for inc in $_inc_items; do
            if [ "$_first" = true ]; then
                _inc_line="$_inc_line\"$inc\""
                _first=false
            else
                _inc_line="$_inc_line, \"$inc\""
            fi
        done
        _inc_line="$_inc_line]"
        echo "" >> "$OUTPUT_FILE"
        echo "$_inc_line" >> "$OUTPUT_FILE"
    fi
}

# ---- proxy ----

generate_proxy() {
    local section="$1"
    local name type local_ip local_port
    local remote_port custom_domains subdomain
    local http_user http_pwd
    local host_header_rewrite locations
    local request_headers response_headers
    local route_by_http_user multiplexer
    local use_encryption use_compression
    local bandwidth_limit bandwidth_limit_mode
    local transport_type proxy_protocol_version pool_count
    local health_check_type health_check_timeout_s
    local health_check_max_failed health_check_interval_s
    local health_check_path health_check_headers
    local plugin_type plugin_user plugin_pass
    local plugin_local_path plugin_strip_prefix
    local plugin_http_user plugin_http_passwd
    local plugin_addr sni_rewrite
    local secret_key role server_name allow_users
    local metadatas annotations
    local load_balance_group load_balance_group_key
    local nat_disable_assisted_addrs

    name=$(sec_get "$section" name "")
    type=$(sec_get "$section" type "tcp")
    local_ip=$(sec_get "$section" local_ip "127.0.0.1")
    local_port=$(sec_get "$section" local_port "")

    if [ -z "$name" ] || [ -z "$local_port" ]; then
        echo "Warning: proxy $section missing name or local_port, skipping" >&2
        return
    fi

    echo "[[proxies]]" >> "$OUTPUT_FILE"
    emit "name" "$name"
    emit "type" "$type"
    emit "localIP" "$local_ip"
    emit_int "localPort" "$local_port"

    # TCP/UDP/SUDP: remotePort
    if [ "$type" = "tcp" ] || [ "$type" = "udp" ] || [ "$type" = "sudp" ]; then
        remote_port=$(sec_get "$section" remote_port "")
        [ -n "$remote_port" ] && emit_int "remotePort" "$remote_port"
    fi

    # HTTP/HTTPS/TCPMux: domains, subdomain, HTTP settings
    if [ "$type" = "http" ] || [ "$type" = "https" ] || [ "$type" = "tcpmux" ]; then
        custom_domains=$(sec_get "$section" custom_domains "")
        subdomain=$(sec_get "$section" subdomain "")

        if [ -n "$custom_domains" ]; then
            # Build TOML array: customDomains = ["d1", "d2"]
            printf 'customDomains = ['
            local first=true
            echo "$custom_domains" | tr ',' '\n' | while IFS= read -r d; do
                d=$(echo "$d" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                [ -z "$d" ] && continue
                if [ "$first" = true ]; then
                    printf '"%s"' "$d"
                    first=false
                else
                    printf ', "%s"' "$d"
                fi
            done
            printf ']\n'
        fi

        [ -n "$subdomain" ] && emit "subdomain" "$subdomain"
    fi

    # HTTP/HTTPS: httpUser, httpPassword, hostHeaderRewrite, locations, headers, routeByHTTPUser
    if [ "$type" = "http" ] || [ "$type" = "https" ]; then
        http_user=$(sec_get "$section" http_user "")
        http_pwd=$(sec_get "$section" http_pwd "")
        [ -n "$http_user" ] && emit "httpUser" "$http_user"
        [ -n "$http_pwd" ] && emit "httpPassword" "$http_pwd"

        route_by_http_user=$(sec_get "$section" route_by_http_user "")
        [ -n "$route_by_http_user" ] && emit "routeByHTTPUser" "$route_by_http_user"

        response_headers=$(sec_get "$section" response_headers "")
        [ -n "$response_headers" ] && emit_map "[proxies.responseHeaders]" "$response_headers"
    fi

    # HTTP/HTTPS/TCPMux: hostHeaderRewrite, locations, multiplexer, requestHeaders
    if [ "$type" = "http" ] || [ "$type" = "https" ] || [ "$type" = "tcpmux" ]; then
        host_header_rewrite=$(sec_get "$section" host_header_rewrite "")
        [ -n "$host_header_rewrite" ] && emit "hostHeaderRewrite" "$host_header_rewrite"

        multiplexer=$(sec_get "$section" multiplexer "")
        [ -n "$multiplexer" ] && emit "multiplexer" "$multiplexer"

        locations=$(sec_get "$section" locations "")
        if [ -n "$locations" ]; then
            printf 'locations = ['
            local first=true
            echo "$locations" | tr '|' '\n' | while IFS= read -r loc; do
                loc=$(echo "$loc" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                [ -z "$loc" ] && continue
                if [ "$first" = true ]; then
                    printf '"%s"' "$loc"
                    first=false
                else
                    printf ', "%s"' "$loc"
                fi
            done
            printf ']\n'
        fi

        request_headers=$(sec_get "$section" request_headers "")
        [ -n "$request_headers" ] && emit_map "[proxies.requestHeaders]" "$request_headers"
    fi

    # Plugin
    plugin_type=$(sec_get "$section" plugin_type "")
    if [ -n "$plugin_type" ]; then
        printf '[proxies.plugin]\n'
        case "$plugin_type" in
            socks5)
                plugin_user=$(sec_get "$section" plugin_user "")
                plugin_pass=$(sec_get "$section" plugin_pass "")
                emit "type" "socks5"
                [ -n "$plugin_user" ] && emit "user" "$plugin_user"
                [ -n "$plugin_pass" ] && { emit "passwd" "$plugin_pass"; }
                ;;
            http_proxy)
                plugin_user=$(sec_get "$section" plugin_user "")
                plugin_pass=$(sec_get "$section" plugin_pass "")
                emit "type" "http_proxy"
                [ -n "$plugin_user" ] && { emit "httpUser" "$plugin_user"; }
                [ -n "$plugin_pass" ] && { emit "httpPassword" "$plugin_pass"; }
                ;;
            static_file)
                plugin_local_path=$(sec_get "$section" plugin_local_path "")
                plugin_strip_prefix=$(sec_get "$section" plugin_strip_prefix "")
                plugin_http_user=$(sec_get "$section" plugin_http_user "")
                plugin_http_passwd=$(sec_get "$section" plugin_http_passwd "")
                emit "type" "static_file"
                [ -n "$plugin_local_path" ] && emit "localPath" "$plugin_local_path"
                [ -n "$plugin_strip_prefix" ] && emit "stripPrefix" "$plugin_strip_prefix"
                [ -n "$plugin_http_user" ] && { emit "httpUser" "$plugin_http_user"; }
                [ -n "$plugin_http_passwd" ] && { emit "httpPassword" "$plugin_http_passwd"; }
                ;;
            unix_domain_socket)
                plugin_addr=$(sec_get "$section" plugin_addr "")
                emit "type" "unix_domain_socket"
                [ -n "$plugin_addr" ] && emit "addr" "$plugin_addr"
                ;;
            http2socks)
                plugin_local_path=$(sec_get "$section" plugin_local_path "")
                emit "type" "http2socks"
                [ -n "$plugin_local_path" ] && emit "localPath" "$plugin_local_path"
                ;;
            sni)
                sni_rewrite=$(sec_get "$section" sni_rewrite "")
                emit "type" "sni"
                [ -n "$sni_rewrite" ] && emit "hostHeaderRewrite" "$sni_rewrite"
                ;;
            http2https)
                plugin_local_addr=$(sec_get "$section" plugin_local_addr "")
                plugin_host_header_rewrite=$(sec_get "$section" plugin_host_header_rewrite "")
                emit "type" "http2https"
                [ -n "$plugin_local_addr" ] && emit "localAddr" "$plugin_local_addr"
                [ -n "$plugin_host_header_rewrite" ] && emit "hostHeaderRewrite" "$plugin_host_header_rewrite"
                ;;
            https2http)
                plugin_local_addr=$(sec_get "$section" plugin_local_addr "")
                plugin_host_header_rewrite=$(sec_get "$section" plugin_host_header_rewrite "")
                plugin_enable_http2=$(sec_get "$section" plugin_enable_http2 "1")
                plugin_crt_path=$(sec_get "$section" plugin_crt_path "")
                plugin_key_path=$(sec_get "$section" plugin_key_path "")
                emit "type" "https2http"
                [ -n "$plugin_local_addr" ] && emit "localAddr" "$plugin_local_addr"
                [ -n "$plugin_host_header_rewrite" ] && emit "hostHeaderRewrite" "$plugin_host_header_rewrite"
                [ "$plugin_enable_http2" = "0" ] && emit_raw "enableHTTP2" "false"
                [ -n "$plugin_crt_path" ] && emit "crtPath" "$plugin_crt_path"
                [ -n "$plugin_key_path" ] && emit "keyPath" "$plugin_key_path"
                ;;
            https2https)
                plugin_local_addr=$(sec_get "$section" plugin_local_addr "")
                plugin_host_header_rewrite=$(sec_get "$section" plugin_host_header_rewrite "")
                plugin_enable_http2=$(sec_get "$section" plugin_enable_http2 "1")
                plugin_crt_path=$(sec_get "$section" plugin_crt_path "")
                plugin_key_path=$(sec_get "$section" plugin_key_path "")
                emit "type" "https2https"
                [ -n "$plugin_local_addr" ] && emit "localAddr" "$plugin_local_addr"
                [ -n "$plugin_host_header_rewrite" ] && emit "hostHeaderRewrite" "$plugin_host_header_rewrite"
                [ "$plugin_enable_http2" = "0" ] && emit_raw "enableHTTP2" "false"
                [ -n "$plugin_crt_path" ] && emit "crtPath" "$plugin_crt_path"
                [ -n "$plugin_key_path" ] && emit "keyPath" "$plugin_key_path"
                ;;
            tls2raw)
                plugin_local_addr=$(sec_get "$section" plugin_local_addr "")
                plugin_crt_path=$(sec_get "$section" plugin_crt_path "")
                plugin_key_path=$(sec_get "$section" plugin_key_path "")
                emit "type" "tls2raw"
                [ -n "$plugin_local_addr" ] && emit "localAddr" "$plugin_local_addr"
                [ -n "$plugin_crt_path" ] && emit "crtPath" "$plugin_crt_path"
                [ -n "$plugin_key_path" ] && emit "keyPath" "$plugin_key_path"
                ;;
        esac
        echo ""
    fi

    # Proxy transport settings
    use_encryption=$(sec_get "$section" use_encryption "")
    use_compression=$(sec_get "$section" use_compression "")
    bandwidth_limit=$(sec_get "$section" bandwidth_limit "")
    bandwidth_limit_mode=$(sec_get "$section" bandwidth_limit_mode "")
    transport_type=$(sec_get "$section" transport_type "")
    proxy_protocol_version=$(sec_get "$section" proxy_protocol_version "")
    pool_count=$(sec_get "$section" pool_count "")

    if [ -n "$use_encryption" ] || [ -n "$use_compression" ] || [ -n "$bandwidth_limit" ] || \
       [ -n "$transport_type" ] || [ -n "$proxy_protocol_version" ] || [ -n "$pool_count" ]; then
        printf '[proxies.transport]\n'
        [ -n "$use_encryption" ] && emit_raw "useEncryption" "$use_encryption"
        [ -n "$use_compression" ] && emit_raw "useCompression" "$use_compression"
        [ -n "$bandwidth_limit" ] && emit "bandwidthLimit" "$bandwidth_limit"
        [ -n "$bandwidth_limit_mode" ] && emit "bandwidthLimitMode" "$bandwidth_limit_mode"
        [ -n "$transport_type" ] && emit "transportType" "$transport_type"
        [ -n "$proxy_protocol_version" ] && emit "proxyProtocolVersion" "$proxy_protocol_version"
        [ -n "$pool_count" ] && emit_int "poolCount" "$pool_count"
        echo ""
    fi

    # STCP/XTCP/SUDP: secretKey, role, serverName, allowUsers
    if [ "$type" = "stcp" ] || [ "$type" = "xtcp" ] || [ "$type" = "sudp" ]; then
        secret_key=$(sec_get "$section" secret_key "")
        role=$(sec_get "$section" role "")
        server_name=$(sec_get "$section" server_name "")
        allow_users=$(sec_get "$section" allow_users "")

        [ -n "$secret_key" ] && emit "secretKey" "$secret_key"
        [ -n "$role" ] && emit "role" "$role"
        [ -n "$server_name" ] && emit "serverName" "$server_name"

        if [ -n "$allow_users" ]; then
            printf 'allowUsers = ['
            local first=true
            echo "$allow_users" | tr ',' '\n' | while IFS= read -r u; do
                u=$(echo "$u" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                [ -z "$u" ] && continue
                if [ "$first" = true ]; then
                    printf '"%s"' "$u"
                    first=false
                else
                    printf ', "%s"' "$u"
                fi
            done
            printf ']\n'
        fi
    fi

    # Health check
    health_check_type=$(sec_get "$section" health_check_type "")
    if [ -n "$health_check_type" ]; then
        printf '[proxies.healthCheck]\n'
        emit "type" "$health_check_type"
        health_check_timeout_s=$(sec_get "$section" health_check_timeout_s "")
        health_check_max_failed=$(sec_get "$section" health_check_max_failed "")
        health_check_interval_s=$(sec_get "$section" health_check_interval_s "")
        [ -n "$health_check_timeout_s" ] && emit_int "timeoutSeconds" "$health_check_timeout_s"
        [ -n "$health_check_max_failed" ] && emit_int "maxFailed" "$health_check_max_failed"
        [ -n "$health_check_interval_s" ] && emit_int "intervalSeconds" "$health_check_interval_s"

        if [ "$health_check_type" = "http" ]; then
            health_check_path=$(sec_get "$section" health_check_path "")
            health_check_headers=$(sec_get "$section" health_check_headers "")
            [ -n "$health_check_path" ] && emit "path" "$health_check_path"
            [ -n "$health_check_headers" ] && emit_map "[proxies.healthCheck.httpHeaders]" "$health_check_headers"
        fi
        echo ""
    fi

    # Proxy metadatas
    metadatas=$(sec_get "$section" metadatas "")
    [ -n "$metadatas" ] && emit_map "[proxies.metadatas]" "$metadatas"

    # Proxy annotations
    annotations=$(sec_get "$section" annotations "")
    [ -n "$annotations" ] && emit_map "[proxies.annotations]" "$annotations"

    # Load balancer
    load_balance_group=$(sec_get "$section" load_balance_group "")
    load_balance_group_key=$(sec_get "$section" load_balance_group_key "")
    if [ -n "$load_balance_group" ]; then
        echo "[proxies.loadBalancer]"
        emit "group" "$load_balance_group"
        [ -n "$load_balance_group_key" ] && emit "groupKey" "$load_balance_group_key"
    fi

    # NAT traversal (XTCP only)
    if [ "$type" = "xtcp" ]; then
        nat_disable_assisted_addrs=$(sec_get "$section" nat_disable_assisted_addrs "0")
        if [ "$nat_disable_assisted_addrs" = "1" ]; then
            echo "[proxies.natTraversal]"
            echo "disableAssistedAddrs = true"
        fi
    fi

    echo "" >> "$OUTPUT_FILE"
}

# ---- visitor ----

generate_visitor() {
    local section="$1"
    local name type server_user server_name
    local secret_key bind_addr bind_port
    local use_encryption use_compression
    local protocol pool_count
    local bandwidth_limit bandwidth_limit_mode transport_type metadatas
    local keep_tunnel_open max_retries fallback_to fallback_timeout_ms

    name=$(sec_get "$section" name "")
    type=$(sec_get "$section" type "stcp")
    server_user=$(sec_get "$section" server_user "")
    server_name=$(sec_get "$section" server_name "")
    secret_key=$(sec_get "$section" secret_key "")
    bind_addr=$(sec_get "$section" bind_addr "127.0.0.1")
    bind_port=$(sec_get "$section" bind_port "")

    if [ -z "$name" ] || [ -z "$server_name" ] || [ -z "$bind_port" ]; then
        echo "Warning: visitor $section missing name, server_name or bind_port, skipping" >&2
        return
    fi

    echo "[[visitors]]" >> "$OUTPUT_FILE"
    emit "name" "$name"
    emit "type" "$type"
    [ -n "$server_user" ] && emit "serverUser" "$server_user"
    emit "serverName" "$server_name"
    [ -n "$secret_key" ] && emit "secretKey" "$secret_key"
    emit "bindAddr" "$bind_addr"
    emit_int "bindPort" "$bind_port"

    # Transport
    use_encryption=$(sec_get "$section" use_encryption "")
    use_compression=$(sec_get "$section" use_compression "")
    pool_count=$(sec_get "$section" pool_count "")
    bandwidth_limit=$(sec_get "$section" bandwidth_limit "")
    bandwidth_limit_mode=$(sec_get "$section" bandwidth_limit_mode "")
    transport_type=$(sec_get "$section" transport_type "")

    if [ -n "$use_encryption" ] || [ -n "$use_compression" ] || [ -n "$pool_count" ] || \
       [ -n "$bandwidth_limit" ] || [ -n "$transport_type" ]; then
        printf '[visitors.transport]\n'
        [ -n "$use_encryption" ] && emit_raw "useEncryption" "$use_encryption"
        [ -n "$use_compression" ] && emit_raw "useCompression" "$use_compression"
        [ -n "$pool_count" ] && emit_int "poolCount" "$pool_count"
        [ -n "$bandwidth_limit" ] && emit "bandwidthLimit" "$bandwidth_limit"
        [ -n "$bandwidth_limit_mode" ] && emit "bandwidthLimitMode" "$bandwidth_limit_mode"
        [ -n "$transport_type" ] && emit "transportType" "$transport_type"
        echo ""
    fi

    # XTCP specific
    if [ "$type" = "xtcp" ]; then
        protocol=$(sec_get "$section" protocol "")
        keep_tunnel_open=$(sec_get "$section" keep_tunnel_open "0")
        max_retries=$(sec_get "$section" max_retries "")
        fallback_to=$(sec_get "$section" fallback_to "")
        fallback_timeout_ms=$(sec_get "$section" fallback_timeout_ms "")

        [ -n "$protocol" ] && emit "protocol" "$protocol"
        [ "$keep_tunnel_open" = "1" ] && echo "keepTunnelOpen = true"
        [ -n "$max_retries" ] && emit_int "maxRetriesAnHour" "$max_retries"
        [ -n "$fallback_to" ] && emit "fallbackTo" "$fallback_to"
        [ -n "$fallback_timeout_ms" ] && emit_int "fallbackTimeoutMs" "$fallback_timeout_ms"
    fi

    # Metadatas
    metadatas=$(sec_get "$section" metadatas "")
    [ -n "$metadatas" ] && emit_map "[visitors.metadatas]" "$metadatas"

    echo "" >> "$OUTPUT_FILE"
}

# ---- main ----

mkdir -p "$(dirname "$OUTPUT_FILE")"
generate_client

# Append each enabled proxy
for section in $(uci -q show "$FRPC_CONFIG" | grep "=proxy$" | cut -d. -f2 | cut -d= -f1 | while read s; do
    enabled=$(uci -q get "$FRPC_CONFIG.$s.enabled" 2>/dev/null)
    [ "$enabled" = "1" ] && echo "$s"
done); do
    generate_proxy "$section" >> "$OUTPUT_FILE"
done

# Append each enabled visitor
for section in $(uci -q show "$FRPC_CONFIG" | grep "=visitor$" | cut -d. -f2 | cut -d= -f1 | while read s; do
    enabled=$(uci -q get "$FRPC_CONFIG.$s.enabled" 2>/dev/null)
    [ "$enabled" = "1" ] && echo "$s"
done); do
    generate_visitor "$section" >> "$OUTPUT_FILE"
done

# Verify generated config
if command -v frpc >/dev/null 2>&1; then
    if ! frpc verify -c "$OUTPUT_FILE" >/dev/null 2>&1; then
        echo "Warning: generated frpc.toml has syntax errors, check config" >&2
    fi
fi

echo "Generated $OUTPUT_FILE at $(date)"
