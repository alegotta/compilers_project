#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "sym_table.h"

extern void yyerror(char* str, ...);
extern bool debug;

//GLOBAL VARIABLES
sym_table *global_table;
sym_table *current_table;
int temp_count = 1;


void print_debug_sym(char* str, ...) {
    if (debug == true) {
        va_list varlist;
        va_start (varlist, str);

        printf(" SYM:  ");
        vprintf (str, varlist);
        printf("\n");

        va_end (varlist);
    }
}

//-------------------------------------------------------------------------------------

values* create_value() {
    values* value = malloc(sizeof(values));
    value->i_value = 0;
    value->c_value = '0';
    value->s_value = "0";
    value->f_value = 0.0;
    value->b_value = false;

    return value;
}

void print_value(elem* elem) {
    if (elem==NULL || elem->value == NULL)
        printf("Value: 0");
    else if (elem->type == INT_TYPE)
        printf("Value: %d", elem->value->i_value);
    else if (elem->type == CHAR_TYPE)
        printf("Value: %c", elem->value->c_value);
    else if (elem->type == REAL_TYPE)
        printf("Value: %f", elem->value->f_value);
    else if (elem->type == STRING_TYPE)
        printf("Value: %s", elem->value->s_value);
    else if (elem->type == BOOL_TYPE)
        (elem->value->b_value==true) ? printf("Value: true") : printf("Value: false");
}

void set_element_type(elem* el, int type) {
    int width = get_type_size(type);

    global_table->offset += width;
    el->type = type;
    el->width = width;
}

char* get_type_string(int type) {
    switch(type) {
        case INT_TYPE:
            return "INT";
        case REAL_TYPE:
            return "FLOAT";
        case CHAR_TYPE:
            return "CHAR";
        case STRING_TYPE:
            return "STRING";
        case BOOL_TYPE:
            return "BOOL";
        case BLOCK_TYPE:
            return "BLOCK";
        case UNKNOWN_TYPE:
            return "UNKNOWN";
        default:
            yyerror("Unrecognized type %d\n", type);
    }
}

int get_type_size(int type) {
    switch(type) {
        case INT_TYPE:
            return sizeof(int);
        case CHAR_TYPE:
            return sizeof(char);
        case REAL_TYPE:
            return sizeof(float);
        case STRING_TYPE:
            return 100;
        case BOOL_TYPE:
            return sizeof(bool);
        case BLOCK_TYPE:
            return 1;
        default:
            yyerror("Unrecognized type %d\n", type);
    }
}

//-------------------------------------------------------------------------------------

//Generate a new table
sym_table *make_table(sym_table* previous) {
    sym_table* new_table = malloc(sizeof(sym_table));
    new_table->head = NULL;
    new_table->tail = NULL;
    new_table->offset = 0;
    new_table->prev_table = previous;

    return new_table;
}

//Initialize the global table
void init_global_table() {
    global_table = make_table(NULL);
    current_table = global_table;
}

void print_table() {
    if (debug==true) {
        elem* iterator;

        printf(" -------------\n  Offset: %d\n", current_table->offset);
        iterator = current_table->head;
        while (iterator != NULL) {
            printf("  Type: %s \t Symbol: %s \t Width: %d \t Line: %d \t ", get_type_string(iterator->type), iterator->name, iterator->width, iterator->line_number);

            if (iterator->value != NULL)
                print_value(iterator);

            printf("\n");
            iterator = iterator->next;
        }
        printf(" -------------\n");
    }
}


//Given a variable name, return the corresponding 'elem' pointer, if it exists.
elem *lookup_table(sym_table* table, char* name, bool recurse) {
    elem *iterator = table->head;

    while (iterator != NULL) {
        if (strcmp(name,iterator->name) == 0) {
            return iterator;
        }
        iterator = iterator->next;
    }

    if (recurse && table->prev_table != NULL)      //Check also outer blocks
        return lookup_table(table->prev_table, name, true);
    else
        return NULL;
}

elem *lookup(char* name) {
    return lookup_table(current_table, name, true);
}

//Entirely delete a table, called when the block is closed
void remove_table() {
    elem* iterator = current_table->head;
    elem* temp = current_table->head;
    while(iterator != NULL) {
        iterator = iterator->next;
        temp->next = NULL;
        free(temp);
        temp = iterator;
    }
    current_table->head = NULL;
    current_table->tail = NULL;
    current_table->prev_table = NULL;
    free(current_table);
}

//-------------------------------------------------------------------------------------

elem* create_element(char* name, int line_number) {
    elem* el = malloc(sizeof(elem));  //Allocate dynamic memory
    el->name = name;
    el->value = NULL;
    el->line_number = line_number;
    el->next = NULL;

    return el;
}

elem* insert_temp_element(int line_number) {
    char name[] = "t";
    char str_count[4];
    sprintf(str_count, "%d", temp_count);

    strcat(name, str_count);
    ++temp_count;

    elem* ret = create_element(strdup(name), line_number);
    ret->value = create_value();

    insert_element(ret);

    return ret;
}

//Add a new symbol to the table
void insert_element(elem* element) {
    elem* el = lookup_table(current_table, element->name, false);
    if (el != NULL) {
        yyerror("Variable '%s' already declared in the same block!", element->name);
    } else {
        print_debug_sym("Symbol '%s' is new, adding to table", element->name);

        if(current_table->head == NULL) {        //The table was empty: initialize head and tail pointers
            current_table->head = element;
            current_table->tail = element;
        } else {                                //Move just the tail pointer
            current_table->tail->next = element;
            current_table->tail = current_table->tail->next;
        }
    }
}
