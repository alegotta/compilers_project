%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdbool.h>
#include <string.h>
#include "sym_table.c"
#include "type_checking.c"

//Functions and variables defined in LEX
extern FILE *yyin;
extern int yylex();
extern int number_line;
extern void yyerror(char* str, ...);

bool debug = true;
int names = 0;
const char * const* token_table;

void print_debug(char* str, ...);
elem **add_variable_to_list(elem** variables, elem* variable, int size);
values* create_value();
elem* get_expression_result(elem* first, elem* second, int operation_type);
%}

/*** Tokens declaration with respective types ***/
%union {
       char* lexeme;			//identifier
       int i_value;	     		//value of an identifier of type INT
       double d_value;			//value of an identifier of type REAL
       bool b_value;			//value of an identifier of type BOOLEAN
       char c_value;    		//value of an identifier of type CHARACTER
       char* s_value;			//value of an identifier of type STRING
       values* value;
       elem** variables;		//value of an identifier of type ELEM[]
       elem* element;    		//value of an identifier of type ELEM
}

%token <i_value> INTEGER
%token <d_value> REAL
%token <b_value> BOOLEAN
%token <c_value> CHARACTER
%token <s_value> CHARARRAY
%token <lexeme> ID
%token <i_value> PLUS MINUS MUL DIV MOD AND OR NOT EQUAL GEQ SEQ GREATER SMALLER ASSIGN
%token INT FLOAT CHAR BOOL STRING IF ELSE WHILE CASE FOR SWITCH CONTINUE BREAK DEFAULT RETURN LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE SEMICOLON COLON DOT COMMA

%type <i_value> type
%type <variables> names
%type <element> variable assignment expression paren_expression constant return

/** Associativity Rules **/
%left COMMA
%right ASSIGN
%left OR
%left AND
%left EQUAL
%left GEQ SEQ GREATER SMALLER
%left PLUS MINUS MOD
%left MUL DIV
%right NOT
%left LPAREN RPAREN LBRACK RBRACK

/* Specification of the initial rule */
%start program


%%


/*** Syntax Rules ***/

program:   function_body return { printf("\n\nParsed Successfully! Return "); print_value($2); YYACCEPT; }
         | return { printf("\n\nParsed Successfully! Return "); print_value($1); YYACCEPT; /*TODO: Print different data types*/ }
         ;
return:    RETURN expression SEMICOLON { $$ = $2; }
         | RETURN SEMICOLON { elem* ret = enter_temp_with_value(NULL, number_line);    //Assign a return of 0
                              ret->value->i_value = 0;
                              $$ = ret;
                            }
         ;
function_body: declarations statements | statements | declarations ;

/** Declaration of variables **/
declarations: declarations declaration | declaration ;
declaration: type names SEMICOLON
             {
                elem** variables = $2;

                for(int i=0; i<names;i++) {  //Set the data type for all variables in the names list
                    elem* variable = variables[i];
                    int data_type = $1;

                    print_debug("declaration of %s %s", get_type_string(data_type), variables[i]->name);

                    if (variable->type != UNKNOWN_TYPE)
                        get_exp_result_type(data_type, variable->type, ASSIGN);     //An initializer is present: check that types are compatible
                    set_type(variable, data_type);
                }
             } ;
type:  INT    { $$ = INT_TYPE; }
     | CHAR   { $$ = CHAR_TYPE; }
     | FLOAT  { $$ = REAL_TYPE; }
     | STRING { $$ = STRING_TYPE; }
     | BOOL   { $$ = BOOL_TYPE; }
     ;
names:   names COMMA variable { $$ = add_variable_to_list($1, $3, ++names); }
       | names COMMA assignment { $$ = add_variable_to_list($1, $3, ++names); }
       | variable { $$ = add_variable_to_list(NULL, $1, 1); }
       | assignment { $$ = add_variable_to_list(NULL, $1, 1); }
       ;

variable: ID { elem* el = lookup(NULL,$1); if (el == NULL) yyerror("Variable not declared!"); $$ = el; } ;

constant:   MINUS INTEGER { elem* temp = enter_temp_with_value(NULL, number_line); set_type(temp,INT_TYPE); temp->value->i_value=-$2; $$ = temp; }
          | MINUS REAL { elem* temp = enter_temp_with_value(NULL, number_line); set_type(temp,REAL_TYPE);  temp->value->f_value=-$2; $$ = temp; }
          | INTEGER { elem* temp = enter_temp_with_value(NULL, number_line); set_type(temp,INT_TYPE);  temp->value->i_value=$1; $$ = temp; }
          | REAL { elem* temp = enter_temp_with_value(NULL, number_line); set_type(temp,REAL_TYPE);  temp->value->f_value=$1; $$ = temp; }
          | CHARACTER { elem* temp = enter_temp_with_value(NULL, number_line); set_type(temp,CHAR_TYPE);  temp->value->c_value=$1; $$ = temp; }
          | BOOLEAN { elem* temp = enter_temp_with_value(NULL, number_line); set_type(temp,BOOL_TYPE);  temp->value->b_value=$1; $$ = temp; }
          | CHARARRAY { elem* temp = enter_temp_with_value(NULL, number_line); set_type(temp,STRING_TYPE);  temp->value->s_value=$1; $$ = temp; }
          ;

assignment: variable ASSIGN expression
       {
         //Assign the expression value to the corresponding variable
         elem* item = $1;
         elem* exp = $3;
         set_type(item, exp->type);    //The check between exp->type and item->type is done in the 'declaration' rule
         item->value = exp->value;

         print_debug("Assigned value of temp variable %s to variable %s", exp->name, item->name);

         $$ = item;
       } ;

/* Arithmetical and Logical expressions */
expression:
    expression PLUS expression    { $$ = get_expression_result($1,$3,$2); } |
    expression MINUS expression   { $$ = get_expression_result($1,$3,$2); } |
    expression MUL expression     { $$ = get_expression_result($1,$3,$2); } |
    expression DIV expression     { $$ = get_expression_result($1,$3,$2); } |
    expression MOD expression     { $$ = get_expression_result($1,$3,$2); } |
    expression OR expression      { $$ = get_expression_result($1,$3,$2); } |
    expression AND expression     { $$ = get_expression_result($1,$3,$2); } |
    NOT expression                { $$ = get_expression_result($2,$2,$1); } |
    expression EQUAL expression   { $$ = get_expression_result($1,$3,$2); } |
    expression GEQ expression     { $$ = get_expression_result($1,$3,$2); } |
    expression SEQ expression     { $$ = get_expression_result($1,$3,$2); } |
    expression GREATER expression { $$ = get_expression_result($1,$3,$2); } |
    expression SMALLER expression { $$ = get_expression_result($1,$3,$2); } |
    paren_expression              { $$=$1; }                                |
    variable                      { if ($1->value == NULL) yyerror("Variable %s not declared!", $1->name); } |
    constant                      { $$=$1; }
   ;
paren_expression: LPAREN expression RPAREN { $$=$2; } ;

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


//Given a list of variables, append a new variable to it.
//This is used for the 'names' rule, for example in the case 'int i=0, j=2;'
elem **add_variable_to_list(elem** variables, elem* variable, int size) {
    if (size == 1)
        names = 1;

    elem **new_array;
    if (variables == NULL)
        new_array = malloc(sizeof(elem));
    else
        new_array = realloc(variables, names*sizeof(elem));

    new_array[names-1] = variable;

    return new_array;
}

void print_debug(char* str, ...) {
    if (debug==true) {
        va_list varlist;
        printf(" YACC: ");
        va_start (varlist, str);
        vprintf (str, varlist);
        va_end (varlist);
        printf("\n");
    }
}

//Returns a stream to the file, if it exists, or to standard input
FILE* get_input_stream(char* path) {
    FILE* stream;

    if(path != NULL) {
    printf("Reading file...\n");
    stream = fopen(path, "r");

        if (stream == NULL) {
            printf("File does not exist!\n");
            exit(1);
        }
    } else {
        printf("Please type some input, or 'return;' to terminate...\n\n");
        stream = stdin;
    }
    return stream;
}

int main(int argc, char *argv[]) {
    printf("--Formal Languages and Compilers--\n           Group Project\n\n");

    init_table();
    token_table = yytname;  //yytname is an internal yacc variable holding the token table. This assignment is needed to access it from LEX

    FILE* stream = get_input_stream(argv[1]);
    yyin = stream;          //yyin is an internal yacc variable

    int parse_ret = yyparse();
    fclose(yyin);

    printf("\n");

    print_table(NULL);
    remove_table(NULL);

    return parse_ret;
}
