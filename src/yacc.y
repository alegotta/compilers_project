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

bool debug = false;
int variables_list_count = 1;

void print_debug(char* str, ...);
elem **add_variable_to_list(elem** variables, elem* variable, int size);
values* create_value();
elem* get_expression_result(elem* first, elem* second, int operation_type);
%}

/*** Tokens declaration with respective types ***/
%union {
    int identifier;         //Internal code assigned by YACC to the various tokens
    elem** variables;       //A list of elements
    elem* element;          //One element in the symbol table
}

%token <identifier> INT FLOAT CHAR BOOL STRING PLUS MINUS MUL DIV MOD AND OR NOT EQUAL GEQ SEQ GREATER SMALLER ASSIGN IF ELSE WHILE FOR
%token <element> ID INT_LITERAL REAL_LITERAL BOOL_LITERAL CHAR_LITERAL STRING_LITERAL
%token CASE SWITCH CONTINUE BREAK DEFAULT RETURN LPAREN RPAREN LBRACE RBRACE SEMICOLON COLON COMMA

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
%left LPAREN RPAREN LBRACK RBRACK

/* Specification of the initial rule */
%start program


%%


/*** Syntax Rules ***/

program:   function_body return { print_debug("Final table:"); print_table(); printf("\nParsed Successfully! Return "); print_value($2); YYACCEPT; }  //YYACCEPT terminates YACC successfully
         | return               { print_debug("Final table:"); print_table(); printf("\nParsed Successfully! Return "); print_value($1); YYACCEPT; }
         ;
return:    RETURN expression SEMICOLON { $$ = $2; }
         | RETURN SEMICOLON            { $$ = create_element("return", number_line); }
         ;
function_body: declarations statements | statements | declarations ;


/** Declaration of variables **/
//-------------------------------------------------------------------------------------------------------------------------------------------------
declarations: declarations declaration | declaration ;
declaration: type variables_list SEMICOLON {
    elem** variables = $2;

    for(int i=0; i<variables_list_count;i++) {  //Set the data type for all variables in the list
        elem* variable = variables[i];
        int expected_data_type = $1;

        print_debug("declaration of %s %s", get_type_string(expected_data_type), variables[i]->name);

        if (variable->type != UNKNOWN_TYPE)                                     //Variable was initialized with some value: check that value type
            get_exp_result_type(expected_data_type, variable->type, ASSIGN);    //  is compatible with the data type of the variable
        else
            set_element_type(variable, expected_data_type);
        insert_element(variable);                                               //Add variable to symbol table
    }
} ;
type:  INT    { $$ = $1; }
     | CHAR   { $$ = $1; }
     | FLOAT  { $$ = $1; }
     | STRING { $$ = $1; }
     | BOOL   { $$ = $1; }
     ;
variables_list:   variables_list COMMA variable       { $$ = add_variable_to_list($1, $3, ++variables_list_count); }
                | variables_list COMMA initialization { $$ = add_variable_to_list($1, $3, ++variables_list_count); }
                | variable                            { $$ = add_variable_to_list(NULL, $1, 1); }
                | initialization                      { $$ = add_variable_to_list(NULL, $1, 1); }
                ;

variable: ID { $$ = $1; } ;

constant:   MINUS INT_LITERAL  { $2->value->i_value = -$2->value->i_value; $$ = $2; }
          | MINUS REAL_LITERAL { $2->value->f_value = -$2->value->f_value; $$ = $2; }
          | INT_LITERAL        { $$ = $1; }
          | REAL_LITERAL       { $$ = $1; }
          | CHAR_LITERAL       { $$ = $1; }
          | BOOL_LITERAL       { $$ = $1; }
          | STRING_LITERAL     { $$ = $1; }
          ;

initialization: variable ASSIGN expression {
    //Assign the expression value to the corresponding variable
    elem* item = $1;
    elem* exp = $3;
    set_element_type(item, exp->type);    //The check between exp->type and item->type is done in the 'declaration' rule
    item->value = exp->value;

    print_debug("Initialized %s with value of temp variable %s", item->name, exp->name);

    $$ = item;
} ;


/* Arithmetical and Logical expressions */
//-------------------------------------------------------------------------------------------------------------------------------------------------
expression:   expression PLUS expression    { $$ = get_expression_result($1,$3,$2); }
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
                elem* elem = lookup($1->name);      //Get the name from the variable identifier, passed from LEX
                if (elem==NULL)
                    yyerror("Variable %s not declared!", $1->name);
                else if (elem->value == NULL)
                    yyerror("Variable %s not initialized!", $1->name);
                $$=elem;
            }
            ;
paren_expression: LPAREN expression RPAREN { $$=$2; } ;


/** Control-Flow Statements **/
//-------------------------------------------------------------------------------------------------------------------------------------------------
statements:  statements statement | statement ;
statement:   if_statement | for_statement | while_statement | switch_statement
           | assignment SEMICOLON | CONTINUE SEMICOLON | BREAK SEMICOLON
           ;

brace_statements:   { print_debug("Creating new symbol table for nested block"); current_table = make_table(current_table); }
                  LBRACE function_body RBRACE
                    { print_debug("Exiting the nested block, here is its table:"); print_table(); current_table = current_table->prev_table; }
                  ;

if_statement:  IF paren_expression brace_statements else_if else { print_debug("If statement"); check_statement_type($2,$1); }
              | IF paren_expression brace_statements else        { print_debug("If statement"); check_statement_type($2,$1); }
              ;
else_if:   else_if ELSE IF paren_expression brace_statements  { check_statement_type($4,$2); }
         | ELSE IF paren_expression brace_statements  { check_statement_type($3,$1); }
         ;
else: ELSE brace_statements | /* empty */ ;


for_statement: FOR LPAREN assignment SEMICOLON expression SEMICOLON expression RPAREN brace_statements { print_debug("For statement"); check_statement_type($5,$1); };


while_statement: WHILE paren_expression brace_statements { print_debug("While statement");  check_statement_type($2,$1); } ;


assignment: variable ASSIGN expression {
    elem* item = lookup($1->name); if (item == NULL) yyerror("Variable %s not declared!", $1->name);
    elem* exp = $3;

    get_exp_result_type(item->type, exp->type, $2);    //Check that the expression type is compatible with the variable data type
    item->value = exp->value;

    print_debug("Assigned value to %s from temp variable %s", item->name, exp->name);

    $$ = item;
} ;

// Switch-case
switch_statement: SWITCH LPAREN variable RPAREN LBRACE cases default RBRACE ;
cases: cases case | case ;
case: CASE constant COLON statements BREAK SEMICOLON ;
default : DEFAULT COLON statements SEMICOLON | /* empty */ ;


%%


//Given a list of variables, append a new variable to it.
//This is used for the 'variables_list' rule, for example in the case 'int i=0, j=2;'
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

const char* get_token_name(int token) {
    return yytname[token-255];     // Return the textual representation of the token. yytname is automatically generated by YACC in the .h file
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

void resolve_console_params(int argc, char *argv[]) {
    if (argc>=2 && strcmp("--file", argv[1]) == 0)
        yyin = get_input_stream(argv[2]);   //yyin is an internal yacc variable
    else
        yyin = stdin;

    if ((argc>=2 && strcmp("--debug", argv[1]) == 0) || (argc>=4 && strcmp("--debug", argv[3]) == 0))
        debug = true;
}

int main(int argc, char *argv[]) {
    printf("-----  Formal Languages and Compilers  Project  -----\n       Alessandro Gottardi and Lucia Maninetti\n\n");

    init_global_table();

    resolve_console_params(argc, argv);

    int parse_ret = yyparse();
    fclose(yyin);

    remove_table();
    printf("\n");

    return parse_ret;
}
