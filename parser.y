%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex(void);

typedef struct Symbol {
    char *name;
    char *type;
    int value;  // store int values only for now
    struct Symbol *next;
} Symbol;

Symbol *symbol_table = NULL;

Symbol* lookup(char *name);
void insert_symbol(char *name, char *type, int value);
void print_symbol_table();

%}

%union {
    int num;
    char* id;
}

%token INT RETURN IF ELSE
%token <num> NUM
%token <id> ID

%token ASSIGN SEMI LPAREN RPAREN LBRACE RBRACE PLUS MINUS MUL DIV

%type <num> expr

%left PLUS MINUS
%left MUL DIV


%%

program:
    statements
    {
        printf("\nParsing completed.\n\nSymbol Table:\n");
        print_symbol_table();
    }
    ;

statements:
    statements statement
    |
    ;

statement:
    INT ID ASSIGN expr SEMI
    {
        if (lookup($2) != NULL) {
            fprintf(stderr, "Error: Variable '%s' already declared.\n", $2);
        } else {
            insert_symbol($2, "int", $4);
            printf("Parsed declaration: int %s = %d\n", $2, $4);
        }
        free($2);
    }
    | RETURN expr SEMI
    {
        printf("Parsed return statement: return %d\n", $2);
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
    LBRACE statements RBRACE
    ;

expr:
    expr PLUS expr { $$ = $1 + $3; }
    | expr MINUS expr { $$ = $1 - $3; }
    | expr MUL expr { $$ = $1 * $3; }
    | expr DIV expr
      {
          if ($3 == 0) {
              fprintf(stderr, "Error: Division by zero.\n");
              $$ = 0;
          } else {
              $$ = $1 / $3;
          }
      }
    | LPAREN expr RPAREN { $$ = $2; }
    | NUM { $$ = $1; }
    | ID
      {
          Symbol *sym = lookup($1);
          if (sym == NULL) {
              fprintf(stderr, "Error: Undeclared variable '%s'\n", $1);
              $$ = 0;
          } else {
              $$ = sym->value;
          }
          free($1);
      }
    ;

%%

// Symbol table functions

Symbol* lookup(char *name) {
    Symbol *current = symbol_table;
    while (current != NULL) {
        if (strcmp(current->name, name) == 0)
            return current;
        current = current->next;
    }
    return NULL;
}

void insert_symbol(char *name, char *type, int value) {
    Symbol *new_symbol = (Symbol*)malloc(sizeof(Symbol));
    new_symbol->name = strdup(name);
    new_symbol->type = strdup(type);
    new_symbol->value = value;
    new_symbol->next = symbol_table;
    symbol_table = new_symbol;
}

void print_symbol_table() {
    Symbol *current = symbol_table;
    printf("Name\tType\tValue\n");
    printf("-------------------------\n");
    while (current != NULL) {
        printf("%s\t%s\t%d\n", current->name, current->type, current->value);
        current = current->next;
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}

extern FILE *yyin;  // Declared by Flex

int yyparse();      // Declared by Bison

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file.c>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");  // Open the input .c file
    if (!yyin) {
        perror("Error opening file");
        return 1;
    }

    yyparse();  // Start parsing

    fclose(yyin);
    return 0;
}
