%option noinput nounput
%{
#include "parserExtended.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void print_token(int token, char* lexeme);
%}

%%

"#include"      { return PREPROCESSOR_INCLUDE; }
"<"[a-zA-Z0-9_.]+">"   { yylval.str = strdup(yytext); return HEADER_FILE; }
"int"       { print_token(INT, "int"); return INT; }
"return"    { print_token(RETURN, "return"); return RETURN; }
"if"        { print_token(IF, "if"); return IF; }
"else"      { print_token(ELSE, "else"); return ELSE; }

[0-9]+      {
                print_token(NUM, yytext);
                yylval.num = atoi(yytext);
                return NUM;
            }

[a-zA-Z_][a-zA-Z0-9_]*  {
                print_token(ID, yytext);
                yylval.str = strdup(yytext);
                return ID;
            }




"="         { print_token(ASSIGN, "="); return ASSIGN; }
";"         { print_token(SEMI, ";"); return SEMI; }
"("         { print_token(LPAREN, "("); return LPAREN; }
")"         { print_token(RPAREN, ")"); return RPAREN; }
"{"         { print_token(LBRACE, "{"); return LBRACE; }
"}"         { print_token(RBRACE, "}"); return RBRACE; }
"+"         { print_token(PLUS, "+"); return PLUS; }
"-"         { print_token(MINUS, "-"); return MINUS; }
"*"         { print_token(MUL, "*"); return MUL; }
"/"         { print_token(DIV, "/"); return DIV; }

[ \t\n]+    ; // skip whitespace

.           { print_token(yytext[0], yytext); return yytext[0]; }

%%

void print_token(int token, char* lexeme) {
    printf("Token: %-8d Lexeme: %s\n", token, lexeme);
}

int yywrap(){
    return 1;
}