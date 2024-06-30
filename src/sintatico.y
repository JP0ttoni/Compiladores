%{
#include "../src/app/app.h"

#define YYSTYPE Atributo

using namespace app;

int yylex(void);

%}

%token TK_TIPO TK_INTEIRO TK_REAL TK_STRING TK_CHAR
%token TK_ID
%token TK_VAR TK_AS
%token TK_DIV TK_MENOS_MENOS TK_MAIS_MAIS
%token TK_TRUE TK_FALSE
%token TK_PRINT TK_PRINTLN TK_SCANF TK_SIZE
%token TK_AND TK_OR TK_NOT
%token TK_IGUAL TK_DIFERENTE TK_MAIOR TK_MENOR TK_MAIOR_IGUAL TK_MENOR_IGUAL
%token TK_IF TK_ELSE TK_DO TK_WHILE TK_FOR

%start S

%left TK_AS
%nonassoc TK_IGUAL TK_DIFERENTE TK_MAIOR TK_MENOR TK_MAIOR_IGUAL TK_MENOR_IGUAL 
%nonassoc '+' '-' TK_AND TK_OR

%nonassoc IF
%nonassoc TK_ELSE

%%

S : COMANDOS { iniciarCompilador($1.traducao); }

COMANDOS: COMANDOS COMANDO { $$.traducao = $1.traducao + $2.traducao;}
	| { $$.traducao = ""; }

COMANDO: CRIAR_CONTEXTO COMANDOS '}' { $$.traducao = $2.traducao; debug("Removendo contexto"); removerContexto(); }
	| DECLARACAO_VARIAVEL OPCIONAL { $$.traducao = $1.traducao; }
    | ATRIBUICAO OPCIONAL { $$.traducao = $1.traducao; }
	| FUNCTIONS OPCIONAL { $$.traducao = $1.traducao; }
	| CONDICIONAL { $$.traducao = $1.traducao; }
	| LOOP { $$.traducao = $1.traducao; }

CRIAR_CONTEXTO: '{' {
		debug("Criando novo contexto...");
		criarContexto();
	}

OPCIONAL : ';' {} | {}

CONDICIONAL : TK_IF '(' EXPRESSAO ')' COMANDO %prec IF {
		if ($3.tipo != "bool") {
			yyerror("Condição do if deve ser do tipo bool");
		}

		string temp = gerarTemporaria();
		string ifLabel = gerarLabel();

		criarVariavel(temp, temp, "bool", true);

		$$.traducao = $3.traducao + "if (!" + $3.label + ") goto " + ifLabel + ";\n" + $5.traducao + ifLabel + ":\n";
	}
	| TK_IF '(' EXPRESSAO ')' COMANDO TK_ELSE COMANDO {
		if ($3.tipo != "bool") {
			yyerror("Condição do if deve ser do tipo bool");
		}

		string temp = gerarTemporaria();
		string ifLabel = gerarLabel();
		string elseLabel = gerarLabel();

		criarVariavel(temp, temp, "bool", true);

		$$.traducao = $3.traducao + "if (!" + $3.label + ") goto " + elseLabel + ";\n" + $5.traducao + "goto " + ifLabel + ";\n" + elseLabel + ":\n" + $7.traducao + ifLabel + ":\n";
	}

LOOP : TK_WHILE '(' EXPRESSAO ')' COMANDO {
		debug("Comando de loop while");

		if ($3.tipo != "bool") {
			yyerror("Condição do while deve ser do tipo bool");
		}

		string temp = gerarTemporaria();
		string whileLabel = gerarLabel();
		string endLabel = gerarLabel();

		criarVariavel(temp, temp, "bool", true);

		$$.traducao = whileLabel + ":\n" + $3.traducao + "if (!" + $3.label + ") goto " + endLabel + ";\n" + $5.traducao + "goto " + whileLabel + ";\n" + endLabel + ":\n";
	}
	| TK_DO COMANDO TK_WHILE '(' EXPRESSAO ')' {
		debug("Comando do-while");

		if ($5.tipo != "bool") {
			yyerror("Condição do while deve ser do tipo bool");
		}

		string temp = gerarTemporaria();
		string whileLabel = gerarLabel();
		string endLabel = gerarLabel();

		criarVariavel(temp, temp, "bool", true);

		$$.traducao = whileLabel + ":\n" + $2.traducao + $5.traducao + "if (!" + $5.label + ") goto " + endLabel + ";\n" + "goto " + whileLabel + ";\n" + endLabel + ":\n";
	}
	| TK_FOR '(' FOR_INICIALIZADOR ';' EXPRESSAO ';' MULTIPLA_EXPRESSOES ')' COMANDO {
		debug("Comando de loop for");

		if ($5.tipo != "bool") {
			yyerror("Condição do for deve ser do tipo bool");
		}

		string temp = gerarTemporaria();
		string forLabel = gerarLabel();
		string endLabel = gerarLabel();

		criarVariavel(temp, temp, "bool", true);

		$$.traducao = $3.traducao + forLabel + ":\n" + $5.traducao + "if (!" + $5.label + ") goto " + endLabel + ";\n" + $9.traducao + $7.traducao + "goto " + forLabel + ";\n" + endLabel + ":\n";
	}

FOR_INICIALIZADOR: DECLARACAO_VARIAVEL { $$.traducao = $1.traducao; }
	| MULTIPLA_ATRIBUICAO { $$.traducao = $1.traducao; }
	| { $$.traducao = ""; }

MULTIPLA_ATRIBUICAO : ATRIBUICAO { $$.traducao = $1.traducao; }
	| MULTIPLA_ATRIBUICAO ',' ATRIBUICAO { $$.traducao = $1.traducao + $3.traducao; }

EXPRESSAO_ATRIBUICAO: EXPRESSAO { $$.traducao = $1.traducao; }
	| ATRIBUICAO { $$.traducao = $1.traducao; }

MULTIPLA_EXPRESSOES: EXPRESSAO_ATRIBUICAO { $$.traducao = $1.traducao; }
	| MULTIPLA_EXPRESSOES ',' EXPRESSAO_ATRIBUICAO { $$.traducao = $1.traducao + $3.traducao; }
	| { $$.traducao = ""; }

DECLARACAO_VARIAVEL: TK_VAR TK_ID '=' EXPRESSAO {
	debug("Declarando variável " + $2.label + " do tipo " + $4.tipo);

	$$.label = gerarTemporaria(false);
	$$.tipo = $4.tipo;

	Variavel *var = buscarVariavel($2.label);

	criarVariavel($$.label, $2.label, $4.tipo);

	$$.traducao = $4.traducao;

	if ($4.tipo == "char*") {
		$$.traducao += criarString($$.label, $4.label + "_size");
		$$.traducao += $$.label + " = copiarString(" + $4.label + ", " + $4.label + "_size);\n";
	} else {
		$$.traducao +=  $$.label + " = " + $4.label + ";\n";
	}
}

ATRIBUICAO: TK_ID '=' EXPRESSAO {
		debug("Atribuindo valor à variável " + $1.label);

		Variavel *var = buscarVariavel($1.label);

		if (var == NULL) {
			yyerror("Variável " + $1.label + " não declarada");
		}

		if (var->getTipo() != $3.tipo) {
			yyerror("Tipos incompatíveis na atribuição");
		}

		$$.tipo = $3.tipo;
		$$.label = var->getNome();
		$$.traducao = $3.traducao;

		if ($3.tipo == "char*") {
			$$.traducao += criarString($$.label, $3.label + "_size");
			$$.traducao += $$.label + " = copiarString(" + $3.label + ", " + $3.label + "_size);\n";
		} else {
			$$.traducao += $$.label + " = " + $3.label + ";\n";
		} 
	}

EXPRESSAO : TERMO { $$.traducao = $1.traducao; }
	| '(' EXPRESSAO ')' {
		debug("Expressão entre parênteses");
		$$.tipo = $2.tipo;
		$$.label = $2.label;
		$$.traducao = $2.traducao;
	}
	| EXPRESSAO '+' TERMO {
		if (isNumerico($1.tipo) && isNumerico($3.tipo)) {
			$$.traducao = $1.traducao + $3.traducao;
			$$.tipo = $1.tipo == "float" || $3.tipo == "float" ? "float" : "int";

			string label1 = converter($1, $$.tipo, $$.traducao);
			string label2 = converter($3, $$.tipo, $$.traducao);

			$$.label = gerarTemporaria();

			criarVariavel($$.label, $$.label, $$.tipo, true);

			$$.traducao += $$.label + " = " + label1 + " + " + label2 + ";\n";
		} else if ($1.tipo == "char*" || $3.tipo == "char*") {
			$$.traducao = $1.traducao + $3.traducao;
			$$.tipo = "char*";

			string label1 = converter($1, "char*", $$.traducao);
			string label2 = converter($3, "char*", $$.traducao);

			$$.label = gerarTemporaria();
			
			string somaTamanho = gerarTemporaria();

			$$.traducao += somaTamanho + " = " + label1 + "_size + " + label2 + "_size;\n";

			criarVariavel(somaTamanho, somaTamanho, "int", true);
			criarVariavel($$.label, $$.label, "char*", true);

			$$.traducao += $$.label + " = concatenarString(" + label1 + ", " + label1 + "_size, " + label2 + ", " + label2 + "_size);\n";
			$$.traducao += criarString($$.label, somaTamanho);
		} else {
			yyerror("Operação de soma/concatenação não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}
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
	| EXPRESSAO TK_AND TERMO {
		$$.traducao = $1.traducao + $3.traducao;
		$$.tipo = "bool";

		string label1 = converter($1, "bool", $$.traducao);
		string label2 = converter($3, "bool", $$.traducao);

		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, "bool", true);

		$$.traducao += $$.label + " = " + label1 + " && " + label2 + ";\n";
	}
	| EXPRESSAO TK_IGUAL EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			if ($1.tipo != $3.tipo) {
				yyerror("Tipos incompatíveis na comparação");
			}
		}

		$$.traducao = $1.traducao + $3.traducao;

		$$.label = gerarTemporaria();
		$$.tipo = "bool";

		criarVariavel($$.label, $$.label, "bool", true);

		$$.traducao += $$.label + " = " + $1.label + " == " + $3.label + ";\n";
	}
	| EXPRESSAO TK_DIFERENTE EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			if ($1.tipo != $3.tipo) {
				yyerror("Tipos incompatíveis na comparação");
			}
		}

		$$.traducao = $1.traducao + $3.traducao;

		$$.label = gerarTemporaria();
		$$.tipo = "bool";

		criarVariavel($$.label, $$.label, "bool", true);

		$$.traducao += $$.label + " = " + $1.label + " != " + $3.label + ";\n";
	}
	| EXPRESSAO TK_MAIOR EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de comparação não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string label1 = converter($1, "int", $$.traducao);
		string label2 = converter($3, "int", $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = "bool";

		criarVariavel($$.label, $$.label, "bool", true);

		$$.traducao += $$.label + " = " + label1 + " > " + label2 + ";\n";
	}
	| EXPRESSAO TK_MENOR EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de comparação não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string label1 = converter($1, "int", $$.traducao);
		string label2 = converter($3, "int", $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = "bool";

		criarVariavel($$.label, $$.label, "bool", true);

		$$.traducao += $$.label + " = " + label1 + " < " + label2 + ";\n";
	}
	| EXPRESSAO TK_MAIOR_IGUAL EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de comparação não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string label1 = converter($1, "int", $$.traducao);
		string label2 = converter($3, "int", $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = "bool";

		criarVariavel($$.label, $$.label, "bool", true);

		$$.traducao += $$.label + " = " + label1 + " >= " + label2 + ";\n";
	}
	| EXPRESSAO TK_MENOR_IGUAL EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de comparação não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string label1 = converter($1, "int", $$.traducao);
		string label2 = converter($3, "int", $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = "bool";

		criarVariavel($$.label, $$.label, "bool", true);

		$$.traducao += $$.label + " = " + label1 + " <= " + label2 + ";\n";
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
	| TERMO TK_OR UNARIO {
		$$.traducao = $1.traducao + $3.traducao;
		$$.tipo = "bool";

		string label1 = converter($1, "bool", $$.traducao);
		string label2 = converter($3, "bool", $$.traducao);

		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, "bool", true);

		$$.traducao += $$.label + " = " + label1 + " || " + label2 + ";\n";
	}

UNARIO : PRIMARIO { $$ = $1; }
	| PRIMARIO TK_AS TK_TIPO {
		debug("Conversão explícita de tipo do tipo " + $1.tipo + " para " + $3.label);

		string label = converter($1, $3.label, $$.traducao);
		$$.tipo = $3.label;
		$$.label = label;
	}
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
	| TK_NOT PRIMARIO {
		debug("Operação de 'not' unário para tipo " + $2.tipo);

		if ($2.tipo != "bool") {
			yyerror("Operação de 'not' unário não permitido para tipo " + $2.tipo);
		}

		$$.label = gerarTemporaria();
		$$.tipo = "bool";

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao = $2.traducao + $$.label + " = !" + $2.label + ";\n";
	}

PRIMARIO : TK_INTEIRO {
		debug("Criado novo número inteiro " + $1.label);

		$$.label = gerarTemporaria();
		$$.tipo = "int";

		criarVariavel($$.label, $$.label, "int", true);

		$$.traducao = $$.label + " = " + $1.label + ";\n";
	}
	| TK_CHAR {
		debug("Criado novo caractere " + $1.label);

		$$.label = gerarTemporaria();
		$$.tipo = "char";

		criarVariavel($$.label, $$.label, "char", true);

		$$.traducao = $$.label + " = " + $1.label + ";\n";
	}
	| TK_STRING {
		debug("Criado nova string " + $1.label);

		$$.label = gerarTemporaria();
		$$.tipo = "char*";

		criarVariavel($$.label, $$.label, "char*", true);

		string stringReal = fatiaString($1.label, "\"")[1];
		string stringValor = "\"" + stringReal + "\""; 

		$$.traducao = $$.label + " = (char*) malloc(" + to_string(stringReal.size()) + ");\n";
		$$.traducao += criarString($$.label, to_string(stringReal.size()));

		for (int i = 0; i < stringReal.size(); i++) {
			$$.traducao += $$.label + "[" + to_string(i) + "] = '" + stringReal[i] + "';\n";
		}
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
	| FUNCTIONS {
		$$.label = $1.label;
		$$.tipo = $1.tipo;
		$$.traducao = $1.traducao;
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

FUNCTIONS: TK_PRINT '(' EXPRESSAO ')' {
		debug("Comando de impressão");

		$$.traducao = $3.traducao + "cout << " + $3.label + ";\n";
	}
	| TK_PRINTLN '(' EXPRESSAO ')' {
		debug("Comando de impressão com quebra de linha");
		$$.traducao = $3.traducao + "cout << " + $3.label + " << endl;\n";
	}
	| TK_SCANF '(' ')' {
		debug("Comando de leitura");

		$$.label = gerarTemporaria();
		$$.tipo = "char*";

		criarVariavel($$.label, $$.label, "char*", true);

		$$.traducao = $$.label + " = lerEntrada();\n";
		$$.traducao += criarString($$.label, "calcularTamanhoString(" + $$.label + ")");

	}
	| TK_SIZE '(' EXPRESSAO ')' {
		debug("Comando de tamanho de string");

		$$.label = gerarTemporaria();
		$$.tipo = "int";

		criarVariavel($$.label, $$.label, "int", true);

		string size = "";

		if ($3.tipo == "char*") {
			size = $3.label + "_size";
		} else {
			size = "1";
		}

		$$.traducao = $3.traducao + $$.label + " = " + size + ";\n";
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

	criarContexto();
	yyparse();
	return 0;
}