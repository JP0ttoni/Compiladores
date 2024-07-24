%{
#include "../src/app/compilador.h"

#define YYSTYPE Atributo

using namespace compilador;

int yylex(void);

%}

%token TK_TIPO TK_INTEIRO TK_REAL TK_STRING TK_CHAR
%token TK_ID TK_MAIS_IGUAL TK_MENOS_IGUAL TK_VEZES_IGUAL TK_DIV_IGUAL
%token TK_VAR TK_AS
%token TK_DIV TK_MENOS_MENOS TK_MAIS_MAIS
%token TK_TRUE TK_FALSE
%token TK_PRINT TK_PRINTLN TK_SCANF TK_SIZE
%token TK_AND TK_OR TK_NOT
%token TK_IGUAL TK_DIFERENTE TK_MAIOR TK_MENOR TK_MAIOR_IGUAL TK_MENOR_IGUAL
%token TK_IF TK_ELSE TK_DO TK_WHILE TK_FOR 
%token TK_BREAK TK_CONTINUE
%token TK_SWITCH TK_CASE TK_DEFAULT
%token TK_RETURN

%start S

%nonassoc TK_IGUAL TK_DIFERENTE TK_MAIOR TK_MENOR TK_MAIOR_IGUAL TK_MENOR_IGUAL '?' ':'
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
	| BREAK_CONTINUE OPCIONAL { $$.traducao = $1.traducao; }
	| RETORNO_FUNCAO OPCIONAL { $$.traducao = $1.traducao; }
	| DEFINICAO_FUNCAO { $$.traducao = $1.traducao; }
	| SWITCH_COMANDO { $$.traducao = $1.traducao; }
	| CONDICIONAL { $$.traducao = $1.traducao; }
	| LOOP { $$.traducao = $1.traducao; }

BREAK_CONTINUE : TK_BREAK {
		BreakContinue* topo = topoBreakContinue();

		if (topo == NULL) {
			yyerror("Comando break fora de loop");
		}

		$$.traducao = "goto " + topo->getFimLabel() + ";\n";
	}
	| TK_CONTINUE {
		BreakContinue* topo = topoContinue();

		if (topo == NULL) {
			yyerror("Comando continue fora de loop");
		}

		$$.traducao = "goto " + topo->getInicioLabel() + ";\n";
	}

CRIAR_CONTEXTO: '{' {
		debug("Criando novo contexto...");
		criarContexto();
	}

OPCIONAL : ';' {} | {}

CONDICIONAL : TK_IF '(' EXPRESSAO ')' COMANDO %prec IF {
		if ($3.tipo != BOOL_TIPO) {
			yyerror("Condição do if deve ser do tipo bool");
		}

		string temp = gerarTemporaria();
		string ifLabel = gerarLabel();

		criarVariavel(temp, temp, BOOL_TIPO, true);

		$$.traducao = $3.traducao + "if (!" + $3.label + ") goto " + ifLabel + ";\n" + $5.traducao + ifLabel + ":\n";
	}
	| TK_IF '(' EXPRESSAO ')' COMANDO TK_ELSE COMANDO {
		if ($3.tipo != BOOL_TIPO) {
			yyerror("Condição do if deve ser do tipo bool");
		}

		string temp = gerarTemporaria();
		string ifLabel = gerarLabel();
		string elseLabel = gerarLabel();

		criarVariavel(temp, temp, BOOL_TIPO, true);

		$$.traducao = $3.traducao + "if (!" + $3.label + ") goto " + elseLabel + ";\n" + $5.traducao + "goto " + ifLabel + ";\n" + elseLabel + ":\n" + $7.traducao + ifLabel + ":\n";
	}

LOOP : WHILE '(' EXPRESSAO ')' COMANDO {
		debug("Comando de loop while");

		if ($3.tipo != BOOL_TIPO) {
			yyerror("Condição do while deve ser do tipo bool");
		}

		string temp = gerarTemporaria();
		BreakContinue* topo = topoBreakContinue();

		string inicioLabel = topo->getInicioLabel();
		string fimLabel = topo->getFimLabel();

		criarVariavel(temp, temp, BOOL_TIPO, true);

		$$.traducao = inicioLabel + ":\n" + $3.traducao + "if (!" + $3.label + ") goto " + fimLabel + ";\n" + $5.traducao + "goto " + inicioLabel + ";\n" + fimLabel + ":\n";
		removerBreakContinue();
	}
	| DO COMANDO TK_WHILE '(' EXPRESSAO ')' {
		debug("Comando do-while");

		if ($5.tipo != BOOL_TIPO) {
			yyerror("Condição do while deve ser do tipo bool");
		}

		string temp = gerarTemporaria();
		BreakContinue* topo = topoBreakContinue();

		string inicioLabel = topo->getInicioLabel();
		string fimLabel = topo->getFimLabel();

		criarVariavel(temp, temp, BOOL_TIPO, true);

		$$.traducao = inicioLabel + ":\n" + $2.traducao + $5.traducao + "if (!" + $5.label + ") goto " + fimLabel + ";\n" + "goto " + inicioLabel + ";\n" + fimLabel + ":\n";
		removerBreakContinue();
	}
	| FOR '(' FOR_INICIALIZADOR ';' EXPRESSAO ';' MULTIPLA_EXPRESSOES ')' COMANDO {
		debug("Comando de loop for");

		if ($5.tipo != BOOL_TIPO) {
			yyerror("Condição do for deve ser do tipo bool");
		}

		string temp = gerarTemporaria();

		BreakContinue* topo = topoBreakContinue();

		string inicioLabel = topo->getInicioLabel();
		string fimLabel = topo->getFimLabel();

		criarVariavel(temp, temp, BOOL_TIPO, true);

		$$.traducao = $3.traducao + inicioLabel + ":\n" + $5.traducao + "if (!" + $5.label + ") goto " + fimLabel + ";\n" + $9.traducao + $7.traducao + "goto " + inicioLabel + ";\n" + fimLabel + ":\n";
		removerBreakContinue();
	}

WHILE: TK_WHILE {
		string whileLabel = gerarLabel();
		string finalLabel = gerarLabel();

		adicionarBreakContinue(whileLabel, finalLabel);
	}

FOR: TK_FOR {
		string forLabel = gerarLabel();
		string finalLabel = gerarLabel();

		adicionarBreakContinue(forLabel, finalLabel);
	}

DO: TK_DO {
		string doLabel = gerarLabel();
		string finalLabel = gerarLabel();

		adicionarBreakContinue(doLabel, finalLabel);
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

	if ($$.tipo == "void") {
		yyerror("A variável " + $2.label + " está recebendo uma expressão do tipo void...");
	}

	$$.dimensoes = $4.dimensoes;
	$$.tamanho = $4.tamanho;

	if ($$.tamanho > 0) {
		criarArray($$.label, $2.label, $$.tipo, false, $$.dimensoes, $$.tamanho);
	} else {
		criarVariavel($$.label, $2.label, $4.tipo);
	}

	$$.traducao = $4.traducao;

	if ($4.tipo == STRING_TIPO && $$.tamanho == 0) {
		$$.traducao += $$.label + " = copiarString(" + $4.label + ");\n";
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

		if ($3.tipo == STRING_TIPO && $$.tamanho == 0) {
			$$.traducao += $$.label + " = copiarString(" + $3.label + ");\n";
		} else {
			$$.traducao += $$.label + " = " + $3.label + ";\n";
		} 
	}
	| TK_ID ARRAY_SELECTOR '=' EXPRESSAO {
		debug("Atribuindo valor à variável " + $1.label);

		Variavel *var = buscarVariavel($1.label);

		if (var == NULL) {
			yyerror("Variável " + $1.label + " não declarada");
		}

		if (var->getTipo() != $4.tipo) {
			yyerror("Tipos incompatíveis na atribuição");
		}

		int* realDimensoes = var->getDimensoes();

		vector<string> arraySelectorDimensoes = fatiaString($2.label, ", ");

		if (arraySelectorDimensoes.size() != var->getTamanho()) {
			yyerror("Número de dimensões do array " + $1.label + " não corresponde ao número de dimensões informado");
		}

		int* dimensoes = (int*) malloc(sizeof(int) * var->getTamanho());

		for (int i = 0; i < var->getTamanho(); i++) {
			dimensoes[i] = stoi(arraySelectorDimensoes[i]);
		}

		int posicao = calcularPosicaoArray(realDimensoes, dimensoes, var->getTamanho());

		$$.label = var->getNome() + "[" + to_string(posicao) + "]";
		$$.tipo = var->getTipo();
		$$.traducao = $4.traducao;

		if ($4.tipo == STRING_TIPO) {
			$$.traducao += $$.label + " = copiarString(" + $4.label + ");\n";
		} else {
			$$.traducao += $$.label + " = " + $4.label + ";\n";
		}
	}
	| TK_ID TK_MAIS_IGUAL EXPRESSAO {
		debug("Atribuição de soma à variável " + $1.label);

		Variavel *var = buscarVariavel($1.label);

		if (var == NULL) {
			yyerror("Variável " + $1.label + " não declarada");
		}

		if (!isNumerico(var->getTipo()) || !isNumerico($3.tipo)) {
			yyerror("Operação de soma não permitida para tipos " + var->getTipo() + " e " + $3.tipo);
		}

		Atributo atributo;

		$$.tipo = var->getTipo();
		$$.label = var->getNome();
		$$.traducao = $3.traducao;

		atributo.tipo = var->getTipo();
		atributo.label = var->getNome();
		atributo.traducao = "";
		atributo.dimensoes = var->getDimensoes();
		atributo.tamanho = var->getTamanho();

		string label1 = converter(atributo, $$.tipo, $$.traducao);
		string label2 = converter($3, $$.tipo, $$.traducao);

		$$.traducao += $$.label + " = " + label1 + " + " + label2 + ";\n";
	}
	| TK_ID TK_MENOS_IGUAL EXPRESSAO {
		debug("Atribuição de subtração à variável " + $1.label);

		Variavel *var = buscarVariavel($1.label);

		if (var == NULL) {
			yyerror("Variável " + $1.label + " não declarada");
		}

		if (!isNumerico(var->getTipo()) || !isNumerico($3.tipo)) {
			yyerror("Operação de subtração não permitida para tipos " + var->getTipo() + " e " + $3.tipo);
		}

		Atributo atributo;

		$$.tipo = var->getTipo();
		$$.label = var->getNome();
		$$.traducao = $3.traducao;

		atributo.tipo = var->getTipo();
		atributo.label = var->getNome();
		atributo.traducao = "";
		atributo.dimensoes = var->getDimensoes();
		atributo.tamanho = var->getTamanho();

		string label1 = converter(atributo, $$.tipo, $$.traducao);
		string label2 = converter($3, $$.tipo, $$.traducao);

		$$.traducao += $$.label + " = " + label1 + " - " + label2 + ";\n";
	}

EXPRESSAO : TERMO { $$ = $1; }
	| EXPRESSAO '+' TERMO {
		if (isNumerico($1.tipo) && isNumerico($3.tipo)) {
			$$.traducao = $1.traducao + $3.traducao;
			$$.tipo = $1.tipo == FLOAT_TIPO || $3.tipo == FLOAT_TIPO ? FLOAT_TIPO : INT_TIPO;

			string label1 = converter($1, $$.tipo, $$.traducao);
			string label2 = converter($3, $$.tipo, $$.traducao);

			$$.label = gerarTemporaria();

			criarVariavel($$.label, $$.label, $$.tipo, true);

			$$.traducao += $$.label + " = " + label1 + " + " + label2 + ";\n";
		} else if ($1.tipo == STRING_TIPO || $3.tipo == STRING_TIPO) {
			$$.traducao = $1.traducao + $3.traducao;
			$$.tipo = STRING_TIPO;

			string label1 = converter($1, STRING_TIPO, $$.traducao);
			string label2 = converter($3, STRING_TIPO, $$.traducao);

			$$.label = gerarTemporaria();

			criarVariavel($$.label, $$.label, STRING_TIPO, true);

			$$.traducao += $$.label + " = concatenarString(" + label1 + "," + label2 + ");\n";
		} else {
			yyerror("Operação de soma/concatenação não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}
	}
	| EXPRESSAO '-' TERMO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de subtração não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;
		$$.tipo = $1.tipo == FLOAT_TIPO || $3.tipo == FLOAT_TIPO ? FLOAT_TIPO : INT_TIPO;

		string label1 = converter($1, $$.tipo, $$.traducao);
		string label2 = converter($3, $$.tipo, $$.traducao);

		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao += $$.label + " = " + label1 + " - " + label2 + ";\n";
	}
	| EXPRESSAO TK_AND TERMO {
		$$.traducao = $1.traducao + $3.traducao;
		$$.tipo = BOOL_TIPO;

		string label1 = converter($1, BOOL_TIPO, $$.traducao);
		string label2 = converter($3, BOOL_TIPO, $$.traducao);

		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, BOOL_TIPO, true);

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
		$$.tipo = BOOL_TIPO;

		criarVariavel($$.label, $$.label, BOOL_TIPO, true);

		if (isNumerico($1.tipo) && isNumerico($3.tipo)) {
			string tipo = $1.tipo == FLOAT_TIPO || $3.tipo == FLOAT_TIPO ? FLOAT_TIPO : INT_TIPO;

			string label1 = converter($1, tipo, $$.traducao);
			string label2 = converter($3, tipo, $$.traducao);

			$$.traducao += $$.label + " = " + label1 + " == " + label2 + ";\n";
		} else if ($1.tipo == STRING_TIPO) {
			$$.traducao += $$.label + " = igualdadeStrings(" + $1.label + "," + $3.label + ");\n";
		} else {
			$$.traducao += $$.label + " = " + $1.label + " == " + $3.label + ";\n";
		}
	}
	| EXPRESSAO TK_DIFERENTE EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			if ($1.tipo != $3.tipo) {
				yyerror("Tipos incompatíveis na comparação");
			}
		}

		$$.traducao = $1.traducao + $3.traducao;

		$$.label = gerarTemporaria();
		$$.tipo = BOOL_TIPO;

		criarVariavel($$.label, $$.label, BOOL_TIPO, true);

		if (isNumerico($1.tipo) && isNumerico($3.tipo)) {
			string tipo = $1.tipo == FLOAT_TIPO || $3.tipo == FLOAT_TIPO ? FLOAT_TIPO : INT_TIPO;

			string label1 = converter($1, tipo, $$.traducao);
			string label2 = converter($3, tipo, $$.traducao);

			$$.traducao += $$.label + " = " + label1 + " != " + label2 + ";\n";
		} else if ($1.tipo == STRING_TIPO) {
			$$.traducao += $$.label + " = igualdadeStrings(" + $1.label + "," + $3.label + ");\n";
			$$.traducao += $$.label + " = !" + $$.label + ";\n";
		} else {
			$$.traducao += $$.label + " = " + $1.label + " != " + $3.label + ";\n";
		}
	}
	| EXPRESSAO TK_MAIOR EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de comparação não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string tipo = $1.tipo == FLOAT_TIPO || $3.tipo == FLOAT_TIPO ? FLOAT_TIPO : INT_TIPO;

		string label1 = converter($1, tipo, $$.traducao);
		string label2 = converter($3, tipo, $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = BOOL_TIPO;

		criarVariavel($$.label, $$.label, BOOL_TIPO, true);

		$$.traducao += $$.label + " = " + label1 + " > " + label2 + ";\n";
	}
	| EXPRESSAO TK_MENOR EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de comparação não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string tipo = $1.tipo == FLOAT_TIPO || $3.tipo == FLOAT_TIPO ? FLOAT_TIPO : INT_TIPO;

		string label1 = converter($1, tipo, $$.traducao);
		string label2 = converter($3, tipo, $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = BOOL_TIPO;

		criarVariavel($$.label, $$.label, BOOL_TIPO, true);

		$$.traducao += $$.label + " = " + label1 + " < " + label2 + ";\n";
	}
	| EXPRESSAO TK_MAIOR_IGUAL EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de comparação não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string tipo = $1.tipo == FLOAT_TIPO || $3.tipo == FLOAT_TIPO ? FLOAT_TIPO : INT_TIPO;

		string label1 = converter($1, tipo, $$.traducao);
		string label2 = converter($3, tipo, $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = BOOL_TIPO;

		criarVariavel($$.label, $$.label, BOOL_TIPO, true);

		$$.traducao += $$.label + " = " + label1 + " >= " + label2 + ";\n";
	}
	| EXPRESSAO TK_MENOR_IGUAL EXPRESSAO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de comparação não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string tipo = $1.tipo == FLOAT_TIPO || $3.tipo == FLOAT_TIPO ? FLOAT_TIPO : INT_TIPO;

		string label1 = converter($1, tipo, $$.traducao);
		string label2 = converter($3, tipo, $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = BOOL_TIPO;

		criarVariavel($$.label, $$.label, BOOL_TIPO, true);

		$$.traducao += $$.label + " = " + label1 + " <= " + label2 + ";\n";
	}
	| EXPRESSAO '?' EXPRESSAO ':' EXPRESSAO {
		if ($1.tipo != BOOL_TIPO) {
			yyerror("Condição do operador ternário deve ser do tipo bool");
		}

		if ($3.tipo != $5.tipo) {
			yyerror("Tipos incompatíveis no operador ternário");
		}

		$$.traducao = $1.traducao + $3.traducao + $5.traducao;

		$$.tipo = $3.tipo;
		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, $$.tipo, true);

		string ifLabel = gerarLabel();
		string elseLabel = gerarLabel();

		$$.traducao += "if (" + $1.label + ") goto " + ifLabel + ";\n" + $$.label + " = " + $5.label + ";\n" + "goto " + elseLabel + ";\n" + ifLabel + ":\n" + $$.label + " = " + $3.label + ";\n" + elseLabel + ":\n";
	}

TERMO : UNARIO { $$ = $1; }
	| TERMO '*' UNARIO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de divisão não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;
		$$.tipo = $1.tipo == FLOAT_TIPO || $3.tipo == FLOAT_TIPO ? FLOAT_TIPO : INT_TIPO;

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

		string label1 = converter($1, INT_TIPO, $$.traducao);
		string label2 = converter($3, INT_TIPO, $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = INT_TIPO;

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao += $$.label + " = " + label1 + " / " + label2 + ";\n";
	}
	| TERMO '/' UNARIO {
		if (!isNumerico($1.tipo) || !isNumerico($3.tipo)) {
			yyerror("Operação de divisão não permitida para tipos " + $1.tipo + " e " + $3.tipo);
		}

		$$.traducao = $1.traducao + $3.traducao;

		string label1 = converter($1, FLOAT_TIPO, $$.traducao);
		string label2 = converter($3, FLOAT_TIPO, $$.traducao);

		$$.label = gerarTemporaria();
		$$.tipo = FLOAT_TIPO;

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao += $$.label + " = " + label1 + " / " + label2 + ";\n";
	}
	| TERMO TK_OR UNARIO {
		$$.traducao = $1.traducao + $3.traducao;
		$$.tipo = BOOL_TIPO;

		string label1 = converter($1, BOOL_TIPO, $$.traducao);
		string label2 = converter($3, BOOL_TIPO, $$.traducao);

		$$.label = gerarTemporaria();

		criarVariavel($$.label, $$.label, BOOL_TIPO, true);

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

		if ($2.tipo != BOOL_TIPO) {
			yyerror("Operação de 'not' unário não permitido para tipo " + $2.tipo);
		}

		$$.label = gerarTemporaria();
		$$.tipo = BOOL_TIPO;

		criarVariavel($$.label, $$.label, $$.tipo, true);

		$$.traducao = $2.traducao + $$.label + " = !" + $2.label + ";\n";
	}

PRIMARIO : PRIMITIVO {
		debug ("Criando variável para o primitivo " + $1.label + " do tipo " + $1.tipo);

		$$.label = gerarTemporaria();
		$$.tipo = $1.tipo;
		
		criarVariavel($$.label, $$.label, $$.tipo, true);

		if ($1.tipo == STRING_TIPO) {
			string stringReal = fatiaString($1.label, "\"")[1];
			string stringValor = "\"" + stringReal + "\""; 

			$$.traducao = $$.label + ".str = (char*) malloc(" + to_string(stringReal.size()) + ");\n";

			for (int i = 0; i < stringReal.size(); i++) {
				$$.traducao += $$.label + ".str[" + to_string(i) + "] = '" + stringReal[i] + "';\n";
			}

			$$.traducao += $$.label + ".tamanho = " + to_string(stringReal.size()) + ";\n";
		} else {
			$$.traducao = $$.label + " = " + $1.label + ";\n";
		}
 	}
	| ARRAY {
		$$ = $1;
	}
	| FUNCTIONS {
		$$.label = $1.label;
		$$.tipo = $1.tipo;
		$$.traducao = $1.traducao;
	}
	| '(' EXPRESSAO ')' {
		debug("Expressão entre parênteses");

		$$.tipo = $2.tipo;
		$$.label = $2.label;
		$$.traducao = $2.traducao;
		$$.dimensoes = $2.dimensoes;
		$$.tamanho = $2.tamanho;
	}
	| TK_ID ARRAY_SELECTOR {
		Variavel *var = buscarVariavel($1.label);

		if (var == NULL) {
			yyerror("Variável " + $1.label + " não declarada");
		}

		if (var->getTipo() == "void") {
			yyerror("Variável " + $1.label + " não pode ser usada como expressão");
		}

		if (var->getTamanho() == 0) {
			yyerror("Variável " + $1.label + " não é um array");
		}

		int* realDimensoes = var->getDimensoes();

		vector<string> arraySelectorDimensoes = fatiaString($2.label, ", ");

		if (arraySelectorDimensoes.size() != var->getTamanho()) {
			yyerror("Número de dimensões do array " + $1.label + " não corresponde ao número de dimensões informado");
		}

		int* dimensoes = (int*) malloc(sizeof(int) * var->getTamanho());

		for (int i = 0; i < var->getTamanho(); i++) {
			dimensoes[i] = stoi(arraySelectorDimensoes[i]);
		}

		int posicao = calcularPosicaoArray(realDimensoes, dimensoes, var->getTamanho());

		$$.label = var->getNome() + "[" + to_string(posicao) + "]";
		$$.tipo = var->getTipo();
	}
	| TK_ID {
		Variavel *var = buscarVariavel($1.label);

		if (var == NULL) {
			yyerror("Variável " + $1.label + " não declarada");
		}

		if (var->getTipo() == "void") {
			yyerror("Variável " + $1.label + " não pode ser usada como expressão");
		}

		$$.label = var->getNome();
		$$.tipo = var->getTipo();
		$$.dimensoes = var->getDimensoes();
		$$.tamanho = var->getTamanho();
	}

ARRAY_SELECTOR : '[' PRIMITIVO ']' {
		if ($2.tipo != INT_TIPO) {
			yyerror("Índice de array deve ser do tipo inteiro");
		}

		debug("Seleção de array");

		$$.label = $2.label;
		$$.tipo = INT_TIPO;
	}
	| ARRAY_SELECTOR '[' PRIMITIVO ']' {
		if ($3.tipo != INT_TIPO) {
			yyerror("Índice de array deve ser do tipo inteiro");
		}

		debug("Seleção de array");

		$$.label = $1.label + ", " + $3.label;
		$$.tipo = INT_TIPO;
	}

PRIMITIVO: TK_INTEIRO {
		debug("Criado novo número inteiro " + $1.label);

		$$.label = $1.label;
		$$.tipo = INT_TIPO;
	}
	| TK_CHAR {
		debug("Criado novo caractere " + $1.label);

		$$.label = $1.label;
		$$.tipo = "char";
	}
	| TK_STRING {
		debug("Criado nova string " + $1.label);

		$$.label = $1.label;
		$$.tipo = STRING_TIPO;
	}
	| TK_REAL {
		debug("Criado novo número real " + $1.label);

		$$.label = $1.label;
		$$.tipo = FLOAT_TIPO;
	}
	| TK_TRUE {
		debug("Criado novo booleano true");

		$$.label = $1.label;
		$$.tipo = BOOL_TIPO;
	}
	| TK_FALSE {
		debug("Criado novo booleano false");

		$$.label = $1.label;
		$$.tipo = BOOL_TIPO;
	}

INICIAR_ARRAY : '[' {
		debug("Iniciando array");
		criarArray();
	}

FINALIZAR_ARRAY : ']' {
		Array* topo = removerArray();

		if (getPilhaArraySize() > 0) {
			Array* top = topoArray();

			top->adicionarChild(topo);
			top->setTipo(topo->getTipo());

			$$.label = "Ignore";
		} else {
			int tamanhoTotal = topo->getTamanhoTotal();
			pair<int*, int> dimensoes = topo->getTamanhoDimensoes();

			debug("Criado uma array de tamanho total " + to_string(tamanhoTotal) + ", com " + to_string(dimensoes.second) + " dimensões");

			$$.label = gerarTemporaria();
			$$.tipo = topo->getTipo();
			$$.dimensoes = dimensoes.first;
			$$.tamanho = dimensoes.second;

			criarArray($$.label, $$.label, $$.tipo, true, dimensoes.first, dimensoes.second);
			
			$$.traducao = topo->getTraducao();
			$$.traducao += $$.label + " = (" + $$.tipo + "*) malloc(sizeof(" + $$.tipo + ") * " + to_string(tamanhoTotal) + ");\n";

			vector<string> labels = topo->getRealLabels();

			for (int i = 0; i < labels.size(); i++) {
				if ($$.tipo == STRING_TIPO) {
					$$.traducao += $$.label + "[" + to_string(i) + "] = copiarString(" + labels[i] + ");\n";
				} else {
					$$.traducao += $$.label + "[" + to_string(i) + "] = " + labels[i] + ";\n";
				}
			}
		}
 	}

ARRAY : INICIAR_ARRAY ARRAY_ELEMENTS_NULLABLE FINALIZAR_ARRAY {
		$$ = $3;
	}

ARRAY_ELEMENTS_NULLABLE : ARRAY_ELEMENTS {} | {}

ARRAY_ELEMENTS : EXPRESSAO {
		if ($1.label != "Ignore") {
			Array* topo = topoArray();

			if (!topo->isTipoCompativel($1.tipo)) {
				yyerror("Tipo incompatível no array");
			}

			topo->adicionarLabel($1.label, $1.traducao);
			topo->setTipo($1.tipo);
		}
	}
	| ARRAY_ELEMENTS ',' EXPRESSAO {
		if ($3.label != "Ignore") {
			Array* topo = topoArray();

			if (!topo->isTipoCompativel($3.tipo)) {
				yyerror("Tipo incompatível no array");
			}

			topo->adicionarLabel($3.label, $3.traducao);
			topo->setTipo($1.tipo);
		}
	}

RETORNO_FUNCAO: TK_RETURN EXPRESSAO {
		debug("Comando de retorno de função");

		Funcao* funcao = getFuncaoDefinindo();

		if (funcao == NULL) {
			yyerror("Comando de retorno fora de função");
		}

		if (funcao->getRetorno() == "void") {
			yyerror("A função " + funcao->getNome() + " foi declarada como void, então não pode ter retorno");
		}

		if (funcao->getRetorno() != $2.tipo) {
			yyerror("Tipo de retorno incompatível com a função");
		}

		Contexto* contexto = topoContexto();

		contexto->setHasReturn(true);

		$$.traducao = $2.traducao;
		$$.traducao += "return " + $2.label + ";\n";
	}

FUNCTIONS: TK_PRINT '(' EXPRESSAO ')' {
		debug("Comando de impressão");

		$$.traducao = $3.traducao;

		string label = converter($3, STRING_TIPO, $$.traducao);

		$$.tipo = "void";
		$$.traducao += "cout << " + label + ".str;\n";
	}
	| TK_PRINTLN '(' EXPRESSAO ')' {
		debug("Comando de impressão com quebra de linha");

		$$.traducao = $3.traducao;

		string label = converter($3, STRING_TIPO, $$.traducao);

		$$.tipo = "void";
		$$.traducao += "cout << " + label + ".str << endl;\n";
	}
	| TK_SCANF '(' ')' {
		debug("Comando de leitura");

		$$.label = gerarTemporaria();
		$$.tipo = STRING_TIPO;

		criarVariavel($$.label, $$.label, STRING_TIPO, true);

		$$.traducao = $$.label + " = lerEntrada();\n";
	}
	| TK_SIZE '(' EXPRESSAO ')' {
		debug("Comando de tamanho de string");

		$$.label = gerarTemporaria();
		$$.tipo = INT_TIPO;

		criarVariavel($$.label, $$.label, INT_TIPO, true);

		string size = "";

		if ($3.tipo == STRING_TIPO) {
			size = $3.label + ".tamanho";
		} else {
			size = "1";
		}

		$$.traducao = $3.traducao + $$.label + " = " + size + ";\n";
	}
	| TK_ID '(' ARGUMENTOS ')' {
		debug("Chamada de função");

		string label = $3.label;

		list<string> argumentos;
		vector<string> args = fatiaString(label, ", ");

		string chamada = "";
		string argumentosChamada = "";

		for (int i = 0; i < args.size(); i++) {
			string arg = args[i];
			vector<string> argSplit = fatiaString(arg, ":");

			string argLabel = argSplit[0];
			string argTipo = argSplit[1];

			argumentos.push_back(argTipo);
			chamada += argLabel + (i < args.size() - 1 ? ", " : "");
			argumentosChamada += argTipo + (i < args.size() - 1 ? ", " : "");
			debug("Adicionado na lista de argumentos " + argLabel + " do tipo " + argTipo);
		}

		Funcao *funcao = buscarFuncao($1.label, argumentos);

		if (funcao == NULL) {
			yyerror("Não existe nenhuma função com nome " + $1.label + " e argumentos dos tipos " + argumentosChamada + " (nesta na ordem).");
		}

		$$.traducao = $3.traducao;

		$$.tipo = funcao->getRetorno();

		if (funcao->getRetorno() == "void") {
			$$.traducao += funcao->getNome() + "(" + chamada+ ");\n";
		} else {
			$$.label = gerarTemporaria();

			criarVariavel($$.label, $$.label, $$.tipo, true);

			if (funcao->getRetorno() == STRING_TIPO) {
				string label = gerarTemporaria();
				
				criarVariavel(label, label, STRING_TIPO, true);

				$$.traducao += label + " = " + funcao->getNome() + "(" + chamada + ");\n";
				$$.traducao += $$.label + " = copiarString(" + label + ");\n";
			} else {
				$$.traducao += $$.label + " = " + funcao->getNome() + "(" + chamada + ");\n";
			}
		}

	}

ARGUMENTOS: ARGUMENTOS ',' EXPRESSAO { 
		$$.traducao = $1.traducao + $3.traducao;
		$$.label = $1.label + ", " + $3.label + ":" + $3.tipo;
	}
	| EXPRESSAO { 
		if ($1.tamanho > 0) {
			yyerror("Argumento de função não pode ser um array");
		}
		
		$$.traducao = $1.traducao; $$.label = $1.label + ":" + $1.tipo;
	}
	| { $$.traducao = ""; }

DEFINICAO_FUNCAO: INICIAR_FUNCAO '(' PARAMETROS ')' '{' COMANDOS '}' {
		debug("Definindo função " + $2.label);

		Funcao* funcao = getFuncaoDefinindo();

		funcao->setTraducao($6.traducao);

		$$.label = $2.label;
		$$.tipo = "void";

		if (funcao->getRetorno() != "void") {
			Contexto* contexto = topoContexto();

			if (!contexto->hasReturn()) {
				yyerror("A função " + $2.label + " precisa ter pelo menos 1 retorno no contexto principal");
			}
		}

		criarFuncao(funcao);
		removeDefinicaoFuncao();
		removerContexto();
	}

INICIAR_FUNCAO: TK_TIPO TK_ID {
		debug("Criando uma nova inicialização de uma função... " + $2.label);

		criarContexto();
		criarDefinicaoFuncao($2.label, $1.label);

		$$.label = $2.label;
	}

PARAMETROS: PARAMETROS ',' PARAMETRO { $$.traducao = $1.traducao + $3.traducao; }
	| PARAMETRO { $$.traducao = $1.traducao; }
	| { $$.traducao = ""; }

PARAMETRO: TK_TIPO TK_ID {
		debug("Criando parâmetro " + $2.label + " do tipo " + $1.label);

		Funcao* funcao = getFuncaoDefinindo();

		$$.label = $2.label;
		$$.tipo = $1.label;

		funcao->adicionarParametro($2.label, $1.label);
	}


SWITCH_COMANDO: INICIAR_SWITCH CASES '}' {
		debug("Comando switch-case");
		Switch* sw = topoSwitch();

		string fimLabel = sw->getFimLabel();

		$$.traducao = $1.traducao;

		$$.traducao += sw->criarSwitchTable();
		$$.traducao += fimLabel + ":\n";

		removerSwitch();
		removerBreakContinue();
	}

CASES: CASES CASE { $$.traducao = $1.traducao + $2.traducao; }
	| { $$.traducao = ""; }

CASE: TK_CASE PRIMITIVO ':' COMANDOS {
		Switch* sw = topoSwitch();

		if (sw == NULL) {
			yyerror("Comando case fora de switch");
		}

		if ($2.tipo != sw->getTipo()) {
			yyerror("Tipos incompatíveis no switch-case");
		}

		sw->adicionarCaso($2.label, $4.traducao);
	}
	| TK_DEFAULT ':' COMANDO {
		Switch* sw = topoSwitch();

		if (sw == NULL) {
			yyerror("Comando default fora de switch");
		}

		sw->adicionarDefault($3.traducao);
	}

INICIAR_SWITCH: TK_SWITCH '(' EXPRESSAO ')' '{' {
		debug("Iniciando switch-case");

		string breakLabel = gerarLabel();

		criarSwitch($3. label, $3.tipo, breakLabel);
		adicionarBreakContinue("", breakLabel);

		$$.traducao = $3.traducao;
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