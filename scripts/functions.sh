#!/bin/bash

exist_url() {
    if wget -S --spider "$1" 2>&1 | grep -q 'HTTP/1.1 200 OK'; then
        return 0
    else
        return 1
    fi
}