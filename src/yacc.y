%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdbool.h>
#include <string.h>
#include "globals.h"
#include "sym_table.c"
#include "type_checking.c"

//Useful global variables
bool verbose = false;
int variables_list_count = 1;

//Functions prototypes
void print_verbose(char* str, ...);
elem **add_variable_to_list(elem** variables, elem* variable, int size);
const char* get_token_name(int token);
void print_verbose(char* str, ...);
FILE* get_input_stream(char* path);
void resolve_console_params(int argc, char *argv[]);

%}

/*** Tokens declaration with respective types ***/
%union {
    int identifier;         //Internal code assigned by YACC to the various tokens, needed for the type_checking file in order to check the kind of operation
    elem** variables;       //An array of elements (see the struct definition if sym_table.h)
    elem* element;          //One element in the symbol table
}

%token <identifier> INT FLOAT CHAR BOOL STRING PLUS MINUS MUL DIV MOD AND OR NOT EQUAL GEQ SEQ GREATER SMALLER ASSIGN IF ELSE WHILE FOR
%token <element> ID INT_LITERAL REAL_LITERAL BOOL_LITERAL CHAR_LITERAL STRING_LITERAL
%token CASE SWITCH BREAK DEFAULT RETURN LPAREN RPAREN LBRACE RBRACE SEMICOLON COLON COMMA

%type <identifier> type
%type <variables> variables_list
%type <element> variable initialization assignment expression paren_expression constant return

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
%left LPAREN RPAREN

/* Specification of the initial rule */
%start start


%%


/*** Syntax Rules ***/

start:  function_body return {
    print_verbose("Final table:");
    print_table();
    printf("\nParsed Successfully! Return ");
    print_value($2);
    YYACCEPT;     //YYACCEPT terminates YACC successfully
} ;

return:    RETURN expression SEMICOLON { $$ = $2; }
         | RETURN SEMICOLON            { $$ = create_element("return", number_line); }
         | /* empty */                 { yyerror("Missing return statement!");       }
         ;
function_body: declarations statements | statements | declarations | /* empty */;


/** Declaration of variables **/
//-------------------------------------------------------------------------------------------------------------------------------------------------
declarations: declarations declaration | declaration ;               //Allow one or more declarations
declaration: type variables_list SEMICOLON {
    elem** variables = $2;

    for(int i=0; i<variables_list_count;i++) {                       //Set the data type for all variables in the list. Methods from sym_table.c are used.
        elem* variable = variables[i];
        int expected_data_type = $1;

        print_verbose("declaration of %s %s", get_type_string(expected_data_type), variables[i]->name);

        if (variable->type != UNKNOWN_TYPE)                         //Variable was initialized with some value: check that value type
            check_compatible_type(expected_data_type, variable);    //  is compatible with the declared data type of the variable (see type_checking.c)
        else                                                        //Variable was not initialized (its type is still unknown): set the type
            set_element_type(variable, expected_data_type);
        insert_element(variable);                                   //Add variable to symbol table
    }

} ;
type:  INT    { $$ = $1; }  //Return the type identifier as defined in LEX
     | CHAR   { $$ = $1; }
     | FLOAT  { $$ = $1; }
     | STRING { $$ = $1; }
     | BOOL   { $$ = $1; }
     ;

variables_list:   variables_list COMMA variable       { $$ = add_variable_to_list($1, $3, ++variables_list_count); }
                | variables_list COMMA initialization { $$ = add_variable_to_list($1, $3, ++variables_list_count); }
                | variable                            { $$ = add_variable_to_list(NULL, $1, 1);                    }
                | initialization                      { $$ = add_variable_to_list(NULL, $1, 1);                    }
                ;

variable: ID { $$ = $1; } ;     //Pass the elem entry, as created in LEX

constant:   MINUS INT_LITERAL  { $2->value->i = -$2->value->i; $$ = $2; }   //Invert the sign
          | MINUS REAL_LITERAL { $2->value->f = -$2->value->f; $$ = $2; }
          | INT_LITERAL        { $$ = $1; }    //Pass the elem entry, as created in LEX
          | REAL_LITERAL       { $$ = $1; }
          | CHAR_LITERAL       { $$ = $1; }
          | BOOL_LITERAL       { $$ = $1; }
          | STRING_LITERAL     { $$ = $1; }
          ;

initialization: variable ASSIGN expression {
    elem* item = $1;
    elem* exp = $3;
    item->value = exp->value;               //The check between exp->type and item->type is done in the 'declaration' rule,
    set_element_type(item, exp->type);      // since in this rule we don't have access to the declared item type

    print_verbose("Initialized %s with value of temp variable %s", item->name, exp->name);

    $$ = item;
} ;


/* Arithmetical and Logical expressions */
//-------------------------------------------------------------------------------------------------------------------------------------------------
expression:   expression PLUS expression    { $$ = get_expression_result($1,$3,$2); }   //See the type_checking.c file
            | expression MINUS expression   { $$ = get_expression_result($1,$3,$2); }
            | expression MUL expression     { $$ = get_expression_result($1,$3,$2); }
            | expression DIV expression     { $$ = get_expression_result($1,$3,$2); }
            | expression MOD expression     { $$ = get_expression_result($1,$3,$2); }
            | expression OR expression      { $$ = get_expression_result($1,$3,$2); }
            | expression AND expression     { $$ = get_expression_result($1,$3,$2); }
            | NOT expression                { $$ = get_expression_result($2,$2,$1); }
            | expression EQUAL expression   { $$ = get_expression_result($1,$3,$2); }
            | expression GEQ expression     { $$ = get_expression_result($1,$3,$2); }
            | expression SEQ expression     { $$ = get_expression_result($1,$3,$2); }
            | expression GREATER expression { $$ = get_expression_result($1,$3,$2); }
            | expression SMALLER expression { $$ = get_expression_result($1,$3,$2); }
            | paren_expression              { $$=$1; }
            | constant                      { $$=$1; }
            | variable                      {
                elem* elem = lookup($1->name);      //Get the variable name as it was set in LEX, then perform a lookup (see sym_table.c)
                if (elem==NULL)
                    yyerror("Variable %s not declared!", $1->name);
                else if (elem->value == NULL)
                    yyerror("Variable %s not initialized!", $1->name);
                $$=elem;
            }
            ;
paren_expression: LPAREN expression RPAREN { $$=$2; } ;


/** Control-Flow Statements **/
//   Note that just type checking is preformed, goto and code jumps have not been implemented
//-------------------------------------------------------------------------------------------------------------------------------------------------
statements:  statements statement | statement ;  //Allow one or more statements
statement:   if_statement | for_statement | while_statement | switch_statement
           | assignment SEMICOLON
           ;

brace_statements:   { print_verbose("Creating new symbol table for nested block"); enter_new_block();             }
                  LBRACE function_body RBRACE
                    { print_verbose("Exiting the nested block, here is its table:"); print_table(); exit_block(); }
                  ;


if_statement:   IF paren_expression brace_statements else_if else { print_verbose("If statement recognized"); check_statement_type($2,$1); }  //See type_checking.c
              | IF paren_expression brace_statements else         { print_verbose("If statement recognized"); check_statement_type($2,$1); }
              ;
else_if:   else_if ELSE IF paren_expression brace_statements  { check_statement_type($4,$2); }
         | ELSE IF paren_expression brace_statements          { check_statement_type($3,$1); }
         ;
else: ELSE brace_statements | /* empty */ ;


for_statement: FOR LPAREN declaration expression SEMICOLON assignment RPAREN brace_statements { print_verbose("For statement recognized"); check_statement_type($4,$1); };


while_statement: WHILE paren_expression brace_statements { print_verbose("While statement recognized");  check_statement_type($2,$1); } ;


switch_statement: SWITCH LPAREN variable RPAREN LBRACE cases default RBRACE ;
cases: cases case | case { print_verbose("Switch-Case statement recognized"); } ;
case: CASE constant COLON statements BREAK SEMICOLON ;
default : DEFAULT COLON statements { print_verbose("Switch-Default statement recognized"); } | /* empty */ ;


assignment: variable ASSIGN expression {
    elem* item = lookup($1->name); if (item == NULL) yyerror("Variable %s not declared!", $1->name);
    elem* exp = $3;

    item->value = exp->value;
    get_exp_result_type(item, exp, $2);    //Check that the expression type is compatible with the variable data type

    print_verbose("Assigned value to %s from temp variable %s", item->name, exp->name);

    $$ = item;
} ;


%%


//Given a list of variables, append a new variable to it.
//  This is used for the 'variables_list' rule, for example in the case 'int i=0, j=2;'
elem **add_variable_to_list(elem** variables, elem* variable, int size) {
    if (size == 1)
        variables_list_count = 1;

    elem **new_array;
    if (variables == NULL)
        new_array = malloc(sizeof(elem));
    else
        new_array = realloc(variables, variables_list_count*sizeof(elem));

    new_array[variables_list_count-1] = variable;

    return new_array;
}

// Return the textual representation of the token. yytname is automatically generated by YACC in the .h file
const char* get_token_name(int token) {
    return yytname[token-255];
}

void print_verbose(char* str, ...) {
    if (verbose==true) {
        va_list varlist;
        printf(" YACC: ");
        va_start (varlist, str);
        vprintf (str, varlist);
        va_end (varlist);
        printf("\n");
    }
}

//Returns a stream to the file path, if it exists, or to standard input
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

//Allowed parameters are:
//  --file <file>
//  --verbose
void resolve_console_params(int argc, char *argv[]) {
    if (argc>=2 && strcmp("--file", argv[1]) == 0)
        yyin = get_input_stream(argv[2]);   //yyin is an internal yacc variable
    else
        yyin = stdin;

    if ((argc>=2 && strcmp("--verbose", argv[1]) == 0) || (argc>=4 && strcmp("--verbose", argv[3]) == 0))
        verbose = true;
}

int main(int argc, char *argv[]) {
    printf("-----  Formal Languages and Compilers  Project  -----\n       Alessandro Gottardi and Lucia Maninetti\n\n");

    init_global_table();

    resolve_console_params(argc, argv);

    int parse_ret = yyparse();
    fclose(yyin);

    exit_block();

    printf("\n");
    return parse_ret;
}
