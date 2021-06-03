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

%token INT FLOAT CHAR BOOL STRING IF ELSE WHILE CASE FOR SWITCH CONTINUE BREAK DEFAULT RETURN PLUS MINUS MUL DIV AND OR NOT EQUAL GEQ SEQ GREATER SMALLER LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE SEMI COLON DOT COMMA ASSIGN
%token <lexeme> ID


 /* %type <value> line */

%left '-' '+'
%left '*' '/'
%right UMINUS

%start program

%%

program: declarations statements RETURN SEMI ;

/* declarations */
declarations: declarations declaration | declaration;
declaration: type names SEMI ;
type: INT | CHAR | FLOAT | STRING | BOOL;
names: names COMMA variable | names COMMA init | variable | init ;

variable: ID
;


init : ID ASSIGN constant;
values: values COMMA constant | constant ;



/* statements */
statements: statements statement | statement ;
cases: cases case | case ;

case:
  CASE constant COLON statements BREAK SEMI | CASE constant COLON statements BREAK SEMI DEFAULT COLON statements SEMI;

statement:
	if_statement | for_statement | while_statement | switch_statement | assignment SEMI |
	CONTINUE SEMI | BREAK SEMI
;

if_statement:
	IF LPAREN expression RPAREN tail else_if optional_else |
	IF LPAREN expression RPAREN tail optional_else
;

else_if:
	else_if ELSE IF LPAREN expression RPAREN tail |
	ELSE IF LPAREN expression RPAREN tail
;

optional_else: ELSE tail | /* empty */ ;

switch_statement:
  SWITCH LPAREN variable RPAREN LBRACE cases RBRACE;

for_statement: FOR LPAREN assignment SEMI expression SEMI expression RPAREN tail ;

while_statement: WHILE LPAREN expression RPAREN tail ;

tail: LBRACE statements RBRACE ;

expression:
    expression PLUS expression |
    expression MINUS expression |
    expression MUL expression |
    expression DIV expression |
    expression OR expression |
    expression AND expression |
    NOT expression |
    expression EQUAL expression |
    expression GEQ expression |
    expression SEQ expression |
    expression GREATER expression |
    expression SMALLER expression |
    LPAREN expression RPAREN |
    variable | constant
;


constant: INTEGER | NUM | CHARACTER | BOOLEAN | CHARARRAY ;

assignment: variable ASSIGN expression ;



%%
#include "lex.yy.c"
