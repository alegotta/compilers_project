%option noyywrap
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "sym_table.h"
#include "y.tab.h"

int number_line = 1;
bool debug = true;
extern FILE *yyin;

int yylex();
void yyerror();
void debug_print(const char* token);
const char* token_name(int t);
%}


DIGIT     [0-9]
INTEGER   {DIGIT}+
NUM      {DIGIT}+(\.{DIGIT}+)?
ANY_CHARACTER [ -~]
CHARACTER '{ANY_CHARACTER}'
CHARARRAY \"{ANY_CHARACTER}*\"
BOOLEAN   true|false

LETTER   [a-zA-Z]
ID       {LETTER}({LETTER}|{DIGIT})*

COMMENT  \/\/.*


%%

{COMMENT}  { debug_print("COMMENTS"); }

"int"      { return INT; }
"float"    { return FLOAT; }
"char"     { return CHAR; }
"bool"     { return BOOL; }
"string"   { return STRING; }

"if"       { return IF; }
"else"     { return ELSE; }
"while"    { return WHILE; }
"case"     { return CASE; }
"for"      { return FOR; }
"switch"   { return SWITCH; }
"continue" { return CONTINUE; }
"break"    { return BREAK; }
"default"  { return DEFAULT; }
"return"   { return RETURN; }

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
";"   { return SEMICOLON; }
":"   { return COLON; }

"."   { return DOT; }
","   { return COMMA; }
"="   { return ASSIGN; }


{INTEGER}   { yylval.i_value = atoi(yytext);
              return INTEGER; }
{NUM}       { yylval.d_value = atof(yytext);
              return NUM; }
{CHARACTER} { yylval.c_value = yytext[1];
              return CHARACTER; }
{BOOLEAN}   { (strcmp(yytext, "true") == 0) ? (yylval.b_value=true) : (yylval.b_value=false);
              return BOOLEAN; }
{ID}        { elem* el = enter(NULL, strdup(yytext), number_line);
              yylval.lexeme = el->name;
              return ID;}
{CHARARRAY} { yylval.s_value = malloc(yyleng * sizeof(char));
              strcpy(yylval.s_value, yytext);  return CHARARRAY; }

[ \t\r\f]+  { /* skip blanks */ }
\n          { number_line+=1; }
.           { printf("\nFATAL: Unrecognized character on line %d: %s\n", number_line, yytext);
              exit(1); }

%%

void debug_print(const char* token) {
    if (debug==true) {
        printf("FLEX: Line %2d: token %s for text %s\n", number_line, token, yytext);
    }
}

int return_print (int token) {
    const char* token_str = token_name(token);
    debug_print(token_str);
    printf("Returning %d", token);
    return token;
}

const char* token_name(int t) {
  //return yytname[YYTRANSLATE(t)];
  return "c";
}

void yyerror (char const *s) {
   fprintf (stderr, "%s\n", s);
 }
