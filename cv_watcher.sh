#!/bin/bash
# Watches CV.tex and triggers sync on every change

CV_TEX="/Users/paulhufe/Dropbox/Website/CV/CV.tex"
SYNC="/Users/paulhufe/Dropbox/Website/sync_cv.sh"

/opt/homebrew/bin/fswatch --event=Updated --event=Created -o "$CV_TEX" | while read -r count; do
    echo "$(date): CV.tex change detected, running sync..." >> /Users/paulhufe/Dropbox/Website/cv_sync.log
    /bin/bash "$SYNC"
done
