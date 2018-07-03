#!/bin/bash

git remote add template https://github.com/carpentries/styles.git
git checkout gh-pages
./bin/lesson_initialize.py 
mv CODE_OF_CONDUCT.md CODE_OF_CONDUCT2.md 
./bin/lesson_initialize.py 
git add .
git commit -m "First commit"
git push
