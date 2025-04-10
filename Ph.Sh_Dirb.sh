#!/bin/bash

# Author    : Ph.sh (Philopater Shenouda)
# LinkedIn  : https://www.linkedin.com/in/philopater-shenouda/
# Date      : 2025-04-10
# Version   : 1.0

# Display ASCII banner
command -v figlet >/dev/null 2>&1 || { echo "Installing figlet..."; sudo apt install figlet -y; }
echo "Ph.sh" | figlet

# Check for anew
if ! command -v anew &> /dev/null; then
    echo "[!] 'anew' not found. Installing..."
    sudo apt install golang -y
    go install -v github.com/tomnomnom/anew@latest
    sudo cp ~/go/bin/anew /usr/local/bin
fi

# Record start time
start_time=$(date +%s)
start_date=$(date "+%Y-%m-%d %H:%M:%S")
echo "[+] Scan started at: $start_date"

# Ask for target
read -p "Enter your target (e.g., example.com): " target
read -p "You entered '$target'. Are you sure? (Yes/No): " sure
case "$sure" in
  [Yy]|[Yy][Ee][Ss]) ;;
  [Nn]|[Nn][Oo])
    echo "Exiting. Please run the script again and confirm."
    exit 1
    ;;
  *)
    echo "Invalid input. Please enter Yes or No."
    exit 1
    ;;
esac

# Wordlists
mapfile -t wordlists < <(cat <<EOF
/usr/share/dirb/wordlists/big.txt
/usr/share/dirb/wordlists/common.txt
/usr/share/dirb/wordlists/extensions_common.txt
/usr/share/dirb/wordlists/mutations_common.txt
/usr/share/dirb/wordlists/small.txt
/usr/share/dirb/wordlists/others/best1050.txt
/usr/share/dirb/wordlists/others/best110.txt
/usr/share/dirb/wordlists/others/best15.txt
/usr/share/dirb/wordlists/others/names.txt
/usr/share/dirb/wordlists/stress/alphanum_case_extra.txt
/usr/share/dirb/wordlists/stress/alphanum_case.txt
/usr/share/dirb/wordlists/stress/char.txt
/usr/share/dirb/wordlists/stress/doble_uri_hex.txt
/usr/share/dirb/wordlists/stress/test_ext.txt
/usr/share/dirb/wordlists/stress/unicode.txt
/usr/share/dirb/wordlists/stress/uri_hex.txt
/usr/share/dirb/wordlists/vulns/apache.txt
/usr/share/dirb/wordlists/vulns/domino.txt
/usr/share/dirb/wordlists/vulns/hpsmh.txt
/usr/share/dirb/wordlists/vulns/jboss.txt
/usr/share/dirb/wordlists/vulns/oracle.txt
/usr/share/dirb/wordlists/vulns/sunas.txt
/usr/share/dirb/wordlists/vulns/weblogic.txt
/usr/share/dirb/wordlists/vulns/axis.txt
/usr/share/dirb/wordlists/vulns/fatwire_pagenames.txt
/usr/share/dirb/wordlists/vulns/hyperion.txt
/usr/share/dirb/wordlists/vulns/jersey.txt
/usr/share/dirb/wordlists/vulns/ror.txt
/usr/share/dirb/wordlists/vulns/tests.txt
/usr/share/dirb/wordlists/vulns/websphere.txt
/usr/share/dirb/wordlists/vulns/cgis.txt
/usr/share/dirb/wordlists/vulns/fatwire.txt
/usr/share/dirb/wordlists/vulns/iis.txt
/usr/share/dirb/wordlists/vulns/jrun.txt
/usr/share/dirb/wordlists/vulns/sap.txt
/usr/share/dirb/wordlists/vulns/tomcat.txt
EOF
)

total=${#wordlists[@]}
current=0

# Progress bar
print_progress() {
    percent=$(( 100 * current / total ))
    bar_length=50
    filled=$(( percent * bar_length / 100 ))
    empty=$(( bar_length - filled ))
    bar=$(printf "%${filled}s" | tr ' ' '=')$(printf "%${empty}s")
    echo -ne "\r[${bar}] ${percent}%% - ${1}"
}

# Temp dir
mkdir -p results_tmp

# Run dirb
for wordlist in "${wordlists[@]}"; do
    encoded=$(echo "$wordlist" | sed 's/\//_/g')
    current=$((current + 1))
    print_progress "$wordlist"
    dirb "http://$target" "$wordlist" -o results_tmp/result_${encoded}.txt > /dev/null 2>&1
done

# Combine results
cat results_tmp/*.txt > "final_results_dirb_$target.txt"
rm -r results_tmp

# Filter useful results using 'anew'
cat "final_results_dirb_$target.txt" | grep "http://$target" | grep "CODE:200" | anew >> URL

# Word count for the filtered results
count=$(wc -l < URL)
echo -e "\n[+] Number of valid 200 OK URLs: $count"

# End timing
end_time=$(date +%s)
duration=$((end_time - start_time))

# Final output
echo "[+] Scan completed!"
echo "[+] Started at : $start_date"
echo "[+] Finished at: $(date "+%Y-%m-%d %H:%M:%S")"
echo "[+] Duration   : $((duration / 60)) min $((duration % 60)) sec"
echo "[+] Results saved in: final_results_dirb_$target.txt"
echo "[+] Filtered URLs saved in: URL"

