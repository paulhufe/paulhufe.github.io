#!/bin/bash

WEBSITE="/Users/paulhufe/Dropbox/Website"
CV_DIR="$WEBSITE/CV"
LOG="$WEBSITE/cv_sync.log"
CLAUDE="/Users/paulhufe/.local/bin/claude"
PDFLATEX="/Library/TeX/texbin/pdflatex"
BIBER="/Library/TeX/texbin/biber"

notify_error() {
    osascript -e "display notification \"$1 Check cv_sync.log for details.\" with title \"CV Sync Error\""
}

echo "" >> "$LOG"
echo "=== $(date) ===" >> "$LOG"
echo "CV sync triggered" >> "$LOG"

# Compile
cd "$CV_DIR"
rm -f CV.aux CV.bbl CV.bcf CV.blg CV.log CV.out CV.run.xml CV.synctex.gz

if ! "$PDFLATEX" -interaction=nonstopmode CV.tex >> "$LOG" 2>&1; then
    echo "pdflatex pass 1 failed" >> "$LOG"
    notify_error "CV compilation failed (pdflatex pass 1)."
    exit 1
fi

if ! "$BIBER" CV >> "$LOG" 2>&1; then
    echo "biber failed" >> "$LOG"
    notify_error "CV compilation failed (biber)."
    exit 1
fi

if ! "$PDFLATEX" -interaction=nonstopmode CV.tex >> "$LOG" 2>&1; then
    echo "pdflatex pass 2 failed" >> "$LOG"
    notify_error "CV compilation failed (pdflatex pass 2)."
    exit 1
fi

if ! "$PDFLATEX" -interaction=nonstopmode CV.tex >> "$LOG" 2>&1; then
    echo "pdflatex pass 3 failed" >> "$LOG"
    notify_error "CV compilation failed (pdflatex pass 3)."
    exit 1
fi

echo "Compilation successful" >> "$LOG"

# Copy PDF to website
cp "$CV_DIR/CV.pdf" "$WEBSITE/pdfs/cv.pdf"
echo "PDF copied to pdfs/cv.pdf" >> "$LOG"

# Sync research.html using Claude CLI
cd "$WEBSITE"
"$CLAUDE" -p "Read the CV PDF at /Users/paulhufe/Dropbox/Website/pdfs/cv.pdf and compare its Publications, Work in Progress, and Other Writing sections against /Users/paulhufe/Dropbox/Website/research.html. Update research.html to exactly match the CV. Rules: (1) Preserve all existing HTML structure, CSS classes, and formatting — only change paper entry content. (2) For the Wienand et al. Work in Progress entry, use the ⓡ symbol between all author names instead of commas to indicate randomized author order per AEA convention. (3) Maintain existing PDF href links where the paper already exists; leave new entries without links." --allowedTools "Read,Edit" >> "$LOG" 2>&1

if [ $? -ne 0 ]; then
    echo "Claude CLI sync failed" >> "$LOG"
    notify_error "research.html sync failed."
    exit 1
fi

echo "research.html synced" >> "$LOG"

# Commit and push
git add pdfs/cv.pdf research.html
git diff --cached --quiet && echo "No changes to commit" >> "$LOG" && exit 0

git commit -m "Auto-sync CV and research page" >> "$LOG" 2>&1
git push >> "$LOG" 2>&1

if [ $? -ne 0 ]; then
    echo "Git push failed" >> "$LOG"
    notify_error "Git push failed."
    exit 1
fi

echo "Committed and pushed" >> "$LOG"
osascript -e 'display notification "CV and research page updated and pushed." with title "CV Sync"'
