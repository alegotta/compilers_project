%option noyywrap
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

int number_line = 1;
bool debug = true;

int yylex();
void yyerror();
void debug_print(const char* token);
const char* print_return(int token);
const char* token_name(int t);
%}


DIGIT     [0-9]
INTEGER   {DIGIT}+
NUM      {DIGIT}+(\.{DIGIT}+)?
CHARACTER [ -~]
CHARARRAY \"{CHARACTER}*\"
BOOLEAN   true|false

LETTER   [a-zA-Z]
ID       {LETTER}({LETTER}|{DIGIT})*

COMMENT  \/\/.*


%%

{COMMENT}  { debug_print("COMMENTS"); }

"int"      { print_return(INT); }
"float"    { print_return(FLOAT); }
"char"     { print_return(CHAR); }
"bool"     { print_return(BOOL); }
"string"   { print_return(STRING); }

"if"       { print_return(IF); }
"else"     { print_return(ELSE); }
"while"    { print_return(WHILE); }
"case"     { print_return(CASE); }
"for"      { print_return(FOR); }
"switch"   { print_return(SWITCH); }
"continue" { print_return(CONTINUE); }
"break"    { print_return(BREAK); }
"default"  { print_return(DEFAULT); }
"return"   { print_return(RETURN); }

"+"   { print_return(PLUS); }
"-"   { print_return(MINUS); }
"*"   { print_return(MUL); }
"/"   { print_return(DIV); }
"&&"  { print_return(AND);}
"||"  { print_return(OR); }
"!"   { print_return(NOT); }
"=="  { print_return(EQUAL); }
">="  { print_return(GEQ); }
"<="  { print_return(SEQ); }
">"   { print_return(GREATER); }
"<"   { print_return(SMALLER); }

"("   { print_return(LPAREN); }
")"   { print_return(RPAREN); }
"]"   { print_return(RBRACK); }
"["   { print_return(LBRACK); }
"{"   { print_return(LBRACE); }
"}"   { print_return(RBRACE); }
";"   { print_return(SEMICOLON); }
":"   { print_return(COLON); }

"."   { print_return(DOT); }
","   { print_return(COMMA); }
"="   { print_return(ASSIGN); }


{INTEGER}   { yylval.i_value = atoi(yytext);
              print_return(INTEGER); }
{NUM}       { yylval.d_value = atof(yytext);
              print_return(NUM); }
{CHARACTER} { yylval.c_value = yytext[0];
              print_return(CHARACTER); }
{BOOLEAN}   { (strcmp(yytext, "true") == 0) ? (yylval.b_value=true) : (yylval.b_value=false);
              print_return(BOOLEAN); }
{ID}        {yylval.lexeme = strdup(yytext);
              print_return(ID);}
{CHARARRAY} { yylval.s_value = malloc(yyleng * sizeof(char));
              strcpy(yylval.s_value, yytext);  print_return(CHARARRAY); }

[ \t\r\f]+  { /* skip blanks */ }
\n          { number_line+=1; }
.           { printf("On line %d: %s\n", number_line, yytext);
              yyerror("unrecognized character"); }

%%

void debug_print(const char* token) {
    if (debug==true) {
        printf("Line %2d: token %s for text %s\n", number_line, token, yytext);
    }
}

const char* print_return(int token) {
    const char* token_str = token_name(token);
    debug_print(token_str);
    return token_str;
}

const char* token_name(int t) {
  return yytname[YYTRANSLATE(t)];
}
