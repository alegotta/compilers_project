#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"

const char* get_token_name(int token);
extern int number_line;
extern void print_debug(char* str, ...);
extern void yyerror(char* str, ...);


void type_error(int first_type, int second_type, int operation_type) {
	yyerror("Type conflict in %s %s %s\n", get_type_string(first_type), get_token_name(operation_type), get_type_string(second_type));
}

//Returns the resulting type of the expression, or stops the compiler in cases of type conflicts
//Note that input and output are integer because this is how YACC internally represents tokens
int get_exp_result_type(int first_type, int second_type, int operation_type) {
    switch(operation_type) {
        case ASSIGN:
            if (first_type == second_type)
                return 0;
            else
                type_error(first_type, second_type, operation_type);
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
            if (first_type==BOOL_TYPE)
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
                (first_type==INT_TYPE && second_type==REAL_TYPE)   ||
                (first_type==REAL_TYPE && second_type==INT_TYPE)   ||
                (first_type==REAL_TYPE && second_type==REAL_TYPE)  ||
                (first_type==INT_TYPE && second_type==INT_TYPE)
               )
                return BOOL_TYPE;
            else
                type_error(first_type, second_type, operation_type);
            break;
        default:
            yyerror("Operator %s not recognized", get_token_name(operation_type));
    }
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
    print_debug("Evaluating expression %s %s %s", first->name, get_token_name(operation_type), second->name);

    //Create the variable and assign the correct type to it
    elem* new_elem = insert_temp_element(number_line);
    new_elem->value = create_value();
    int type = get_exp_result_type(first->type, second->type, operation_type);
    set_element_type(new_elem, type);

    switch(operation_type) {
        case PLUS:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->i_value = first->value->i_value + second->value->i_value;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                new_elem->value->f_value = first->value->i_value + second->value->f_value;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                new_elem->value->f_value = first->value->f_value + second->value->i_value;
            else // if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                new_elem->value->f_value = first->value->f_value + second->value->f_value;
            break;
        case MINUS:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->i_value = first->value->i_value - second->value->i_value;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                new_elem->value->f_value = first->value->i_value - second->value->f_value;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                new_elem->value->f_value = first->value->f_value - second->value->i_value;
            else // if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                new_elem->value->f_value = first->value->f_value - second->value->f_value;
            break;

        case MUL:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->i_value = first->value->i_value * second->value->i_value;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                new_elem->value->f_value = first->value->i_value * second->value->f_value;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                new_elem->value->f_value = first->value->f_value * second->value->i_value;
            else // if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                new_elem->value->f_value = first->value->f_value * second->value->f_value;
            break;

        case DIV:
            if ((second->value->i_value == 0) || (second->value->f_value) == 0)
                yyerror("Division by 0 between %s and %s", first->name, second->name);

            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->i_value = first->value->i_value / second->value->i_value;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                new_elem->value->f_value = first->value->i_value / second->value->f_value;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                new_elem->value->f_value = first->value->f_value / second->value->i_value;
            else // if (first->type==REAL_TYPE && second->type== REAL_TYPE)
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
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                new_elem->value->b_value = first->value->i_value == second->value->f_value;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->f_value == second->value->i_value;
            else // if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                new_elem->value->b_value = first->value->f_value == second->value->f_value;
            break;
        case GEQ:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->i_value >= second->value->i_value;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                new_elem->value->b_value = first->value->i_value >= second->value->f_value;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->f_value >= second->value->i_value;
            else // if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                new_elem->value->b_value = first->value->f_value >= second->value->f_value;
            break;
        case SEQ:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->i_value <= second->value->i_value;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                new_elem->value->b_value = first->value->i_value <= second->value->f_value;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->f_value <= second->value->i_value;
            else // if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                new_elem->value->b_value = first->value->f_value <= second->value->f_value;
            break;
        case SMALLER:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->i_value < second->value->i_value;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                new_elem->value->b_value = first->value->i_value < second->value->f_value;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->f_value < second->value->i_value;
            else // if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                new_elem->value->b_value = first->value->f_value < second->value->f_value;
            break;
        case GREATER:
            if (first->type==INT_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->i_value > second->value->i_value;
            else if (first->type==INT_TYPE && second->type== REAL_TYPE)
                new_elem->value->b_value = first->value->i_value > second->value->f_value;
            else if(first->type==REAL_TYPE && second->type== INT_TYPE)
                new_elem->value->b_value = first->value->f_value > second->value->i_value;
            else // if (first->type==REAL_TYPE && second->type== REAL_TYPE)
                new_elem->value->b_value = first->value->f_value > second->value->f_value;
            break;
        default:
            yyerror("Operator %s not recognized", get_token_name(operation_type));
    }
    return new_elem;
}
