%{
#include "../src/app/app.h"

#define YYSTYPE Atributo

using namespace app;

int yylex(void);

%}

%token TK_INTEIRO TK_REAL
%token TK_MAIN TK_ID
%token TK_VAR TK_AS TK_TIPO
%token TK_DIV TK_MENOS_MENOS TK_MAIS_MAIS
%token TK_TRUE TK_FALSE
%token TK_PRINT TK_PRINTLN

%start S

%left TK_AS

%%

S : COMANDOS { iniciarCompilador($1.traducao); } 
	| { cout << "// Programa vazio" << endl; }

COMANDOS: COMANDOS COMANDO { $$.traducao = $1.traducao + $2.traducao;}
	| COMANDO { $$.traducao = $1.traducao; }

COMANDO: '{' COMANDOS '}' { $$.traducao = $2.traducao; }
	| DECLARACAO_VARIAVEL ';' { $$.traducao = $1.traducao; }
    | ATRIBUICAO ';' { $$.traducao = $1.traducao; }
	| EXPRESSAO ';' { $$.traducao = $1.traducao; }
	| IN_OUT ';' { $$.traducao = $1.traducao; }

IN_OUT: TK_PRINT '(' EXPRESSAO ')' {
		debug("Comando de impressão");

		$$.traducao = $3.traducao + "cout << " + $3.label + ";\n";
	}
	| TK_PRINTLN '(' EXPRESSAO ')' {
		debug("Comando de impressão com quebra de linha");
		$$.traducao = $3.traducao + "cout << " + $3.label + " << endl;\n";
	}

DECLARACAO_VARIAVEL: TK_VAR TK_ID '=' EXPRESSAO {
	debug("Declarando variável " + $2.label + " do tipo " + $4.tipo);

	$$.label = gerarTemporaria(false);
	$$.tipo = $4.tipo;

	Variavel *var = buscarVariavel($2.label);

	if (var != NULL) {
		yyerror("Variável " + $2.label + " já declarada");
	}

	criarVariavel($$.label, $2.label, $4.tipo);

	$$.traducao = $4.traducao + $$.label + " = " + $4.label + ";\n";
}

ATRIBUICAO: TK_ID '=' EXPRESSAO {
		$$.label = gerarTemporaria();
		$$.tipo = $3.tipo;

		Variavel *var = buscarVariavel($1.label);

		if (var == NULL) {
			yyerror("Variável " + $1.label + " não declarada");
		}

		if (var->getTipo() != $3.tipo) {
			yyerror("Tipos incompatíveis na atribuição");
		}

		criarVariavel($$.label, $1.label, $3.tipo);

		string traducao = $3.traducao;

		traducao += $$.label + " = " + $3.label + ";\n";

		$$.traducao = traducao; 
	}

EXPRESSAO : TERMO { $$.traducao = $1.traducao; }
	| '(' EXPRESSAO ')' {
		debug("Expressão entre parênteses");
		$$.tipo = $2.tipo;
		$$.label = $2.label;
		$$.traducao = $2.traducao;
	}
	| EXPRESSAO TK_AS TK_TIPO {
		debug("Conversão explícita de tipo do tipo " + $1.tipo + " para " + $3.label);

		string label = converter($1, $3.label, $$.traducao);
		$$.tipo = $3.label;
		$$.label = label;
	}
	| EXPRESSAO '+' TERMO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de soma não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;
		$$.tipo = $1.tipo == "float" || $3.tipo == "float" ? "float" : "int";

		string label1 = converter($1, $$.tipo, $$.traducao);
		string label2 = converter($3, $$.tipo, $$.traducao);

		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao += $$.label + " = " + label1 + " + " + label2 + ";\n";
	}
	| EXPRESSAO '-' TERMO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de subtração não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;
		$$.tipo = $1.tipo == "float" || $3.tipo == "float" ? "float" : "int";

		string label1 = converter($1, $$.tipo, $$.traducao);
		string label2 = converter($3, $$.tipo, $$.traducao);

		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao += $$.label + " = " + label1 + " - " + label2 + ";\n";
	}

TERMO : UNARIO { $$ = $1; }
	| TERMO '*' UNARIO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de divisão não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;
		$$.tipo = $1.tipo == "float" || $3.tipo == "float" ? "float" : "int";

		string label1 = converter($1, $$.tipo, $$.traducao);
		string label2 = converter($3, $$.tipo, $$.traducao);

		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao += $$.label + " = " + label1 + " * " + label2 + ";\n";
	}
	| TERMO TK_DIV UNARIO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de divisão não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string label1 = converter($1, "int", $$.traducao);
		string label2 = converter($3, "int", $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = "int";

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao += $$.label + " = " + label1 + " / " + label2 + ";\n";
	}
	| TERMO '/' UNARIO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de divisão não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string label1 = converter($1, "float", $$.traducao);
		string label2 = converter($3, "float", $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = "float";

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao += $$.label + " = " + label1 + " / " + label2 + ";\n";
	}

UNARIO : PRIMARIO { $$ = $1; }
	| '+' PRIMARIO {
		debug("Operação de '+' unário para tipo " + $2.tipo);

		if (!isNumerico($2.tipo)) {
			yyerror("Operação de '+' unário não permitido para tipo " + $2.tipo);
		}

		$$.label = gerarTemporaria();
		$$.tipo = $2.tipo;

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao = $2.traducao + $$.label + " = " + $2.label + ";\n";
	}
	| '-' PRIMARIO {
		debug("Operação de '-' unário para tipo " + $2.tipo);

		if (!isNumerico($2.tipo)) {
			yyerror("Operação de '-' unário não permitido para tipo " + $2.tipo);
		}


		$$.label = gerarTemporaria();
		$$.tipo = $2.tipo;

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao = $2.traducao + $$.label + " = -" + $2.label + ";\n";
	}

PRIMARIO : TK_INTEIRO {
		debug("Criado novo número inteiro " + $1.label);

		$$.label = gerarTemporaria();
		$$.tipo = "int";

		criarVariavel($$.label, $$.label, "int", true);

		$$.traducao = $$.label + " = " + $1.label + ";\n";
	}
	| TK_REAL {
		debug("Criado novo número real " + $1.label);

		$$.label = gerarTemporaria();
		$$.tipo = "float";

		criarVariavel($$.label, $$.label, "float", true);

		$$.traducao = $$.label + " = " + $1.label + ";\n";
	}
	| TK_TRUE {
		debug("Criado novo booleano true");

		$$.label = gerarTemporaria();
		$$.tipo = "bool";

		criarVariavel($$.label, $$.label, "bool", true);

		$$.traducao = $$.label + " = true;\n";
	}
	| TK_FALSE {
		debug("Criado novo booleano false");

		$$.label = gerarTemporaria();
		$$.tipo = "bool";

		criarVariavel($$.label, $$.label, "bool", true);

		$$.traducao = $$.label + " = false;\n";
	}
	| TK_ID {
		Variavel *var = buscarVariavel($1.label);

		if (var == NULL) {
			yyerror("Variável " + $1.label + " não declarada");
		}

		debug("Usando variável " + $1.label + "...");

		$$.label = var->getNome();
		$$.tipo = var->getTipo();
	}

%%

#include "lex.yy.c"

int yyparse();

int main(int argc, char* argv[])
{
	if (argc >= 1) {
		for (int i = 1; i < argc; i++) {
			if (string(argv[i]) == "--debug") {
				setDebugMode(true);
			} else if (string(argv[i]) == "--simplify") {
				setSimplified(true);
			}
		}
	}

	yyparse();
	return 0;
}