#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "sym_table.h"

/* Code for symbol table. Check structs declaration in sym_table.h */

//Functions defined in YACC
extern void yyerror(char* str, ...);
extern bool verbose;

//Global Variables
sym_table *global_table;
sym_table *current_table;   //Table in which the program is currently. It is initially equal to global_table.
int temp_count = 1;


void print_verbose_sym(char* str, ...) {
    if (verbose == true) {
        va_list varlist;
        va_start (varlist, str);

        printf(" SYM:  ");
        vprintf (str, varlist);
        printf("\n");

        va_end (varlist);
    }
}

// Functions related to content of variables (struct 'values')
//-------------------------------------------------------------------------------------

//Create a variable of type 'values'
values* create_value() {
    values* value = malloc(sizeof(values));
    value->i = 0;
    value->c = '0';
    value->s = "0";
    value->f = 0.0;
    value->b = false;

    return value;
}

//Print the content of an element to screen, based on its data type
void print_value(elem* elem) {
    if (elem==NULL || elem->value == NULL)
        printf("Value: 0");
    else {
        switch(elem->type) {
            case INT_TYPE:
                printf("Value: %d", elem->value->i);
                break;
            case REAL_TYPE:
                printf("Value: %f", elem->value->f);
                break;
            case CHAR_TYPE:
                printf("Value: %c", elem->value->c);
                break;
            case STRING_TYPE:
                printf("Value: %s", elem->value->s);
                break;
            case BOOL_TYPE:
                (elem->value->b==true) ? printf("Value: true") : printf("Value: false");
                break;
            case UNKNOWN_TYPE:
                printf("Value: 0");
                break;
            default:
                yyerror("Unrecognized type %d\n", elem->type);
                break;
        }
    }
}

// Functions related to symbol table opreations
//-------------------------------------------------------------------------------------

//Generate a new symvol table
sym_table *make_table(sym_table* previous) {
    sym_table* new_table = malloc(sizeof(sym_table));
    new_table->head = NULL;
    new_table->tail = NULL;
    new_table->offset = 0;
    new_table->prev_table = previous;

    return new_table;
}

//Method called at the start of compiler to initialize the global table
void init_global_table() {
    global_table = make_table(NULL);
    current_table = global_table;
}

void print_table() {
    if (verbose==true) {
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


//Given an element name, return the corresponding pointer if it exists, NULL otherwise.
elem *lookup_table(sym_table* table, char* name, bool recurse) {
    elem *iterator = table->head;

    while (iterator != NULL) {
        if (strcmp(name,iterator->name) == 0)
            return iterator;

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
void remove_table(sym_table* table) {
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

//Create a table for the newsted block, and change the current_table variable accordingly
void enter_new_block() {
    current_table = make_table(current_table);
}

//Move to the outer block (if possible) and remove the inner table
void exit_block() {
    sym_table* old_block = current_table;

    if (current_table->prev_table != NULL)
        current_table = current_table->prev_table;

    remove_table(old_block);
}

// Functions related to variables of type 'elem'
//-------------------------------------------------------------------------------------

//Set the type for an element, also adjusting its size
void set_element_type(elem* el, int type) {
    int width = get_type_size(type);
    if (type == STRING_TYPE)
        width = width * strlen(el->value->s);

    global_table->offset += width;
    el->type = type;
    el->width = width;
}

//Return a string representation of the internal type code
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
            return sizeof(char);    //Will be enlarged based on the actual content
        case BOOL_TYPE:
            return sizeof(bool);
        default:
            yyerror("Unrecognized type %d\n", type);
    }
}

//Create a variable of type elem, initially without specifying its type and without adding it to the table
elem* create_element(char* name, int line_number) {
    elem* el = malloc(sizeof(elem));  //Allocate dynamic memory
    el->name = name;
    el->value = NULL;
    el->line_number = line_number;
    el->next = NULL;

    return el;
}

//Add a temporary element to the table. The variable name has the form "t0" and is automatically generated
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

//Add a variable of type element to the current table
// Also check that no other element with the same identifier have already been defined in the same block
elem* insert_element(elem* element) {
    elem* el = lookup_table(current_table, element->name, false);   //With false we don't check in outer blocks
    if (el != NULL) {
        yyerror("Variable '%s' already declared in the same block!", element->name);
    } else {
        print_verbose_sym("Symbol '%s' is new, adding to table", element->name);

        if(current_table->head == NULL) {        //The table was empty: initialize head and tail pointers
            current_table->head = element;
            current_table->tail = element;
        } else {                                //Move just the tail pointer
            current_table->tail->next = element;
            current_table->tail = current_table->tail->next;
        }
    }
    return el;
}
