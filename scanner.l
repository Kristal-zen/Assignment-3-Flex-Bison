
%{
#include <stdio.h>
#include <string.h>
#include "parser.tab.h"

/* Shared state from parser.y */
extern int has_assign;
extern char invalid_token_text[256];
extern int last_token_was_op;
extern int seen_invalid_token;
%}

%option noyywrap

%%

[ \t]+              ;

"("                 { last_token_was_op = 0; return LPAREN; }
")"                 { last_token_was_op = 0; return RPAREN; }

"="                 {
                        if (last_token_was_op && !seen_invalid_token) {
                            snprintf(invalid_token_text, sizeof(invalid_token_text), "op op");
                            seen_invalid_token = 1;
                            last_token_was_op = 0;
                            return INVALID;
                        }
                        has_assign = 1;
                        last_token_was_op = 1;
                        return ASSIGN;
                    }

";"                 { last_token_was_op = 0; return SEMI; }

"+-"                {
                        if (!seen_invalid_token) {
                            snprintf(invalid_token_text, sizeof(invalid_token_text), "%s", yytext);
                            seen_invalid_token = 1;
                        }
                        last_token_was_op = 0;
                        return INVALID;
                    }

[+\-*/%]            {
                        if (last_token_was_op && !seen_invalid_token) {
                            snprintf(invalid_token_text, sizeof(invalid_token_text), "op op");
                            seen_invalid_token = 1;
                            last_token_was_op = 0;
                            return INVALID;
                        }
                        last_token_was_op = 1;
                        return OP;
                    }

[A-Za-z][A-Za-z0-9]* {
                        last_token_was_op = 0;
                        return ID;
                    }

[0-9][A-Za-z][A-Za-z0-9]* {
                        if (!seen_invalid_token) {
                            snprintf(invalid_token_text, sizeof(invalid_token_text), "%s", yytext);
                            seen_invalid_token = 1;
                        }
                        last_token_was_op = 0;
                        return INVALID;
                    }

[0-9]+             {
                        last_token_was_op = 0;
                        return ID;
                    }

\n                 { last_token_was_op = 0; return NEWLINE; }

.                  {
                        if (!seen_invalid_token) {
                            snprintf(invalid_token_text, sizeof(invalid_token_text), "%s", yytext);
                            seen_invalid_token = 1;
                        }
                        last_token_was_op = 0;
                        return INVALID;
                    }

%%
