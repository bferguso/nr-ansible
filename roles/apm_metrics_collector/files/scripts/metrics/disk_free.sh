#!/bin/bash

df -P | \
  jq -R -s '
    {
      disk: [
        split("\n") |
        .[] |
        if test("^/") then
          gsub(" +"; " ") | split(" ") | {mount: .[0], total: .[1], available: .[2]}
        else
          empty
        end
      ]
    }' | \
    jq -c