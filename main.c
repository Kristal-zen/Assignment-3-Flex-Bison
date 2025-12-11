/* main.c */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "parser.tab.h"

/* Flex/Bison external declarations */
typedef struct yy_buffer_state *YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char *str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);
extern int yyparse(void);

/* Shared state variables from parser.y and scanner.l */
extern int has_assign;
extern char invalid_token_text[256];
extern int parse_error;
extern char error_reason[256];
extern int saw_assign_lhs_complex;
extern int last_token_was_op;
extern int seen_invalid_token;

/**
 * Check if a line contains only whitespace characters
 */
static int is_whitespace_only(const char *line)
{
    while (*line) {
        if (!isspace((unsigned char)*line))
            return 0;
        line++;
    }
    return 1;
}

/**
 * Remove trailing whitespace (including newlines) from a string in-place
 */
static void trim_trailing_whitespace(char *str)
{
    if (!str || !*str)
        return;
    
    char *end = str + strlen(str) - 1;
    while (end >= str && isspace((unsigned char)*end)) {
        *end = '\0';
        end--;
    }
}

/**
 * Reset all parser state variables before parsing a new line
 */
static void reset_parser_state(void)
{
    has_assign = 0;
    invalid_token_text[0] = '\0';
    parse_error = 0;
    error_reason[0] = '\0';
    saw_assign_lhs_complex = 0;
    last_token_was_op = 0;
    seen_invalid_token = 0;
}

/**
 * Parse a single line and print the result
 */
static void parse_and_print_line(const char *line)
{
    char line_copy[1024];
    
    /* Make a clean copy and remove trailing whitespace */
    strncpy(line_copy, line, sizeof(line_copy) - 1);
    line_copy[sizeof(line_copy) - 1] = '\0';
    trim_trailing_whitespace(line_copy);
    
    /* Skip empty or whitespace-only lines */
    if (is_whitespace_only(line_copy)) {
        return;
    }
    
    /* Prepare input buffer for flex (must end with newline) */
    char parse_buffer[2048];
    snprintf(parse_buffer, sizeof(parse_buffer), "%s\n", line_copy);
    
    /* Reset state before parsing */
    reset_parser_state();
    
    /* Parse the line */
    YY_BUFFER_STATE buffer_state = yy_scan_string(parse_buffer);
    yyparse();
    yy_delete_buffer(buffer_state);
    
    /* Print result */
    if (!parse_error) {
        printf("%s -- valid\n", line_copy);
    } else {
        /* Ensure we always have an error reason */
        if (error_reason[0] == '\0') {
            snprintf(error_reason, sizeof(error_reason), "invalid expression");
        }
        printf("%s -- invalid: %s\n", line_copy, error_reason);
    }
}

/**
 * Process an entire file line by line
 */
static int process_file(const char *filename)
{
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        fprintf(stderr, "Error: Could not open file '%s'\n", filename);
        return 1;
    }
    
    char line_buffer[1024];
    int line_number = 0;
    
    while (fgets(line_buffer, sizeof(line_buffer), fp)) {
        line_number++;
        
        /* Check for lines that are too long */
        size_t len = strlen(line_buffer);
        if (len > 0 && line_buffer[len - 1] != '\n' && !feof(fp)) {
            fprintf(stderr, "Warning: Line %d exceeds buffer size\n", line_number);
        }
        
        parse_and_print_line(line_buffer);
    }
    
    fclose(fp);
    return 0;
}

int main(int argc, char *argv[])
{
    const char *filename = "scanme.txt";
    
    /* Allow user to specify input file via command line */
    if (argc > 1) {
        filename = argv[1];
    }
    
    return process_file(filename);
}