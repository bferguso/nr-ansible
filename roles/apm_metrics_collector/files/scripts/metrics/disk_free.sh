#!/bin/bash

df -P | \
  /sw_ux/bin/jq -R -s '
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
    /sw_ux/bin/jq -c