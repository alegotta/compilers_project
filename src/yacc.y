%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
%}


%union {
       char* lexeme;			//identifier
       int i_value;	     		//value of an identifier of type INT
       double d_value;			//value of an identifier of type NUM
       bool b_value;			//value of an identifier of type BOOLEAN
       char c_value;    		//value of an identifier of type CHARACTER
       char* s_value;			//value of an identifier of type STRING
       }

%token <i_value> INTEGER
%token <d_value> NUM
%token <b_value> BOOLEAN
%token <c_value> CHARACTER
%token <s_value> CHARARRAY

%token INT FLOAT CHAR BOOL STRING IF ELSE WHILE FOR SWITCH CONTINUE BREAK PLUS MINUS MUL DIV AND OR NOT EQUAL GEQ SEQ GREATER SMALLER LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE SEMI DOT COMMA ASSIGN
%token <lexeme> ID

%type <i_value> expr
 /* %type <value> line */

%left '-' '+'
%left '*' '/'
%right UMINUS

%start line

%%
line  : expr           {printf("Result: %f\n", $1);}
      | line ';' expr  {printf("Result: %f\n", $3);}
      ;
expr  : expr '+' expr  {$$ = $1 + $3;}
      | expr '-' expr  {$$ = $1 - $3;}
      | expr '*' expr  {$$ = $1 * $3;}
      | expr '/' expr  {$$ = $1 / $3;}
      | NUM            {$$ = $1;}
      | '-' expr %prec UMINUS {$$ = -$2;}
      ;

%%

#include "lex.yy.c"
