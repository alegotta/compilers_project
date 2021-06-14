%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include "sym_table.c"

extern FILE *yyin;
extern int yylex();
void yyerror();
elem **add_variable(elem* variables[], elem* variable);
values* create_value();

%}

/*** Tokens declaration with respective types ***/
%union {
       char* lexeme;			//identifier
       int i_value;	     		//value of an identifier of type INT
       double d_value;			//value of an identifier of type NUM
       bool b_value;			//value of an identifier of type BOOLEAN
       char c_value;    		//value of an identifier of type CHARACTER
       char* s_value;			//value of an identifier of type STRING
       values* value;
       elem** variables;		//value of an identifier of type ELEM[]
       elem* element;    		//value of an identifier of type ELEM
}

%token <i_value> INTEGER
%token <d_value> NUM
%token <b_value> BOOLEAN
%token <c_value> CHARACTER
%token <s_value> CHARARRAY

%token INT FLOAT CHAR BOOL STRING IF ELSE WHILE CASE FOR SWITCH CONTINUE BREAK DEFAULT RETURN PLUS MINUS MUL DIV AND OR NOT EQUAL GEQ SEQ GREATER SMALLER LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE SEMICOLON COLON DOT COMMA ASSIGN
%token <lexeme> ID

%type <s_value> type
%type <variables> names
%type <element> variable assignment
%type <value> constant expression paren_expression


/** Associativity Rules **/
%left COMMA
%right ASSIGN
%left OR
%left AND
%left EQUAL
%left GEQ SEQ GREATER SMALLER
%left PLUS MINUS
%left MUL DIV
%right NOT
%left LPAREN RPAREN LBRACK RBRACK

/* Specification of the initial rule */
%start program


%%


/*** Syntax Rules ***/

program: declarations statements | declarations | statements | /* empty*/ ;


/** Declaration of variables **/
declarations: declarations declaration | declaration {printf("dec1\n"); } ;
type:  INT { $$ = "INT"; printf("INT\n"); }
     | CHAR { $$ = "CHAR"; }
     | FLOAT { $$ = "FLOAT"; }
     | STRING { $$ = "STRING"; }
     | BOOL { $$ = "BOOL"; } ;
declaration: type names SEMICOLON
             {
                printf("DECLARATION\n");
                elem** variables = $2;
                int size = sizeof(variables)/sizeof(variables[0]);
                printf("SizeD: %d\n", size);
                for(int i=0; i<size;i++) {
                    elem* variable = variables[i];
                    printf("va: %s\n", variables[i]->name);
                    char* data_type = (char*) $1;
                    set_type(variable, data_type);
                }
             } ;
names:   names COMMA variable { $$ = add_variable($1, $3); }
       | names COMMA assignment { $$ = add_variable($1, $3); }
       | variable { $$ = add_variable(NULL, $1); }
       | assignment { $$ = add_variable(NULL, $1); }
       ;

variable: ID { elem* el = lookup(NULL,$1); printf("LOOK\n"); $$ = el; } ;

/* Declaration of constants */
constant:  INTEGER { values* value = create_value(); value->i_value=$1; printf("VAL: %d %c \n",value->i_value, value->c_value); $$ = value; }
          | NUM { values* value = create_value(); value->f_value=$1; $$ = value; }
          | CHARACTER { values* value = create_value(); value->c_value=$1; $$ = value; }
          | BOOLEAN { values* value = create_value(); value->b_value=$1; $$ = value; }
          | CHARARRAY { values* value = create_value(); value->s_value=$1; $$ = value; }
          ;

assignment: variable ASSIGN constant
       {
         elem* item = $1;
         values *val = $3;
         item->value = val;
         $$ = item;
       } ;

/* Arithmetical and Logical expressions */
expression:
    expression PLUS expression {get_result_type($1,$3,$2);}  |
    expression MINUS expression   |
    expression MUL expression     |
    expression DIV expression     |
    expression OR expression      |
    expression AND expression     |
    NOT expression { $$ = $2; }   |
    expression EQUAL expression   |
    expression GEQ expression     |
    expression SEQ expression     |
    expression GREATER expression |
    expression SMALLER expression |
    paren_expression              |
    variable { $$ = $1->value;}   |
    constant
   ;
paren_expression: LPAREN expression RPAREN { $$ = $2; } ;

/** Control-Flow Statements **/
statements: statements statement | statement ;
statement:
    if_statement | for_statement | while_statement | switch_statement | assignment SEMICOLON |
    CONTINUE SEMICOLON | BREAK SEMICOLON
    ;
brace_statements: LBRACE statements RBRACE ;

// Switch-case
switch_statement: SWITCH LPAREN variable RPAREN LBRACE cases default RBRACE ;
cases: cases case | case ;
case: CASE constant COLON statements BREAK SEMICOLON ;
default : DEFAULT COLON statements SEMICOLON | /* empty */ ;

// If
if_statement:
    IF paren_expression brace_statements else_if else |
    IF paren_expression brace_statements else
    ;
else_if:
    else_if ELSE IF paren_expression brace_statements |
    ELSE IF paren_expression brace_statements
    ;
else: ELSE brace_statements | /* empty */ ;

// For
for_statement: FOR LPAREN assignment SEMICOLON expression SEMICOLON expression RPAREN brace_statements ;

//While
while_statement: WHILE paren_expression brace_statements ;


%%

values* create_value() {
    values* value = malloc(sizeof(values));
    value->i_value = 0;
    value->c_value = '0';
    value->s_value = "0";
    value->f_value = 0.0;
    value->b_value = false;

    return value;
}

elem **add_variable(elem** variables, elem* variable) {
    int size = 0;
    if (variables != NULL)
        size = sizeof(variables)/sizeof(variables[0]);

    printf("size: %d\n", size);
    elem **new_array = realloc(variables, (size+1) * sizeof(elem));
    for(int i=0;i<size;i++) {
        new_array[i] = variables[i];
    }
    new_array[size] = variable;

    printf("NAME: %s\n", new_array[0]->name);

    return new_array;
}

void type_error(int first_type, int second_type, int operation_type) {
	fprintf(stderr, "Type conflict between %d and %d using op type %d\n", first_type, second_type, operation_type);
	exit(1);
}

int get_result_type(int first_type, int second_type, int operation_type) {
    switch(operation_type) {
        case ASSIGN:
            if (first_type == second_type)
                return 1;
            else
                type_error(first_type, second_type, operation_type);
            break;

        case PLUS:
        case MINUS:
        case MUL:
        case DIV:
            if (first_type==INT && second_type==INT)
                return INT;
            else if (first_type==CHAR && second_type==CHAR)
                return CHAR;
            else if ((first_type==INT && second_type==FLOAT) || (first_type==FLOAT && second_type==INT) || (first_type==FLOAT && second_type==FLOAT))
                return FLOAT;
            else
                type_error(first_type, second_type, operation_type);
            break;

        case AND:
        case OR:
            if (first_type==BOOL && second_type==BOOL)
                return BOOL;
            else
                type_error(first_type, second_type, operation_type);
            break;
        case NOT:
            if (first_type==BOOL)       // TODO: Handle !=
                return BOOL;
            else
                type_error(first_type, second_type, operation_type);
            break;
        case GEQ:
        case SEQ:
        case GREATER:
        case SMALLER:
        case EQUAL:
            if (
                (first_type==INT && second_type==FLOAT)   ||
                (first_type==FLOAT && second_type==INT)   ||
                (first_type==FLOAT && second_type==FLOAT) ||
                (first_type==INT && second_type==INT)
               )
                return BOOL;
            else
                type_error(first_type, second_type, operation_type);
            break;
        default: /* wrong choice case */
            fprintf(stderr, "Error in operator selection!\n");
            exit(1);
    }
}

int main(int argc, char *argv[]) {
    printf("--Formal Languages and Compilers--\n           Group Project\n");

    init_table();

    yyin = stdin;

    if(argv[1] != NULL) {
        printf("Reading file...\n");
        yyin = fopen(argv[1], "r");
        int parse_ret = yyparse();
        fclose(yyin);
        print_table(NULL);
        printf("Return: %d\n", parse_ret);
        return parse_ret;
    } else {
        printf("Please type some input...\n");
        return yyparse();
    }
}
