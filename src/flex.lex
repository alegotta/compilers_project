%option noyywrap
%{
#include <stdlib.h>
#include <string.h>
int yylex();
void yyerror(const char *s);
%}

IF       if
ELSE     else
WHILE    while
FOR      for
SWITCH   switch

INT      int
FLOAT    float
CHAR     char
BOOLEAN  bool
EQUAL    ==

GREATER  >
LESS     <
ASSIGN   =

DIGIT    [0-9]
NUM      {DIGIT}+(\.{DIGIT}+)?

LETTER   [a-zA-Z]
ID       {LETTER}({LETTER}|{DIGIT})*

COMMENT  \/\/.*\n



%%

[ ]     { /* skip blanks */ }

{IF}    {return IF;}
{NUM}    {yylval.value = atof(yytext);
          return NUM;}
{ID}     {yylval.lexeme = strdup(yytext);
          return ID;}

"+"     {return '+';}
"-"     {return '-';}
"*"     {return '*';}
"/"     {return '/';}
\n      {return '\n';}



%%
