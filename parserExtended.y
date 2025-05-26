%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "semantic.h"      // For symbol table functions
#include "intermediate.h"  // For intermediate code generation

void yyerror(const char *s);
int yylex(void);

extern FILE *yyin;  // from Flex

int tempVarCount = 1;

%}

%union {
    int num;
    char *str;
    struct {
        int val;
        char name[20];
    } exprInfo;
}

%token <str> HEADER_FILE
%token PREPROCESSOR_INCLUDE
%token INT RETURN IF ELSE
%token <num> NUM
%token <str> ID
%token ASSIGN SEMI LPAREN RPAREN LBRACE RBRACE PLUS MINUS MUL DIV

%type <exprInfo> expr

%left PLUS MINUS
%left MUL DIV

%%

start:
    program
    {
        printf("\nParsing completed.\n\nSymbol Table:\n");
        print_symbol_table();

        printCode();
    }
;

program:
    program_element
    | program program_element
;

program_element:
    function_definition
    | statement
;

function_definition:
    INT ID LPAREN RPAREN block
    {
        printf("Parsed function definition: int %s()\n", $2);
        free($2);
    }
;

statement:
    PREPROCESSOR_INCLUDE HEADER_FILE
    {
        printf("Parsed preprocessor directive: #include %s\n", $2);
        free($2);
    }
    | INT ID ASSIGN expr SEMI
    {
        if (lookup($2) != NULL) {
            fprintf(stderr, "Error: Variable '%s' already declared.\n", $2);
        } else {
            insert_symbol($2, "int", $4.val);
            generateCode("=", $4.name, "", $2);
            printf("Parsed declaration: int %s = %d\n", $2, $4.val);
        }
        free($2);
    }
    | RETURN expr SEMI
    {
        printf("Parsed return statement: return %d\n", $2.val);
    }
    | IF LPAREN expr RPAREN block ELSE block
    {
        printf("Parsed if-else statement\n");
    }
    | IF LPAREN expr RPAREN block
    {
        printf("Parsed if statement\n");
    }
;

block:
    LBRACE program RBRACE
;

expr:
    expr PLUS expr
    {
        $$.val = $1.val + $3.val;
        sprintf($$.name, "t%d", tempVarCount++);
        generateCode("+", $1.name, $3.name, $$.name);
    }
    | expr MINUS expr
    {
        $$.val = $1.val - $3.val;
        sprintf($$.name, "t%d", tempVarCount++);
        generateCode("-", $1.name, $3.name, $$.name);
    }
    | expr MUL expr
    {
        $$.val = $1.val * $3.val;
        sprintf($$.name, "t%d", tempVarCount++);
        generateCode("*", $1.name, $3.name, $$.name);
    }
    | expr DIV expr
    {
        if ($3.val == 0) {
            fprintf(stderr, "Error: Division by zero.\n");
            $$.val = 0;
            strcpy($$.name, "0");
        } else {
            $$.val = $1.val / $3.val;
            sprintf($$.name, "t%d", tempVarCount++);
            generateCode("/", $1.name, $3.name, $$.name);
        }
    }
    | LPAREN expr RPAREN
    {
        $$.val = $2.val;
        strcpy($$.name, $2.name);
    }
    | NUM
    {
        $$.val = $1;
        sprintf($$.name, "%d", $1);
    }
    | ID
    {
        Symbol *sym = lookup($1);
        if (sym == NULL) {
            fprintf(stderr, "Error: Undeclared variable '%s'\n", $1);
            $$.val = 0;
            strcpy($$.name, "0");
        } else {
            $$.val = sym->value;
            strcpy($$.name, $1);
        }
        free($1);
    }
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file.c>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Error opening file");
        return 1;
    }

    init_symbol_table();  // From semantic.c
    yyparse();

    fclose(yyin);
    return 0;
}
