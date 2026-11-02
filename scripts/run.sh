#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

if [ ! -f "$DIR/dist/Reader.app/Contents/MacOS/ReaderMac" ]; then
    bash "$DIR/scripts/build.sh"
fi

echo "==> 启动 Reader for Mac..."
open "$DIR/dist/Reader.app"
