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

%%

S : COMANDOS { iniciarCompilador($1.traducao); } 

COMANDOS: COMANDO COMANDOS { $$.traducao = $1.traducao + $2.traducao; }
	| { $$.traducao = ""; }

COMANDO: ATRIBUICAO { $$.traducao = $1.traducao; }
	| EXPRESSAO { $$.traducao = $1.traducao; }
	| EOL { $$.traducao = ""; }

ATRIBUICAO: TK_ID '=' EXPRESSAO {
		$$.label = gerarTemporaria(false);
		$$.tipo = $3.tipo;

		Variavel *var = buscarVariavel($1.label);

		if (var != NULL && var->getTipo() != $3.tipo) {
			yyerror("Erro de atribuição: tipos incompatíveis");
		}

		criarVariavel($$.label, $1.label, $3.tipo);

		string traducao = $3.traducao;

		traducao += $$.label + " = " + $3.label + ";\n";

		$$.traducao = traducao; 
	}

EXPRESSAO : TERMO { $$.traducao = $1.traducao; }
	| EXPRESSAO '+' TERMO {
		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, "int", true);

		string traducao = $1.traducao + $3.traducao;

		traducao += $$.label + " = " + $1.label + " + " + $3.label + ";\n";

		$$.traducao = traducao; 
	}
	| EXPRESSAO '-' TERMO {
		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, "int", true);

		string traducao = $1.traducao + $3.traducao;

		traducao += $$.label + " = " + $1.label + " - " + $3.label + ";\n";

		$$.traducao = traducao; 
	}

TERMO : UNARIO { $$ = $1; }
	| TERMO '*' UNARIO {
		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, "int", true);

		string traducao = $1.traducao + $3.traducao;

		traducao += $$.label + " = " + $1.label + " * " + $3.label + ";\n";

		$$.traducao = traducao; 
	}
	| TERMO '/' UNARIO {
		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, "int", true);

		string traducao = $1.traducao + $3.traducao;

		traducao += $$.label + " = " + $1.label + " / " + $3.label + ";\n";

		$$.traducao = traducao; 
	}

UNARIO : PRIMARIO { $$ = $1; }

PRIMARIO : TK_NUM {
		$$.label = gerarTemporaria();
		$$.tipo = "int";

		criarVariavel($$.label, $$.label, "int", true);

		$$.traducao = $$.label + " = " + $1.label + ";\n";
	}
	| TK_ID {
		$$.label = gerarTemporaria();
		$$.tipo = "int";

		criarVariavel($$.label, $$.label, "int", true);

		$$.traducao = $$.label + " = " + $1.label + ";\n";
	}

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