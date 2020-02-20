#!/bin/bash

exist_url() {
    if wget -S --spider "$1" 2>&1 | grep -q 'HTTP/1.1 200 OK'; then
        return 0
    else
        return 1
    fi
}

# Adapted from https://stackoverflow.com/questions/44810685/how-to-sanitize-a-string-in-bash
sanitize() {
   local s="${1?need a string}" # receive input in first argument
   s="${s//[^[:alnum:]\.]/-}"     # replace all non-alnum characters to -
   s="${s//+(-)/-}"             # convert multiple - to single -
   s="${s/#-}"                  # remove - from start
   s="${s/%-}"                  # remove - from end
   echo "$s"
}