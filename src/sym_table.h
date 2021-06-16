#define UNKNOWN_TYPE 0
#define INT_TYPE 1
#define REAL_TYPE 2
#define CHAR_TYPE 3
#define STRING_TYPE 4
#define BOOL_TYPE 5
#define BLOCK_TYPE 6

char* get_type_string(int type);


//Struct describing possible data values of a node
typedef struct values {
    int i_value;
    bool b_value;
    char c_value;
    float f_value;
    char* s_value;
} values;

//Struct defining the content of each node in the symbol table
typedef struct elem {
    char* name;         //Name of the variable
    int type;   //Data type
    int width;          //Size
    int line_number;
    values *value;
    struct elem *next;  //Pointer to the next value, needed since this is a linked list
} elem;

//Struct defining the actual symbol table. It is a linked list with both head and tail pointers (to increase insertion efficiency)
typedef struct sym_table {
    elem* head;
    elem* tail;
    struct sym_table* prev_table;   //Pointer to the upper symbol table, used in cases of nested blocks
    int offset;
} sym_table;


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
void remove_table();
elem* create_element(char* name, int line_number);
elem* insert_temp_element(int line_number);
void insert_element(elem* element);
