// semantic.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "semantic.h"

Symbol *symbol_table = NULL;

void init_symbol_table() {
    symbol_table = NULL;
}

Symbol* lookup(const char *name) {
    Symbol *current = symbol_table;
    while (current) {
        if (strcmp(current->name, name) == 0)
            return current;
        current = current->next;
    }
    return NULL;
}

void insert_symbol(const char *name, const char *type, int value) {
    Symbol *new_sym = (Symbol*)malloc(sizeof(Symbol));
    new_sym->name = strdup(name);
    new_sym->type = strdup(type);
    new_sym->value = value;
    new_sym->next = symbol_table;
    symbol_table = new_sym;
}

void print_symbol_table() {
    printf("\nSymbol Table:\n");
    printf("Name    Type    Value\n");
    printf("-------------------------\n");
    Symbol *current = symbol_table;
    while (current) {
        printf("%s\t%s\t%d\n", current->name, current->type, current->value);
        current = current->next;
    }
}
