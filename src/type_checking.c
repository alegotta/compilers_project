#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

//Functions defined in YACC
extern const char* get_token_name(int token);
extern int number_line;
extern void print_verbose(char* str, ...);
extern void yyerror(char* str, ...);


//Terminate the program in cases of errors
void type_error(elem* first, elem* second, int operation_type) {
    yyerror("Type conflict in expression (%s %s) %s (%s %s)\n", get_type_string(first->type), first->name, get_token_name(operation_type), get_type_string(second->type), second->name);
}

//Return the resulting type of the expression, or stops the compiler in cases of type conflicts
//Note that input and output are integer because this is how YACC internally represents tokens
int get_exp_result_type(elem* first, elem* second, int operation_type) {
    int first_type = first->type;
    int second_type = second->type;

    switch(operation_type) {
        case ASSIGN:
            if (first_type == second_type)
                return 0;
            else
                type_error(first, second, operation_type);
            break;

        case PLUS:
        case MINUS:
        case MUL:
        case DIV:
            if (first_type==INT_TYPE && second_type==INT_TYPE)
                return INT_TYPE;
            else if ((first_type==INT_TYPE && second_type==REAL_TYPE) || (first_type==REAL_TYPE && second_type==INT_TYPE) || (first_type==REAL_TYPE && second_type==REAL_TYPE))
                return REAL_TYPE;
            else
                type_error(first, second, operation_type);
            break;
        case MOD:
            if (first_type==INT_TYPE && second_type==INT_TYPE)
                return INT_TYPE;
            else
                type_error(first, second, operation_type);
            break;

        case AND:
        case OR:
        case NOT:   //NOT has just one operator, but just for simplifying this function was called with first==second
            if (first_type==BOOL_TYPE && second_type==BOOL_TYPE)
                return BOOL_TYPE;
            else
                type_error(first, second, operation_type);
            break;

        case GEQ:
        case SEQ:
        case GREATER:
        case SMALLER:
        case EQUAL:
            if (
                (first_type == second_type==INT_TYPE)             ||
                (first_type==INT_TYPE && second_type==REAL_TYPE)  ||
                (first_type==REAL_TYPE && second_type==INT_TYPE)  ||
                (first_type==REAL_TYPE && second_type==REAL_TYPE)
               )
                return BOOL_TYPE;
            else
                type_error(first, second, operation_type);
            break;
        default:
            yyerror("Operator %s not recognized", get_token_name(operation_type));
    }
}

void check_compatible_type(int type, elem* variable) {
    if (type != variable->type)
        yyerror("Type mismatch in initialization of variable %s: expected %s, got %s", variable->name, get_type_string(type), get_type_string(variable->type));
}

void check_statement_type(elem* variable, int statement) {
    switch(statement) {
        case IF:
        case WHILE:
        case FOR:
            if (variable->type != BOOL_TYPE)
                yyerror("Wrong type in %s condition for variable %s, expected BOOL", get_token_name(statement), variable->name);
    }
}

//Check that types are compatible, then return a new temporary value holding the expression result
elem* get_expression_result(elem* first, elem* second, int operation_type) {
    print_verbose("Evaluating expression %s %s %s", first->name, get_token_name(operation_type), second->name);

    //Create the variable and assign the correct type to it
    elem* new_elem = insert_temp_element(number_line);
    new_elem->value = create_value();
    int type = get_exp_result_type(first, second, operation_type);
    set_element_type(new_elem, type);

    values* ret_value = new_elem->value;
    values* first_value = first->value;
    values* second_value = second->value;

    switch(operation_type) {
        case PLUS:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                ret_value->i = first_value->i + second_value->i;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                ret_value->i = first_value->i + second_value->f;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                ret_value->f = first_value->f + second_value->i;
            else if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                ret_value->f = first_value->f + second_value->f;
            break;
        case MINUS:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                ret_value->i = first_value->i - second_value->i;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                ret_value->f = first_value->i - second_value->f;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                ret_value->f = first_value->f - second_value->i;
            else if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                ret_value->f = first_value->f - second_value->f;
            break;

        case MUL:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                ret_value->i = first_value->i * second_value->i;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                ret_value->f = first_value->i * second_value->f;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                ret_value->f = first_value->f * second_value->i;
            else if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                ret_value->f = first_value->f * second_value->f;
            break;

        case DIV:
            if ((second_value->i == 0) || (second_value->f) == 0)
                yyerror("Division by 0 between %s and %s", first->name, second->name);

            if (first->type==INT_TYPE && second->type== INT_TYPE)
                ret_value->i = first_value->i / second_value->i;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                ret_value->f = first_value->i / second_value->f;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                ret_value->f = first_value->f / second_value->i;
            else if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                ret_value->f = first_value->f / second_value->f;
            break;
        case MOD:
            if (second_value->i == 0)
                yyerror("Division by 0 between %s and %s", first->name, second->name);

            ret_value->i = first_value->i % second_value->i;
            break;

        case AND:
            ret_value->b = first_value->b && second_value->b;
            break;
        case OR:
            ret_value->b = first_value->b || second_value->b;
            break;
        case NOT:
            ret_value->b = !first_value->b;
            break;

        case EQUAL:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                ret_value->b = first_value->i == second_value->i;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                ret_value->b = first_value->i == second_value->f;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                ret_value->b = first_value->f == second_value->i;
            else if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                ret_value->b = first_value->f == second_value->f;
            else if (first->type==CHAR_TYPE && second->type== CHAR_TYPE)
                ret_value->b = first_value->c == second_value->c;
            else if (first->type==STRING_TYPE && second->type== STRING_TYPE)
                ret_value->b = strcmp(first_value->s, second_value->s) == 0;
            break;
        case GEQ:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                ret_value->b = first_value->i >= second_value->i;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                ret_value->b = first_value->i >= second_value->f;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                ret_value->b = first_value->f >= second_value->i;
            else if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                ret_value->b = first_value->f >= second_value->f;
            else if (first->type==CHAR_TYPE && second->type== CHAR_TYPE)
                ret_value->b = first_value->c >= second_value->c;
            else if (first->type==STRING_TYPE && second->type== STRING_TYPE)
                ret_value->b = strcmp(first_value->s, second_value->s) >= 0;
            break;
        case SEQ:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                ret_value->b = first_value->i <= second_value->i;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                ret_value->b = first_value->i <= second_value->f;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                ret_value->b = first_value->f <= second_value->i;
            else if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                ret_value->b = first_value->f <= second_value->f;
            else if (first->type==CHAR_TYPE && second->type== CHAR_TYPE)
                ret_value->b = first_value->c <= second_value->c;
            else if (first->type==STRING_TYPE && second->type== STRING_TYPE)
                ret_value->b = strcmp(first_value->s, second_value->s) <= 0;
            break;
        case SMALLER:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                ret_value->b = first_value->i < second_value->i;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                ret_value->b = first_value->i < second_value->f;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                ret_value->b = first_value->f < second_value->i;
            else if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                ret_value->b = first_value->f < second_value->f;
            else if (first->type==CHAR_TYPE && second->type== CHAR_TYPE)
                ret_value->b = first_value->c < second_value->c;
            else if (first->type==STRING_TYPE && second->type== STRING_TYPE)
                ret_value->b = strcmp(first_value->s, second_value->s) < 0;
            break;
        case GREATER:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                ret_value->b = first_value->i > second_value->i;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                ret_value->b = first_value->i > second_value->f;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                ret_value->b = first_value->f > second_value->i;
            else if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                ret_value->b = first_value->f > second_value->f;
            else if (first->type==CHAR_TYPE && second->type== CHAR_TYPE)
                ret_value->b = first_value->c > second_value->c;
            else if (first->type==STRING_TYPE && second->type== STRING_TYPE)
                ret_value->b = strcmp(first_value->s, second_value->s) > 0;
            break;
        default:
            yyerror("Operator %s not recognized", get_token_name(operation_type));
    }
    return new_elem;
}
