#!/bin/sh

URL="http://10.113.0.253"

love_response=$(curl -s "$URL/tasks" -X POST \
-H 'Content-Type: application/json' \
-d '{"type": "JOIN_NYCU_CSIT"}'
)
echo "Love Response Code: $love_response"

math_response=$(curl -s "$URL/tasks" -X POST \
-H 'Content-Type: application/json' \
-d '{"type": "MATH_SOLVER"}'
)

echo "Math Response Code: $math_response"

caesar_response=$(curl "$URL/tasks" -X POST \
-H 'Content-Type: application/json' \
-d '{"type": "CRACK_PASSWORD"}'
)
echo "Caesar Response Code: $caesar_response"