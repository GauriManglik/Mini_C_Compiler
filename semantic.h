// semantic.h
#ifndef SEMANTIC_H
#define SEMANTIC_H

typedef struct Symbol {
    char *name;
    char *type;
    int value;
    struct Symbol *next;
} Symbol;

void init_symbol_table();
Symbol* lookup(const char *name);
void insert_symbol(const char *name, const char *type, int value);
void print_symbol_table();

#endif
