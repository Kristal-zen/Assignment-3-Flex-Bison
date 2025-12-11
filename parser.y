/* parser.y */
%{
#include <stdio.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);

/* Shared state variables */
int has_assign = 0;                     /* Set to 1 when we see an '=' token */
char invalid_token_text[256];           /* Holds the text of invalid tokens from lexer */
int parse_error = 0;                    /* Set to 1 when parsing fails */
char error_reason[256];                 /* The error message to display */
int saw_assign_lhs_complex = 0;         /* Set when left side of '=' is not a simple ID */
int last_token_was_op = 0;              /* Tracks consecutive operators for "op op" detection */
int seen_invalid_token = 0;             /* Prevents overwriting first invalid token */
%}

/* Token declarations */
%token ID           /* Identifiers: letters followed by letters/digits */
%token ASSIGN       /* Assignment operator: = */
%token OP           /* Arithmetic operators: + - * / % */
%token SEMI         /* Semicolon: ; */
%token LPAREN       /* Left parenthesis: ( */
%token RPAREN       /* Right parenthesis: ) */
%token NEWLINE      /* End of line */
%token INVALID      /* Any invalid token detected by lexer */

%start line

%%

/* A line is either a statement followed by newline, or just a newline */
line
    : stmt NEWLINE
    | NEWLINE           /* Allow blank/empty lines */
    ;

/* A statement is either an assignment or an expression */
stmt
    : assignment
    | expression
    ;

/* Valid assignment: ID = expression ; */
assignment
    : ID ASSIGN expression SEMI
    /* Missing semicolon after assignment */
    | ID ASSIGN expression error {
        if (error_reason[0] == '\0') {
            snprintf(error_reason, sizeof(error_reason), "invalid assignment");
        }
        YYERROR;
    }
    /* Catches cases like "bad / min = fourth ;" where LHS is not a simple ID */
    | error ASSIGN expression SEMI {
        if (error_reason[0] == '\0') {
            saw_assign_lhs_complex = 1;
        }
        YYERROR;
    }
    ;

/* Expression: chain of terms connected by operators */
expression
    : term
    | expression OP term
    ;

/* Term: just a factor (can be extended for precedence if needed) */
term
    : factor
    ;

/* Factor: ID, parenthesized expression, or invalid token */
factor
    : ID
    | LPAREN expression RPAREN
    | INVALID {
        /* Handle invalid tokens *here* so we always report the right thing */
        parse_error = 1;

        if (error_reason[0] == '\0') {
            if (invalid_token_text[0] != '\0') {
                if (strcmp(invalid_token_text, "op op") == 0) {
                    snprintf(error_reason, sizeof(error_reason), "op op");
                } else {
                    snprintf(error_reason, sizeof(error_reason),
                             "invalid token \"%s\"", invalid_token_text);
                }
            } else {
                /* Fallback, should rarely happen */
                snprintf(error_reason, sizeof(error_reason),
                         "invalid expression");
            }
        }

      }
    ;

%%

/**
 * Error handler called by parser when syntax error occurs.
 * Sets appropriate error message based on the type of error detected.
 */
void yyerror(const char *s) {
    (void)s;  /* Unused parameter */

    parse_error = 1;

    /* Don't overwrite existing error reason */
    if (error_reason[0] != '\0')
        return;

    /* If we got here without factor's INVALID action handling it,
       fall back to the previous priority rules. */

    /* Priority 1: Invalid token from lexer (highest priority) */
    if (invalid_token_text[0] != '\0') {
        if (strcmp(invalid_token_text, "op op") == 0) {
            snprintf(error_reason, sizeof(error_reason), "op op");
        } else {
            snprintf(error_reason, sizeof(error_reason),
                     "invalid token \"%s\"", invalid_token_text);
        }
    }
    /* Priority 2: Complex left-hand side of assignment */
    else if (saw_assign_lhs_complex) {
        snprintf(error_reason, sizeof(error_reason),
                 "invalid assignment");
    }
    /* Priority 3: Assignment-related errors (missing semicolon, etc.) */
    else if (has_assign) {
        snprintf(error_reason, sizeof(error_reason),
                 "invalid assignment");
    }
    /* Priority 4: General expression errors (default) */
    else {
        snprintf(error_reason, sizeof(error_reason),
                 "invalid expression");
    }
}
