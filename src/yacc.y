%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdarg.h>
#include "sym_table.c"

extern FILE *yyin;
bool debug = true;
extern int yylex();
extern int number_line;
const char * const* token_table;
void yyerror(char* str, ...);
void print_debug(char* str, ...);
elem **add_variable_to_list(elem* variables[], elem* variable);
values* create_value();
elem* get_expression_result(elem* first, elem* second, int operation_type);
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

%token INT FLOAT CHAR BOOL STRING IF ELSE WHILE CASE FOR SWITCH CONTINUE BREAK DEFAULT RETURN LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE SEMICOLON COLON DOT COMMA ASSIGN
%token <lexeme> ID
%token <i_value> PLUS MINUS MUL DIV MOD AND OR NOT EQUAL GEQ SEQ GREATER SMALLER
%type <i_value> type
%type <variables> names
%type <element> variable assignment expression paren_expression
%type <value> constant return


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

program: main return { printf("\nReturn: %d\n\nParsed Successfully!\n", $2->i_value); YYACCEPT; } | return { printf("\nReturn: %d\n\nParsed Successfully!\n", $1->i_value); YYACCEPT; } ;

return: RETURN expression SEMICOLON { $$ = $2->value; } | RETURN SEMICOLON { elem* ret = enter_temp(NULL, number_line); ret->value=create_value(); ret->value->i_value = 0; $$ = ret->value; } ;

main: declarations statements | statements | declarations ;

/** Declaration of variables **/
declarations: declarations declaration | declaration ;
type:  INT { $$ = INT_TYPE; }
     | CHAR { $$ = CHAR_TYPE; }
     | FLOAT { $$ = FLOAT_TYPE; }
     | STRING { $$ = STRING_TYPE; }
     | BOOL { $$ = BOOL_TYPE; } ;
declaration: type names SEMICOLON
             {
                elem** variables = $2;
                int size = sizeof(variables)/sizeof(variables[0]);

                for(int i=0; i<size;i++) {
                    elem* variable = variables[i];
                    int data_type = $1;
                    set_type(variable, data_type);
                    print_debug("declaration of %s %s", get_type_string(data_type), variables[i]->name);
                }
             } ;
names:   names COMMA variable { $$ = add_variable_to_list($1, $3); }
       | names COMMA assignment { $$ = add_variable_to_list($1, $3); }
       | variable { $$ = add_variable_to_list(NULL, $1); }
       | assignment { $$ = add_variable_to_list(NULL, $1); }
       ;

variable: ID { elem* el = lookup(NULL,$1); $$ = el; } ;

/* Declaration of constants */
constant:  /* INTEGER %prec MINUS { values* value = create_value(); value->i_value=-$1; $$ = value; }
          | NUM %prec MINUS { values* value = create_value(); value->f_value=-$1; $$ = value; }
          |*/ INTEGER { values* value = create_value(); value->i_value=$1; $$ = value; }
          | NUM { values* value = create_value(); value->f_value=$1; $$ = value; }
          | CHARACTER { values* value = create_value(); value->c_value=$1; $$ = value; }
          | BOOLEAN { values* value = create_value(); value->b_value=$1; $$ = value; }
          | CHARARRAY { values* value = create_value(); value->s_value=$1; $$ = value; }
          ;

assignment: variable ASSIGN expression
       {
         elem* item = $1;
         elem* exp = $3;
         item->value = exp->value;
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
    variable                      { $$=$1; }                                |
    constant                      { elem* new_elem = enter_temp(NULL, number_line); new_elem->value=$1; $$=new_elem; }
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


elem **add_variable_to_list(elem** variables, elem* variable) {
    int size = 0;
    if (variables != NULL)
        size = sizeof(variables)/sizeof(variables[0]);

    elem **new_array = realloc(variables, (size+1) * sizeof(elem));
    for(int i=0;i<size;i++) {
        new_array[i] = variables[i];
    }
    new_array[size] = variable;

    return new_array;
}

void type_error(int first_type, int second_type, int operation_type) {
	yyerror("Type conflict in %s %s %s\n", get_type_string(first_type), token_table[operation_type-255], get_type_string(second_type));
}

int get_exp_result_type(int first_type, int second_type, int operation_type) {
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
            if (first_type==INT_TYPE && second_type==INT_TYPE)
                return INT_TYPE;
            else if ((first_type==INT_TYPE && second_type==FLOAT_TYPE) || (first_type==FLOAT_TYPE && second_type==INT_TYPE) || (first_type==FLOAT_TYPE && second_type==FLOAT_TYPE))
                return FLOAT_TYPE;
            else
                type_error(first_type, second_type, operation_type);
            break;
        case MOD:
            if (first_type==INT_TYPE && second_type==INT_TYPE)
                return INT_TYPE;
            else
                type_error(first_type, second_type, operation_type);
            break;

        case AND:
        case OR:
            if (first_type==BOOL_TYPE && second_type==BOOL_TYPE)
                return BOOL_TYPE;
            else
                type_error(first_type, second_type, operation_type);
            break;
        case NOT:
            if (first_type==BOOL_TYPE)       // TODO: Handle !=
                return BOOL_TYPE;
            else
                type_error(first_type, second_type, operation_type);
            break;
        case GEQ:
        case SEQ:
        case GREATER:
        case SMALLER:
        case EQUAL:
            if (
                (first_type==INT_TYPE && second_type==FLOAT_TYPE)   ||
                (first_type==FLOAT_TYPE && second_type==INT_TYPE)   ||
                (first_type==FLOAT_TYPE && second_type==FLOAT_TYPE) ||
                (first_type==INT_TYPE && second_type==INT_TYPE)
               )
                return BOOL_TYPE;
            else
                type_error(first_type, second_type, operation_type);
            break;
        default:
            yyerror("Operator %s not recognized", token_table[operation_type-255]);
    }
}

elem* get_expression_result(elem* first, elem* second, int operation_type) {
    elem* new_elem = enter_temp(NULL, number_line);
    new_elem->value = create_value();
    int type = get_exp_result_type(first->type, second->type, operation_type);
    set_type(new_elem, type);

    switch(operation_type) {
        case PLUS:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->i_value = first->value->i_value + second->value->i_value;
            else if (first->type==INT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->f_value = first->value->i_value + second->value->f_value;
            else if(first->type==FLOAT_TYPE && second->type== INT_TYPE)
                new_elem->value->f_value = first->value->f_value + second->value->i_value;
            else // if (first->type==FLOAT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->f_value = first->value->f_value + second->value->f_value;
            break;
        case MINUS:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->i_value = first->value->i_value - second->value->i_value;
            else if (first->type==INT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->f_value = first->value->i_value - second->value->f_value;
            else if(first->type==FLOAT_TYPE && second->type== INT_TYPE)
                new_elem->value->f_value = first->value->f_value - second->value->i_value;
            else // if (first->type==FLOAT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->f_value = first->value->f_value - second->value->f_value;
            break;

        case MUL:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->i_value = first->value->i_value * second->value->i_value;
            else if (first->type==INT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->f_value = first->value->i_value * second->value->f_value;
            else if(first->type==FLOAT_TYPE && second->type== INT_TYPE)
                new_elem->value->f_value = first->value->f_value * second->value->i_value;
            else // if (first->type==FLOAT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->f_value = first->value->f_value * second->value->f_value;
            break;

        case DIV:
            if ((second->value->i_value == 0) || (second->value->f_value) == 0)
                yyerror("Division by 0 between %s and %s", first->name, second->name);

            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->i_value = first->value->i_value / second->value->i_value;
            else if (first->type==INT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->f_value = first->value->i_value / second->value->f_value;
            else if(first->type==FLOAT_TYPE && second->type== INT_TYPE)
                new_elem->value->f_value = first->value->f_value / second->value->i_value;
            else // if (first->type==FLOAT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->f_value = first->value->f_value / second->value->f_value;
            break;
        case MOD:
            if (second->value->i_value == 0)
                yyerror("Division by 0 between %s and %s", first->name, second->name);

            new_elem->value->i_value = first->value->i_value % second->value->i_value;
            break;

        case AND:
            new_elem->value->b_value = first->value->b_value && second->value->b_value;
            break;
        case OR:
            new_elem->value->b_value = first->value->b_value || second->value->b_value;
            break;
        case NOT:
            new_elem->value->b_value = !first->value->b_value;
            break;

        case EQUAL:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->i_value == second->value->i_value;
            else if (first->type==INT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->b_value = first->value->i_value == second->value->f_value;
            else if(first->type==FLOAT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->f_value == second->value->i_value;
            else // if (first->type==FLOAT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->b_value = first->value->f_value == second->value->f_value;
            break;
        case GEQ:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->i_value >= second->value->i_value;
            else if (first->type==INT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->b_value = first->value->i_value >= second->value->f_value;
            else if(first->type==FLOAT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->f_value >= second->value->i_value;
            else // if (first->type==FLOAT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->b_value = first->value->f_value >= second->value->f_value;
            break;
        case SEQ:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->i_value <= second->value->i_value;
            else if (first->type==INT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->b_value = first->value->i_value <= second->value->f_value;
            else if(first->type==FLOAT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->f_value <= second->value->i_value;
            else // if (first->type==FLOAT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->b_value = first->value->f_value <= second->value->f_value;
            break;
        case SMALLER:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->i_value < second->value->i_value;
            else if (first->type==INT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->b_value = first->value->i_value < second->value->f_value;
            else if(first->type==FLOAT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->f_value < second->value->i_value;
            else // if (first->type==FLOAT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->b_value = first->value->f_value < second->value->f_value;
            break;
        case GREATER:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->i_value > second->value->i_value;
            else if (first->type==INT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->b_value = first->value->i_value > second->value->f_value;
            else if(first->type==FLOAT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->f_value > second->value->i_value;
            else // if (first->type==FLOAT_TYPE && second->type== FLOAT_TYPE)
                new_elem->value->b_value = first->value->f_value > second->value->f_value;
            break;
        default:
            yyerror("Operator %s not recognized", token_table[operation_type-255]);
    }
    return new_elem;
}

void print_debug(char* str, ...) {
    if (debug==true) {
        va_list varlist;
        printf("YACC: ");
        va_start (varlist, str);
        vprintf (str, varlist);
        va_end (varlist);
        printf("\n");
    }
}

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
        printf("Please type some input, or 'return;' to terminate...\n");
        stream = stdin;
    }
    return stream;
}

int main(int argc, char *argv[]) {
    printf("--Formal Languages and Compilers--\n           Group Project\n\n");

    init_table();
    token_table = yytname;

    FILE* stream = get_input_stream(argv[1]);
    yyin = stream;

    int parse_ret = yyparse();
    fclose(yyin);
    print_table(NULL);
    remove_table(NULL);

    return parse_ret;
}
