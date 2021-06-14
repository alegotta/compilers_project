#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "sym_table.h"


//GLOBAL VARIABLES
sym_table *global_table;

//Generate a new table
sym_table *mktable(char* name, sym_table* previous) {
    sym_table* new_table = malloc(sizeof(sym_table));
    new_table->head = NULL;
    new_table->tail = NULL;
    new_table->offset = 0;
    new_table->name = name;
    new_table->prev_table = previous;

    return new_table;
}

void print_table(sym_table* table) {
    if (table == NULL)
        table = global_table;
    elem* temp;

    printf("\n-------------\nSymbol Table %s:\n-------------\nOffset: %d\n", table->name, table->offset);
    temp = table->head;
    while (temp != NULL) {
        printf("Type: %s \t Width: %d \t Line: %d \t Symbol: %s \t", temp->type, temp->width, temp->line_number, temp->name);

        if (temp->value != NULL) {
            if (strcmp(temp->type, "INT") == 0)
                printf("Value: %d", temp->value->i_value);
            else if (strcmp(temp->type, "CHAR") == 0)
                printf("Value: %c", temp->value->c_value);
            else if (strcmp(temp->type, "FLOAT") == 0)
                printf("Value: %f", temp->value->f_value);
            else if (strcmp(temp->type, "STRING") == 0)
                printf("Value: %s", temp->value->s_value);
        }
        printf("\n");
        temp = temp->next;
    }
    printf("\n\n");
}

int get_size(const char* type) {
    if (strcmp(type, "INT") == 0)
        return sizeof(int);
    else if (strcmp(type, "CHAR") == 0)
            return sizeof(char);
    else if (strcmp(type, "FLOAT") == 0)
            return sizeof(float);
    else if (strcmp(type, "STRING") == 0)
            return 100;
    else if (strcmp(type, "BLOCK") == 0)
            return 1;
    else {
        printf("Unrecognized type\n");
        exit(1);
    }
}

//Given a variable name, return the corresponding 'elem' pointer, if it exists.
elem *lookup(sym_table* table, char* name) {
    if (table == NULL)
        table = global_table;

    elem *temp = table->head;

    while (temp != NULL) {
        if (strcmp(name,temp->name) == 0) {
            return temp;
        }
        temp = temp->next;
    }

    if (table->prev_table != NULL)      //Check also outer blocks
        return lookup(table->prev_table, name);
    else
        return NULL;
}

//Add a new symbol to the table. Note that type and value will be added in a later moment
elem* enter(sym_table* table, char* name, int line_number) {
    sym_table* actual_table = table;
    if (table == NULL)  //Use the global table if not specifying differently
        actual_table = global_table;

    if (lookup(actual_table, name) != NULL) {
        printf("SYM:  Symbol %s already present in table!\n", name);
    } else {
        printf("SYM:  Symbol %s is new, adding to table\n", name);
        elem* new_elem = malloc(sizeof(elem)*20);  //Allocate dynamic memory
        new_elem->name = name;
        new_elem->value = NULL;
        new_elem->line_number = line_number;
        new_elem->next = NULL;

        if(actual_table->head == NULL) {        //The table was empty: initialize head and tail pointers
            actual_table->head = new_elem;
            actual_table->tail = new_elem;
        } else {                                //Move just the tail pointer
            actual_table->tail->next = new_elem;
            actual_table->tail = actual_table->tail->next;
        }
        return new_elem;
    }
}

void set_type(elem* el, char* type) {
    int width = get_size(type);

    global_table->offset += width;     //TODO: Nested
    el->type = type;
    el->width = width;
}

void set_value(elem* el, void* val) {
    if (strcmp(el->type, "INTEGER") == 0) {
        el->value->i_value = *((int *) val);
    }
}

void get_value(elem* el, void* val) {
    if (strcmp(el->type, "INTEGER") == 0) {
        *((int *) val) = el->value->i_value;
    }
}

void modify_value(sym_table* table, char* name, void* val) {
    elem *el = lookup(table, name);
    if (el != NULL) {
        set_value(el, val);
    } else {
        printf("Error: trying to modify a variable (%s) that does not exist!", name);
        exit(1);
    }
}

//Entirely delete a table, called when the block is closed
void rmtable(sym_table* table) {
    elem* temp = table->head;
    while(temp != NULL) {
        elem* t = temp->next;
        if (t != NULL) {
            temp->next = NULL;
            free(temp);
            temp = t;
        }
    }
    table->head = NULL;
    table->tail = NULL;
    table->prev_table = NULL;
    free(table);
}

//Initialize the global table
void init_table() {
    global_table = mktable("Global", NULL);
}
