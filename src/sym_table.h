// Internal identifiers needed to distinguish different data types
#define UNKNOWN_TYPE 0  //Default value if not specified otherwise
#define INT_TYPE 1
#define REAL_TYPE 2
#define CHAR_TYPE 3
#define STRING_TYPE 4
#define BOOL_TYPE 5


//Struct describing all possible data values of an element.
// Just one of them is actually filled, depending on the chosen data type
typedef struct values {
    int i;
    bool b;
    char c;
    float f;
    char* s;
} values;

//Struct defining the content of each node in the symbol table
typedef struct elem {
    char* name;         //Name of the variable
    int type;           //Data type (from the above define list)
    int width;          //Size of the variable (from c sizeof function)
    int line_number;    //Line where the element was declared
    values *value;      //Content of the element
    struct elem *next;  //Pointer to the next value, needed since symbol table is implemented using a linked list
} elem;

//Struct defining the actual symbol table
// It is a linked list with both head and tail pointers (to improve insertion efficiency)
typedef struct sym_table {
    elem* head;
    elem* tail;
    struct sym_table* prev_table;   //Pointer to the upper symbol table, used in cases of nested blocks
    int offset;
} sym_table;


//Function signatures, see sym_table.c for implementation

values* create_value();
void print_value(elem* elem);
void set_element_type(elem* el, int type);
char* get_type_string(int type);
int get_type_size(int type);

sym_table *make_table(sym_table* previous);
void init_global_table();
void print_table();
elem *lookup_table(sym_table* table, char* name, bool recurse);
elem *lookup(char* name);
void remove_table(sym_table* table);
void enter_new_block();
void exit_block();

elem* create_element(char* name, int line_number);
elem* insert_temp_element(int line_number);
elem* insert_element(elem* element);
