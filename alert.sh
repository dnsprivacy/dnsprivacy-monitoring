#!/usr/bin/env bash
MON="./getdns_server_mon -v -M --tls"

declare -a servers=(
"getdnsapi.net"
)
  
declare -a commands=(
"TLS"
"Strict Name"
"Cert 0"
"Cert 7"
)

RES=0

echo "|Server and IP version|TLS| Strict Name| Cert 0| Cert 7|" > results.md
echo "| ---                 | --- |---        | ---  |---    | " >> results.md

for server in "${servers[@]}"; do

  echo
  echo $server " "
  for ip in "v4" "v6"; do

    echo -n "|" $server " ("$ip")" "|" >> results.md

    for command in "${commands[@]}"; do
      if [ "${ip}" == "v6" ]; then
        ADDR=$(dig +short $server AAAA | tail -n 1)
      else
        ADDR=$(dig +short $server A | tail -n 1)
      fi

      echo -n "[" $ADDR "," $command "]: "

      ARGS=""
      CMD=""

      case "${command}" in
        TLS) 			CMD="lookup";;
        Strict\ Name)	CMD="tls-auth"; ARGS="--strict-usage-profile"; ADDR="${ADDR}~${server}";;
        Cert\ 0)		CMD="tls-cert-valid 0,0";;
        Cert\ 7)		CMD="tls-cert-valid 7,7";;
      esac

      ${MON} ${ARGS} @${ADDR} ${CMD} 
      if [  $? -ne 0 ]; then
        echo -n "  :x:  |" >> results.md
        RES=1
      else
        echo -n "  :white_check_mark:  |" >> results.md
      fi

      # Needed as a few test use records with 1s TTL and we do v4 then v6
      sleep 1
    done
  echo "" >> results.md
  done
done

echo " "
echo "####  All the following are tested over TLS connections:" >> results.md
echo >> results.md
echo " * **TLS** Does the server answer DNS queries over TLS on port 853 with no SNI sent?" >> results.md
echo " * **Strict Name** Does the server pass Strict authentication using the authentication domain name only?" >> results.md
echo " * **Cert 0** Are there 0 days or less to certificate expiry?" >> results.md
echo " * **Cert 7** Are there 7 or fewer days to certificate expiry?" >> results.md
echo >> results.md
echo "Authentication information is taken from the [DNS Privacy Project Test Servers](https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Test+Servers) page. These tests use getdns_server_mon, a [getdns based monitoring plugin](https://github.com/getdnsapi/getdns/tree/develop/src/tools)."  >> results.md


exit $RES