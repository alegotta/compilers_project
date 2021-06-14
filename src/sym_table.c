#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "sym_table.h"


//GLOBAL VARIABLES
sym_table *global_table;
int temp_count = 1;

sym_table* check_null(sym_table* table) {
    if (table == NULL)
        return global_table;
    else
        return table;
}

char* get_type_string(int type) {
    switch(type) {
        case INT_TYPE:
            return "INT";
        case FLOAT_TYPE:
            return "FLOAT";
        case CHAR_TYPE:
            return "CHAR";
        case STRING_TYPE:
            return "STRING";
        case BOOL_TYPE:
            return "BOOL";
        case BLOCK_TYPE:
            return "BLOCK";
        default:
            return "Unknown";
    }
}

//Generate a new table
sym_table *make_table(char* name, sym_table* previous) {
    sym_table* new_table = malloc(sizeof(sym_table));
    new_table->head = NULL;
    new_table->tail = NULL;
    new_table->offset = 0;
    new_table->name = name;
    new_table->prev_table = previous;

    return new_table;
}

void print_table(sym_table* table) {
    table = check_null(table);
    elem* iterator;

    printf("\n-------------\nSymbol Table %s:\n-------------\nOffset: %d\n", table->name, table->offset);
    iterator = table->head;
    while (iterator != NULL) {
        printf("Type: %s \t Symbol: %s \t Width: %d \t ", get_type_string(iterator->type), iterator->name, iterator->width);

        if (iterator->line_number != -1)
            printf("Line: %d \t ", iterator->line_number);
        if (iterator->value != NULL) {
            if (iterator->type == INT_TYPE)
                printf("Value: %d", iterator->value->i_value);
            else if (iterator->type == CHAR_TYPE)
                printf("Value: %c", iterator->value->c_value);
            else if (iterator->type == FLOAT_TYPE)
                printf("Value: %f", iterator->value->f_value);
            else if (iterator->type == STRING_TYPE)
                printf("Value: %s", iterator->value->s_value);
            else if (iterator->type == BOOL_TYPE)
                printf("Value: %b", iterator->value->b_value);
        }
        printf("\n");
        iterator = iterator->next;
    }
    printf("\n\n");
}

int get_size(int type) {
    switch(type) {
        case INT_TYPE:
            return sizeof(int);
        case CHAR_TYPE:
            return sizeof(char);
        case FLOAT_TYPE:
            return sizeof(float);
        case STRING_TYPE:
            return 100;
        case BOOL_TYPE:
            return sizeof(bool);
        case BLOCK_TYPE:
            return 1;
        default:
            printf("Unrecognized type\n");
            exit(1);
    }
}

//Given a variable name, return the corresponding 'elem' pointer, if it exists.
elem *lookup(sym_table* table, char* name) {
    table = check_null(table);

    elem *iterator = table->head;

    while (iterator != NULL) {
        if (strcmp(name,iterator->name) == 0) {
            return iterator;
        }
        iterator = iterator->next;
    }

    if (table->prev_table != NULL)      //Check also outer blocks
        return lookup(table->prev_table, name);
    else
        return NULL;
}

elem* enter_temp(sym_table* table, int line_number) {
    char name[] = "t";
    char str_count[4];
    sprintf(str_count, "%d", temp_count);

    strcat(name, str_count);
    ++temp_count;

    return enter(table, strdup(name), line_number);
}

//Add a new symbol to the table. Note that type and value will be added in a later moment
elem* enter(sym_table* table, char* name, int line_number) {
    table = check_null(table);

    elem* el = lookup(table, name);
    if (el != NULL) {
        printf("SYM:  Symbol '%s' already present in table!\n", name);
        return el;
    } else {
        printf("SYM:  Symbol '%s' is new, adding to table\n", name);
        el = malloc(sizeof(elem));  //Allocate dynamic memory
        el->name = name;
        el->value = NULL;
        el->line_number = line_number;
        el->next = NULL;

        if(table->head == NULL) {        //The table was empty: initialize head and tail pointers
            table->head = el;
            table->tail = el;
        } else {                                //Move just the tail pointer
            table->tail->next = el;
            table->tail = table->tail->next;
        }
        return el;
    }
}

void set_type(elem* el, int type) {
    int width = get_size(type);

    global_table->offset += width;     //TODO: Nested
    el->type = type;
    el->width = width;
}

values* create_value() {
    values* value = malloc(sizeof(values));
    value->i_value = 0;
    value->c_value = '0';
    value->s_value = "0";
    value->f_value = 0.0;
    value->b_value = false;

    return value;
}

//Entirely delete a table, called when the block is closed
void remove_table(sym_table* table) {
    table = check_null(table);

    elem* iterator = table->head;
    elem* temp = table->head;
    while(iterator != NULL) {
        iterator = iterator->next;
        temp->next = NULL;
        free(temp);
        temp = iterator;
    }
    table->head = NULL;
    table->tail = NULL;
    table->prev_table = NULL;
    free(table);
}

//Initialize the global table
void init_table() {
    global_table = make_table("Global", NULL);
}
