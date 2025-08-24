#! /bin/bash
waypaper --restore
OLD_PID=$!

while true; do
    sleep 2m
    waypaper --random
    NEXT_PID=$!
    sleep 5
    kill $OLD_PID
    OLD_PID=$NEXT_PID
done
