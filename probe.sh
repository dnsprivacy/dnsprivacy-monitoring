#!/usr/bin/env bash
MON="./getdns_server_mon -v -M --tls"

declare -a servers=(
"getdnsapi.net"
"getdnsapi.net (port 443)"
"dns.quad9.net"
"1dot1dot1dot1.cloudflare-dns.com"
"dns.google"
"dns-unfiltered.adguard.com"
"unicast.censurfridns.dk"
"dot1.appliedprivacy.net"
"dnspub.restena.lu"
"dns.neutopia.org"
"dnsotls.lab.nic.cl"
"ibksturm.synology.me"
"fdns1.dismail.de"
"dot-de.blahdns.com"
"ns0.fdn.fr"
)
  
declare -a commands=(
"TLS"
"TLS 443"
"Strict Name"
"Strict Name 443"
"Cert 0"
"Cert 14"
"QNAME min"
"RTT 250"
"DNSSEC"
"Keepalive"
"Padding"
"TLS 1.3"
"OOOR"
)

echo "## dnsprivacy.org monitoring results" > results.md
echo " " >> results.md
echo "Latest run at: " $(date) >> results.md
echo " " >> results.md
echo "See [the output of the latest workflow for more details](https://github.com/dnsprivacy/dnsprivacy-monitoring/actions/workflows/dnsprivacy-monitoring.yml)"  >> results.md
echo "" >> results.md


echo "|Server and IP version|TLS|TLS 443| Strict Name| Strict Name 443| Cert 0| Cert 14| QNAME min| RTT 250| DNSSEC| Keepalive| Padding| TLS 1.3| OOOR |" >> results.md
echo "| ---  | --- |---  | ---         |---            | ---   |---     | ---      |---     | ---    |---      | ---    |---     | ---  |" >> results.md

for server in "${servers[@]}"; do

  echo
  echo $server " "
  for ip in "v4" "v6"; do
    # Since we use Cloudflare WARP to provide v6 support, we cannot actually connect to 1.1.1.1 over v6!
    if [ "${server}" == "1dot1dot1dot1.cloudflare-dns.com" ] &&  [ "${ip}" == "v6" ] ; then
      continue
    fi

    echo -n "|" $server " ("$ip")" "|" >> results.md

    for command in "${commands[@]}"; do
      auth_server=$server
      # dns.neutopia.org use a CNAME so tail the output
      if [ "${server}" == "getdnsapi.net (port 443)" ] ; then
        if  [ "${ip}" == "v4" ] ; then
          ADDR="185.49.141.37"
          else
          ADDR="2a04:b900:0:100::38"
          fi
          auth_server="getdnsapi.net"
      elif [ "${ip}" == "v6" ] ; then
        if [ "${server}" == "family-filter-dns.cleanbrowsing.org" ] ; then
          ADDR="2a0d:2a00:1::2]"
        else
          ADDR=$(dig +short $server AAAA | tail -n 1)
        fi
      else
        ADDR=$(dig +short $server A | tail -n 1)
      fi

      echo -n "[" $ADDR "," $command "]: "

      ARGS=""
      CMD=""

      case "${command}" in
        TLS) 			CMD="lookup";;
        TLS\ 443)		CMD="lookup"; ADDR="${ADDR}#443";;
        Strict\ Name)	CMD="tls-auth"; ARGS="--strict-usage-profile"; ADDR="${ADDR}~${auth_server}";;
        Strict\ Name\ 443)	CMD="tls-auth"; ARGS="--strict-usage-profile"; ADDR="${ADDR}~${auth_server}#443";;
        Cert\ 0)		CMD="tls-cert-valid 0,0";;
        Cert\ 14)		CMD="tls-cert-valid 14,14";;
        QNAME\ min)		CMD="qname-min";;
        RTT\ 250)		CMD="rtt 250,250";;
        DNSSEC)			CMD="dnssec-validate";;
        Keepalive)		CMD="keepalive";;
        Padding)		CMD="tls-padding 1";;
        TLS\ 1.3)		CMD="tls-1.3";;
        OOOR)       CMD="OOOR" ;;
      esac

      ${MON} ${ARGS} @${ADDR} ${CMD} 
      if [  $? -ne 0 ]; then
        echo -n "  :x:  |" >> results.md
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
echo " * **TLS 443** Does the server answer DNS queries over TLS on port 443 with no SNI sent?" >> results.md
echo " * **Strict Name** Does the server pass Strict authentication using the authentication domain name only?" >> results.md
echo " * **Strict Name 443** Does the server pass Strict authentication using the authentication domain name only on 443 (some operators require an SNI on 443 to defend against attacks)?" >> results.md
echo " * **Cert 0** Are there 0 days or less to certificate expiry?" >> results.md
echo " * **Cert 14** Are there 14 or fewer days to certificate expiry?" >> results.md
echo " * **QNAME min** Is the server configured to use QNAME minimisation [RFC7816]?" >> results.md
echo " * **RTT 250** Is a simple query round trip time from the probe location < 250ms?" >> results.md
echo " * **DNSSEC** Is the server doing DNSSEC validation (i.e. returning SERVFAIL for bogus domains)?" >> results.md
echo " * **Keepalive** Does the server support the EDNS0 Keepalive option [RFC7828]?" >> results.md
echo " * **Padding** Does the server add an EDNS0 Padding option to the response if one is in the query [RFC7830]?" >> results.md
echo " * **TLS 1.3** Does the server support TLS 1.3 ?" >> results.md
echo " * **OOOR** Does the server give Out Of Order Responses (Experimental, may give false negatives)?" >> results.md
echo >> results.md
echo "Authentication information is taken from the [DNS Privacy Project Test Servers](https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Test+Servers) page. These tests use getdns_server_mon, a [getdns based monitoring plugin](https://github.com/getdnsapi/getdns/tree/develop/src/tools)."  >> results.md
echo >> results.md
echo "Note that Quad9, Cloudflare and Google and others operate an anycast service so the results below are just for the location of the Github test runner used for the test." >> results.md