%option noyywrap
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdarg.h>
#include "sym_table.h"
#include "y.tab.h"

int number_line = 1;
extern bool debug;
extern FILE *yyin;
extern const char ** token_table;

int yylex();
void yyerror(char* str, ...);
void debug_print(const char* token);
void debug_token(int token);
const char* token_name(int t);
%}


DIGIT     [0-9]
INTEGER   {DIGIT}+
NUM      {DIGIT}+(\.{DIGIT}+)?
ANY_CHARACTER [ -~]
CHARACTER '{ANY_CHARACTER}'
CHARARRAY \"{ANY_CHARACTER}*\"
BOOLEAN   true|false

LETTER   [a-zA-Z_]
ID       {LETTER}({LETTER}|{DIGIT})*

COMMENT  \/\/.*


%%

{COMMENT}  { debug_print("COMMENTS"); }

"int"      { debug_token(INT); return INT; }
"float"    { debug_token(FLOAT); return FLOAT; }
"char"     { debug_token(CHAR); return CHAR; }
"bool"     { debug_token(BOOL); return BOOL; }
"string"   { debug_token(STRING); return STRING; }

"if"       { debug_token(IF); return IF; }
"else"     { debug_token(ELSE); return ELSE; }
"while"    { debug_token(WHILE); return WHILE; }
"case"     { debug_token(CASE); return CASE; }
"for"      { debug_token(FOR); return FOR; }
"switch"   { debug_token(SWITCH); return SWITCH; }
"continue" { debug_token(CONTINUE); return CONTINUE; }
"break"    { debug_token(BREAK); return BREAK; }
"default"  { debug_token(DEFAULT); return DEFAULT; }
"return"   { debug_token(RETURN); return RETURN; }

"+"   { yylval.i_value = PLUS; debug_token(PLUS); return PLUS; }
"-"   { yylval.i_value = MINUS; debug_token(MINUS); return MINUS; }
"*"   { yylval.i_value = MUL;  debug_token(MUL); return MUL; }
"/"   { yylval.i_value = DIV; debug_token(DIV); return DIV; }
"%"   { yylval.i_value = MOD; debug_token(MOD); return MOD; }
"&&"  { yylval.i_value = AND; debug_token(AND); return AND;}
"||"  { yylval.i_value = OR; debug_token(OR); return OR; }
"!"   { yylval.i_value = NOT; debug_token(NOT); return NOT; }
"=="  { yylval.i_value = EQUAL; debug_token(EQUAL); return EQUAL; }
">="  { yylval.i_value = GEQ; debug_token(GEQ); return GEQ; }
"<="  { yylval.i_value = SEQ; debug_token(SEQ); return SEQ; }
">"   { yylval.i_value = GREATER; debug_token(GREATER); return GREATER; }
"<"   { yylval.i_value = SMALLER; debug_token(SMALLER); return SMALLER; }

"("   { debug_token(LPAREN); return LPAREN; }
")"   { debug_token(RPAREN); return RPAREN; }
"]"   { debug_token(RBRACK); return RBRACK; }
"["   { debug_token(LBRACK); return LBRACK; }
"{"   { debug_token(LBRACE); return LBRACE; }
"}"   { debug_token(RBRACE); return RBRACE; }
";"   { debug_token(SEMICOLON); return SEMICOLON; }
":"   { debug_token(COLON); return COLON; }

"."   { debug_token(DOT); return DOT; }
","   { debug_token(COMMA); return COMMA; }
"="   { debug_token(ASSIGN); return ASSIGN; }


{INTEGER}   { yylval.i_value = atoi(yytext);
              debug_token(INTEGER); return INTEGER; }
{NUM}       { yylval.d_value = atof(yytext);
              debug_token(NUM); return NUM; }
{CHARACTER} { yylval.c_value = yytext[1];
              debug_token(ASSIGN); return CHARACTER; }
{BOOLEAN}   { (strcmp(yytext, "true") == 0) ? (yylval.b_value=true) : (yylval.b_value=false);
              debug_token(BOOLEAN); return BOOLEAN; }
{ID}        { elem* el = enter(NULL, strdup(yytext), number_line);
              yylval.lexeme = el->name;
              debug_token(ID); return ID;}
{CHARARRAY} { yylval.s_value = malloc(yyleng * sizeof(char));
              strcpy(yylval.s_value, yytext);  debug_token(CHARARRAY); return CHARARRAY; }

[ \t\r\f]+  { /* skip blanks */ }
\n          { number_line+=1; }
.           { yyerror("Unrecognized character: %s", yytext) ; }

%%

void debug_print(const char* token) {
    if (debug==true) {
        printf("FLEX: Line %2d: token %s for text %s\n", number_line, token, yytext);
    }
}

void debug_token (int token) {
    const char* token_str = token_name(token);
    debug_print(token_str);
}

const char* token_name(int t) {
  return token_table[t -255];
}

void yyerror (char* str, ...) {
    va_list varlist;
    va_start (varlist, str);

    fprintf(stderr, "\nFatal error on line %d: ", number_line);
    vfprintf (stderr, str, varlist);
    fprintf(stderr, "\n");

    va_end (varlist);
    exit(1);
}
