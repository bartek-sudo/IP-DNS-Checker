#!/bin/bash

# Sprawdzenie czy podano plik wejściowy
if [ $# -ne 1 ]; then
  echo "Usage: $0 <input_file>"
  exit 1
fi

input_file=$1
output_file="Raport_DNS_$(date +%Y-%m-%d_%H-%M).txt"

# Funkcja do sprawdzania domeny
check_domain() {
  domain=$1
  echo "Sprawdzanie domeny: $domain"
  
  # Sprawdzenie czy domena jest zajęta
  whois_info=$(whois $domain)
  if echo "$whois_info" | grep -qi "No match"; then
    echo "Domena $domain jest wolna." >> $output_file
    return
  else
    echo "Domena $domain jest zajęta." >> $output_file
  fi

  # Właściciel domeny
  owner=$(echo "$whois_info" | grep -iE "Registrant Name|Registrant Organization|Organization" | head -n 1)
  if [ -z "$owner" ]; then
    owner="Nieznany"
  fi
  echo "Właściciel domeny: $owner" >> $output_file

  # Data wygaśnięcia
  expiry_date=$(echo "$whois_info" | grep -iE "Expiry Date|Expiration Date|paid-till" | head -n 1)
  if [ -z "$expiry_date" ]; then
    expiry_date="Nieznana"
  fi
  echo "Data wygaśnięcia domeny: $expiry_date" >> $output_file
  echo "" >> $output_file
}

# Funkcja do sprawdzania adresu IP
check_ip() {
  ip=$1
  echo "Sprawdzanie adresu IP: $ip"
  
  # Reverse DNS lookup
  domain=$(dig -x $ip +short)
  if [ -z "$domain" ]; then
    echo "Adres IP $ip nie jest powiązany z żadną domeną." >> $output_file
    echo "" >> $output_file
  else
    domain=$(echo $domain | sed 's/\.$//') # Usunięcie końcowej kropki
    echo "Adres IP $ip jest powiązany z domeną: $domain" >> $output_file
    check_domain $domain
  fi
}

# Główna pętla przetwarzająca plik wejściowy
while IFS= read -r line || [[ -n "$line" ]]; do
  # Pomijanie pustych linii
  if [ -z "$line" ]; then
    continue
  fi

  # Sprawdzanie czy linia jest adresem IP
  if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    check_ip $line
  else
    check_domain $line
  fi
done < "$input_file"

echo "Raport zapisano do pliku $output_file"
