%{
#include "../src/app/app.h"

#define YYSTYPE CurrentType

using namespace app;

int yylex(void);

%}

%token TK_NUM EOL TK_MINUS_MINUS
%token TK_MAIN TK_ID TK_TIPO_INT
%token TK_FIM TK_ERROR TK_ELOG TK_EQUAL TK_DIFERENT TK_MAIOR_IGUAL TK_MENOR_IGUAL TK_ASPA
%token TK_NEGATIVE TK_OR

%start S

%left '-' '+'
%left '*' '/'

%%

S : COMMANDS { cout << $1.traducao; } 

COMMANDS: COMMAND COMMANDS { $$.traducao = $1.traducao + $2.traducao; }
	| '{' COMMANDS '}' COMMANDS  { $$.traducao = $1.traducao; }
	| { $$.traducao = ""; }

COMMAND: EXPRESSION { $$.traducao = $1.traducao; }

EXPRESSION : TERM { $$.traducao = $1.traducao; }
	| EXPRESSION '+' TERM { $$.traducao = $1.traducao + $3.traducao + "ADD\n"; }
	| EXPRESSION '-' TERM { $$.traducao = $1.traducao + $3.traducao + "SUB\n"; }

TERM : UNARY { $$.traducao = $1.traducao; }
	| TERM '*' UNARY { $$.traducao = $1.traducao + $3.traducao + "MUL\n"; }
	| TERM '/' UNARY { $$.traducao = $1.traducao + $3.traducao + "DIV\n"; }

UNARY : FACTOR { $$.traducao = $1.traducao; }


FACTOR : TK_NUM { $$.traducao = "PUSH " + $1.label + "\n"; }

%%

#include "lex.yy.c"

int yyparse();

int main(int argc, char* argv[])
{
	yyparse();
	return 0;
}

void yyerror(string MSG)
{
	cout << MSG << endl;
	exit (0);
}