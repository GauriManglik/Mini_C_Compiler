#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "intermediate.h"

typedef struct
{
    char op[10];
    char arg1[20];
    char arg2[20];
    char result[20];
} CodeLine;

CodeLine code[1000];
int codeIndex = 0;

void generateCode(const char *op, const char *arg1, const char *arg2, const char *result)
{
    strcpy(code[codeIndex].op, op);
    strcpy(code[codeIndex].arg1, arg1);
    strcpy(code[codeIndex].arg2, arg2);
    strcpy(code[codeIndex].result, result);
    codeIndex++;
}

void printCode()
{
    printf("\nIntermediate Code:\n");
    for (int i = 0; i < codeIndex; i++)
    {
        if (strcmp(code[i].op, "=") == 0 && strcmp(code[i].arg2, "") == 0)
            printf("%s = %s\n", code[i].result, code[i].arg1); // better for assignments
        else
            printf("%s = %s %s %s\n", code[i].result, code[i].arg1, code[i].op, code[i].arg2);
    }
}