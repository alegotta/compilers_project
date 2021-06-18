//Functions and variables defined in LEX
extern FILE *yyin;
extern int yylex();
extern int number_line;
extern void yyerror(char* str, ...);

//Functions and variables defined in LEX
extern bool verbose;
extern const char* get_token_name(int token);
