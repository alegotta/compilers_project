%option noyywrap
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

int number_line = 0;
int yylex();
void yyerror(const char *s);
%}


DIGIT     [0-9]
INTEGER   {DIGIT}+
NUM      {DIGIT}+(\.{DIGIT}+)?
CHARACTER ([a-zA-Z]|{DIGIT})
CHARARRAY {CHARACTER}+
BOOLEAN   true|false

LETTER   [a-zA-Z]
ID       {LETTER}({LETTER}|{DIGIT})*

COMMENT  \/\/.*\n


%%

{COMMENT}  { printf("Comments at line %d\n", ++number_line); }

"int"      { return INT; }
"float"    { return FLOAT; }
"char"     { return CHAR; }
"bool"     { return BOOL; }
"string"   { return STRING; }

"if"       { return IF; }
"else"     { return ELSE; }
"while"    { return WHILE; }
"for"      { return FOR; }
"switch"   { return SWITCH; }
"continue" { return CONTINUE; }
"break"    { return BREAK; }

"+"   { return PLUS; }
"-"   { return MINUS; }
"*"   { return MUL; }
"/"   { return DIV; }
"&&"  { return AND;}
"||"  { return OR; }
"!"   { return NOT; }
"=="  { return EQUAL; }
">="  { return GEQ; }
"<="  { return SEQ; }
">"   { return GREATER; }
"<"   { return SMALLER; }

"("   { return LPAREN; }
")"   { return RPAREN; }
"]"   { return RBRACK; }
"["   { return LBRACK; }
"{"   { return LBRACE; }
"}"   { return RBRACE; }
";"   { return SEMI; }

"."   { return DOT; }
","   { return COMMA; }
"="   { return ASSIGN; }


{INTEGER}   { yylval.i_value = atoi(yytext);
              return INTEGER; }
{NUM}       { yylval.d_value = atof(yytext);
              return NUM; }
{CHARACTER} { yylval.c_value = yytext[0];
              return CHARACTER; }
{BOOLEAN}   { (strcmp(yytext, "true") == 0) ? (yylval.b_value=true) : (yylval.b_value=false);
              return BOOLEAN; }
{ID}        {yylval.lexeme = strdup(yytext);
              return ID;}
{CHARARRAY} { yylval.s_value = malloc(yyleng * sizeof(char));
              strcpy(yylval.s_value, yytext);  return STRING; }


[ \t\r\f]+  { /* skip blanks */ }
\n          { ++number_line; }
.           { yyerror("Unrecognized character %s on line %d\n", yytext, ++number_line); }

%%

int main() {
  printf("--Formal Languages and Compilers--\n           Group Project\n");
  return yylex();
}
