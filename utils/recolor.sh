#!/bin/bash
sed -i -e 's/fill:#\(111\|111111\)/fill:#111111;fill-opacity:0.0/g' "$1"
sed -i -e 's/fill:#\(fff\|ffffff\)/fill:#111111/g' "$1"
sed -i -e 's/stroke:#\(fff\|ffffff\)/stroke:#111111/g' "$1"
sed -i -e 's/stroke:#\(eee\|eeeeee\)/stroke:#eeeeee;stroke-opacity:0.0/g' "$1"
