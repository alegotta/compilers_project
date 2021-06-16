%option noyywrap
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdbool.h>
#include <string.h>
#include "sym_table.h"
#include "y.tab.h"

int number_line = 1;
extern bool debug;
const char* get_token_name(int token);

int yylex();
void yyerror(char* str, ...);
void debug_print(const char* token);
void debug_token(int token);



/** Regular Expressions declaration **/
// ANY_CHARACTER recognizes all printable character (from ' ' to '~')
// COMMENTS recognizes a whole line starting with //
%}

DIGIT          [0-9]
INT_LITERAL    {DIGIT}+
REAL_LITERAL   {DIGIT}+(\.{DIGIT}+)?
ANY_CHARACTER  [ -~]
CHAR_LITERAL   '{ANY_CHARACTER}'
STRING_LITERAL \"{ANY_CHARACTER}*\"
BOOL_LITERAL   true|false

LETTER         [a-zA-Z_]
ID             {LETTER}({LETTER}|{DIGIT})*

COMMENTS       \/\/.*


%%

{COMMENTS}  { debug_print("COMMENTS"); }

"int"      { yylval.identifier = INT_TYPE; debug_token(INT); return INT; }
"float"    { yylval.identifier = REAL_TYPE; debug_token(FLOAT); return FLOAT; }
"char"     { yylval.identifier = CHAR_TYPE; debug_token(CHAR); return CHAR; }
"bool"     { yylval.identifier = BOOL_TYPE; debug_token(BOOL); return BOOL; }
"string"   { yylval.identifier = STRING_TYPE; debug_token(STRING); return STRING; }

"if"       { yylval.identifier = IF;  debug_token(IF); return IF; }
"else"     { yylval.identifier = ELSE;  debug_token(ELSE); return ELSE; }
"while"    { yylval.identifier = WHILE;  debug_token(WHILE); return WHILE; }
"case"     { debug_token(CASE); return CASE; }
"for"      { yylval.identifier = FOR;  debug_token(FOR); return FOR; }
"switch"   { debug_token(SWITCH); return SWITCH; }
"continue" { debug_token(CONTINUE); return CONTINUE; }
"break"    { debug_token(BREAK); return BREAK; }
"default"  { debug_token(DEFAULT); return DEFAULT; }
"return"   { debug_token(RETURN); return RETURN; }

"+"   { yylval.identifier = PLUS; debug_token(PLUS); return PLUS; }
"-"   { yylval.identifier = MINUS; debug_token(MINUS); return MINUS; }
"*"   { yylval.identifier = MUL;  debug_token(MUL); return MUL; }
"/"   { yylval.identifier = DIV; debug_token(DIV); return DIV; }
"%"   { yylval.identifier = MOD; debug_token(MOD); return MOD; }
"&&"  { yylval.identifier = AND; debug_token(AND); return AND;}
"||"  { yylval.identifier = OR; debug_token(OR); return OR; }
"!"   { yylval.identifier = NOT; debug_token(NOT); return NOT; }
"=="  { yylval.identifier = EQUAL; debug_token(EQUAL); return EQUAL; }
">="  { yylval.identifier = GEQ; debug_token(GEQ); return GEQ; }
"<="  { yylval.identifier = SEQ; debug_token(SEQ); return SEQ; }
">"   { yylval.identifier = GREATER; debug_token(GREATER); return GREATER; }
"<"   { yylval.identifier = SMALLER; debug_token(SMALLER); return SMALLER; }

"("   { debug_token(LPAREN); return LPAREN; }
")"   { debug_token(RPAREN); return RPAREN; }
"{"   { debug_token(LBRACE); return LBRACE; }
"}"   { debug_token(RBRACE); return RBRACE; }
";"   { debug_token(SEMICOLON); return SEMICOLON; }
":"   { debug_token(COLON); return COLON; }

","   { debug_token(COMMA); return COMMA; }
"="   { yylval.identifier = ASSIGN; debug_token(ASSIGN); return ASSIGN; }


{INT_LITERAL}    {  yylval.element = insert_temp_element(number_line);
                    set_element_type(yylval.element,INT_TYPE);
                    yylval.element->value->i_value = atoi(yytext);
                    debug_token(INT_LITERAL); return INT_LITERAL;
                  }
{REAL_LITERAL}    { yylval.element = insert_temp_element(number_line);
                   set_element_type(yylval.element,REAL_TYPE);
                   yylval.element->value->f_value = atof(yytext);
                   debug_token(REAL_LITERAL); return REAL_LITERAL;
                 }
{CHAR_LITERAL}   { yylval.element = insert_temp_element(number_line);
                   set_element_type(yylval.element,CHAR_TYPE);
                   yylval.element->value->c_value = yytext[1];   //Use index 1 because index 0 is the ' symbol
                   debug_token(CHAR_LITERAL); return CHAR_LITERAL;
                 }
{BOOL_LITERAL}   { yylval.element = insert_temp_element(number_line);
                   set_element_type(yylval.element,BOOL_TYPE);
                   (strcmp(yytext, "true") == 0) ? (yylval.element->value->b_value=true) : (yylval.element->value->b_value=false);
                   debug_token(BOOL_LITERAL); return BOOL_LITERAL;
                 }
{ID}             { elem* el = create_element(strdup(yytext), number_line);
                   yylval.element = el;
                   debug_token(ID); return ID;
                 }
{STRING_LITERAL} { yylval.element = insert_temp_element(number_line);
                   set_element_type(yylval.element,STRING_TYPE);
                   yylval.element->value->s_value = malloc(yyleng * sizeof(char));
                   strcpy(yylval.element->value->s_value, yytext);  debug_token(STRING_LITERAL); return STRING_LITERAL;
                 }

[ \t\r\f]+  { /* skip spaces */ }
\n          { number_line+=1; }
.           { yyerror("Unrecognized character: %s", yytext); }

%%

/** C functions to print debug information to screen **/

void debug_print(const char* token) {
    if (debug==true)
        printf(" FLEX: Line %2d: token %s for text %s\n", number_line, token, yytext);
}

void debug_token (int token) {
    const char* token_str = get_token_name(token);
    debug_print(token_str);
}

//Print the error to string and terminate the program. Note that the function is an extension over printf
void yyerror (char* str, ...) {
    va_list varlist;
    va_start (varlist, str);

    fprintf(stderr, "\nFatal error on line %d: ", number_line);
    vfprintf (stderr, str, varlist);
    fprintf(stderr, "\n");

    va_end (varlist);

    print_table();

    exit(1);
}
