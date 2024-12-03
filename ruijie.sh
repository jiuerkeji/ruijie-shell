#!/bin/bash

# Function to display usage instructions
usage() {
  echo "Usage: $0 [-d] username password"
  echo "Options:"
  echo "  -d   Enable debug mode"
  echo "Example: $0 201620000000 123456"
  exit 1
}

# Debug mode flag
DEBUG=0

# Parse options
while getopts ":d" opt; do
  case $opt in
    d)
      DEBUG=1
      ;;
    *)
      usage
      ;;
  esac
done

# Shift options
shift $((OPTIND - 1))

# Check if username and password are provided
if [ "$#" -lt 2 ]; then
  usage
fi

USERNAME=$1
PASSWORD=$2

# Check dependencies
for cmd in curl awk; do
  if ! command -v $cmd &>/dev/null; then
    echo "Error: $cmd is not installed."
    exit 1
  fi
done

# Function to debug output
debug_log() {
  if [ "$DEBUG" -eq 1 ]; then
    echo "Debug: $1"
  fi
}

# Check network status using Google captive portal
debug_log "Checking network status..."
CAPTIVE_RETURN_CODE=$(curl -s -I -m 10 -o /dev/null -w "%{http_code}" http://www.google.cn/generate_204)
if [ "$CAPTIVE_RETURN_CODE" -eq 204 ]; then
  echo "You are already online!"
  exit 0
fi

# Retrieve Ruijie login page URL
debug_log "Retrieving Ruijie login page URL..."
LOGIN_PAGE_URL=$(curl -s "http://www.google.cn/generate_204" | awk -F \' '{print $2}')
if [ -z "$LOGIN_PAGE_URL" ]; then
  echo "Error: Failed to retrieve login page URL."
  exit 1
fi
debug_log "Login page URL: $LOGIN_PAGE_URL"

# Construct login URL
LOGIN_URL=$(echo "$LOGIN_PAGE_URL" | awk -F \? '{print $1}')
LOGIN_URL="${LOGIN_URL/index.jsp/InterFace.do?method=login}"
if [ -z "$LOGIN_URL" ]; then
  echo "Error: Failed to construct login URL."
  exit 1
fi
debug_log "Login URL: $LOGIN_URL"

# Construct query string
QUERY_STRING=$(echo "$LOGIN_PAGE_URL" | awk -F \? '{print $2}')
QUERY_STRING="${QUERY_STRING//&/%2526}"
QUERY_STRING="${QUERY_STRING//=/%253D}"
if [ -z "$QUERY_STRING" ]; then
  echo "Error: Failed to construct query string."
  exit 1
fi
debug_log "Query string: $QUERY_STRING"

# Perform authentication
debug_log "Sending authentication request..."
AUTH_RESULT=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.91 Safari/537.36" \
  -e "$LOGIN_PAGE_URL" \
  -b "EPORTAL_COOKIE_USERNAME=; EPORTAL_COOKIE_PASSWORD=; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_SERVER_NAME=; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=; EPORTAL_COOKIE_OPERATORPWD=;" \
  -d "userId=${USERNAME}&password=${PASSWORD}&service=&queryString=${QUERY_STRING}&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
  -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
  "$LOGIN_URL")

# Check authentication result
if [ -n "$AUTH_RESULT" ]; then
  echo "Authentication Result: $AUTH_RESULT"
else
  echo "Error: Authentication request failed."
  exit 1
fi
