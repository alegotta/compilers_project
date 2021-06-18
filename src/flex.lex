%option noyywrap
%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdbool.h>
#include <string.h>
#include "globals.h"
#include "sym_table.h"
#include "y.tab.h"

//Line counter, for verbose reasons
int number_line = 1;

//Functions signatures
int yylex();
void yyerror(char* str, ...);
void verbose_print(const char* token);
void print_token(int token);


/** Regular Expressions declaration **/
// *_LITERAL recognize data expressions related to the different types
//  Note the CHAR and STRING regex: they match an opening quote, then any character except a quote, and finally a closing quote
// COMMENTS recognizes a whole line starting with // (the dot matches all characters)
// Note that some characters had to be escaped (" and /)
%}

DIGIT          [0-9]
INT_LITERAL    {DIGIT}+
REAL_LITERAL   {DIGIT}+(\.{DIGIT}+)?
CHAR_LITERAL   '[^']'
STRING_LITERAL \"[^\"]+\"
BOOL_LITERAL   true|false

LETTER         [a-zA-Z_]
ID             {LETTER}({LETTER}|{DIGIT})*

COMMENTS       \/\/.*


%%

{COMMENTS}  { verbose_print("COMMENTS"); }

"int"      { yylval.identifier = INT_TYPE; print_token(INT); return INT;          }
"float"    { yylval.identifier = REAL_TYPE; print_token(FLOAT); return FLOAT;     }
"char*"    { yylval.identifier = STRING_TYPE; print_token(STRING); return STRING; }
"char"     { yylval.identifier = CHAR_TYPE; print_token(CHAR); return CHAR;       }
"bool"     { yylval.identifier = BOOL_TYPE; print_token(BOOL); return BOOL;       }

"if"       { yylval.identifier = IF;  print_token(IF); return IF;          }
"else"     { yylval.identifier = ELSE;  print_token(ELSE); return ELSE;    }
"while"    { yylval.identifier = WHILE;  print_token(WHILE); return WHILE; }
"case"     { print_token(CASE); return CASE;                               }
"for"      { yylval.identifier = FOR;  print_token(FOR); return FOR;       }
"switch"   { print_token(SWITCH); return SWITCH;                           }
"break"    { print_token(BREAK); return BREAK;                             }
"default"  { print_token(DEFAULT); return DEFAULT;                         }
"return"   { print_token(RETURN); return RETURN;                           }

"+"   { yylval.identifier = PLUS; print_token(PLUS); return PLUS;          }
"-"   { yylval.identifier = MINUS; print_token(MINUS); return MINUS;       }
"*"   { yylval.identifier = MUL;  print_token(MUL); return MUL;            }
"/"   { yylval.identifier = DIV; print_token(DIV); return DIV;             }
"%"   { yylval.identifier = MOD; print_token(MOD); return MOD;             }
"&&"  { yylval.identifier = AND; print_token(AND); return AND;             }
"||"  { yylval.identifier = OR; print_token(OR); return OR;                }
"!"   { yylval.identifier = NOT; print_token(NOT); return NOT;             }
"=="  { yylval.identifier = EQUAL; print_token(EQUAL); return EQUAL;       }
">="  { yylval.identifier = GEQ; print_token(GEQ); return GEQ;             }
"<="  { yylval.identifier = SEQ; print_token(SEQ); return SEQ;             }
">"   { yylval.identifier = GREATER; print_token(GREATER); return GREATER; }
"<"   { yylval.identifier = SMALLER; print_token(SMALLER); return SMALLER; }

"("   { print_token(LPAREN); return LPAREN;       }
")"   { print_token(RPAREN); return RPAREN;       }
"{"   { print_token(LBRACE); return LBRACE;       }
"}"   { print_token(RBRACE); return RBRACE;       }
";"   { print_token(SEMICOLON); return SEMICOLON; }
":"   { print_token(COLON); return COLON;         }
","   { print_token(COMMA); return COMMA;         }
"="   { yylval.identifier = ASSIGN; print_token(ASSIGN); return ASSIGN; }


{INT_LITERAL}    {  yylval.element = insert_temp_element(number_line);      //Create a temporary variable of type elem (check definition in sym_table.h)
                    yylval.element->value->i = atoi(yytext);                // Convert the string read by FLEX (in variable yytext) into integer
                    set_element_type(yylval.element, INT_TYPE);             // Set its type to INT_TYPE (internal code also defined in sym_table.h)
                    print_token(INT_LITERAL); return INT_LITERAL;
                  }
{REAL_LITERAL}    { yylval.element = insert_temp_element(number_line);
                   yylval.element->value->f = atof(yytext);
                   set_element_type(yylval.element, REAL_TYPE);
                   print_token(REAL_LITERAL); return REAL_LITERAL;
                 }
{CHAR_LITERAL}   { yylval.element = insert_temp_element(number_line);
                   yylval.element->value->c = yytext[1];              //Use index 1 because index 0 is the ' symbol
                   set_element_type(yylval.element, CHAR_TYPE);
                   print_token(CHAR_LITERAL); return CHAR_LITERAL;
                 }
{BOOL_LITERAL}   { yylval.element = insert_temp_element(number_line);
                   (strcmp(yytext, "true") == 0) ? (yylval.element->value->b=true) : (yylval.element->value->b=false);
                   set_element_type(yylval.element, BOOL_TYPE);
                   print_token(BOOL_LITERAL); return BOOL_LITERAL;
                 }
{ID}             { elem* el = create_element(strdup(yytext), number_line);  //Create a variable of type elem, and set its name to yytext
                   yylval.element = el;
                   print_token(ID); return ID;
                 }
{STRING_LITERAL} { yylval.element = insert_temp_element(number_line);
                   yylval.element->value->s = malloc(yyleng * sizeof(char));  //Remove start/end quote
                   strcpy(yytext, strtok(yytext, "\"")); strcpy(yylval.element->value->s, yytext);
                   set_element_type(yylval.element, STRING_TYPE);
                   print_token(STRING_LITERAL); return STRING_LITERAL;
                 }

[ \t\r\f]+  { /* skip spaces */ }
\n          { number_line+=1;   }

.           { yyerror("Unrecognized character: %s", yytext); }

%%

/** C functions to print verbose information to screen **/

void verbose_print(const char* token) {
    if (verbose==true)
        printf(" FLEX: Line %2d: token %s for text %s\n", number_line, token, yytext);
}

void print_token (int token) {
    const char* token_str = get_token_name(token);
    verbose_print(token_str);
}

//Print the error to string and terminate the program. Note that the function is an extension over printf
void yyerror (char* str, ...) {
    va_list varlist;
    va_start (varlist, str);

    fprintf(stderr, "\nFatal error on line %d: ", number_line);
    vfprintf (stderr, str, varlist);
    fprintf(stderr, "\n");

    va_end (varlist);

    print_table();

    exit(1);
}
