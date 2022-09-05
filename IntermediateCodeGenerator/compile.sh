#!/bin/bash
yacc --defines=y.tab.h -d -y -o $1y.cpp $1.y
echo 'Generated the parser C file as well the header file'
g++ -std=c++17 -Wshadow -Wall -w -c -o $1y.o $1y.cpp
echo 'Generated the parser object file'
flex -o $1l.cpp $1.l
echo 'Generated the scanner C file'
g++ -std=c++17 -Wshadow -Wall -w -c -o $1l.o $1l.cpp
# if the above command doesn't work try g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ $1y.o $1l.o -lfl -o $1
echo 'All ready, running'
./$@
#g++ -std=c++17 -Wshadow -Wall -w -o "%e" "%f" -g -fsanitize=address -fsanitize=undefined -D_GLIBCXX_DEBUG
