#include <string>
#include <vector>
#include <fstream>
#include <sstream>

#include "bison.h"

using namespace bison;

#pragma once
namespace app {

    bool isDebugMode = false;
    bool isSimplified = false;

    int contadorVariavel = 1;
    int contadorVariavelTemporaria = 1;

    typedef struct {
        string label;
        string tipo;
        string traducao;
    } Atributo;

    void setDebugMode(bool debug) {
        isDebugMode = debug;
    }

    void setSimplified(bool simplified) {
        isSimplified = simplified;
    }

    void debug(string message) {
        if (isDebugMode) {
            cout << message << endl;
        }
    }

    class Variavel {
        private:
            string nome;
            string apelido;
            string tipo;
        public:
            Variavel(string nome, string apelido, string tipo) {
                this->nome = nome;
                this->apelido = apelido;
                this->tipo = tipo;
            }

            string getNome() {
                return this->nome;
            }

            string getApelido() {
                return this->apelido;
            }

            string getTipo() {
                return this->tipo;
            }
    };

    vector<Variavel*> tabelaSimbolos;

    void iniciarCompilador(string traducaoGeral) {
        ifstream file("src/app/inter/codigo-intermediario.cpp");

        if (!file.is_open()) {
            yyerror("Arquivo de código intermediário não encontrado");
        }

        stringstream buffer;
        buffer << file.rdbuf();
        file.close();

        vector<string> splittedContent = fatiaString(buffer.str(), "/*-=-*/");

        if (!isSimplified) {
            cout << splittedContent[0];
        }
        
        string traducao = "/* Variáveis */\n\n";
        
        for (int i = 0; i < tabelaSimbolos.size(); i++) {
            traducao += tabelaSimbolos[i]->getTipo() + " " + tabelaSimbolos[i]->getNome() + ";\n";
        }

        traducao += "\nint main(void) {\n" + formataCodigo(traducaoGeral) + "\treturn 0;\n}";
                        
        cout << traducao;
        
        if (!isSimplified) {
            cout << splittedContent[1];
        }

        cout << endl;
    }

    /**
     * Cria uma variável na tabela de símbolos
     * 
     * @param nome - Nome da variável
     * @param apelido - Apelido da variável
     * @param tipo - Tipo da variável
     * @param temporaria - Indica se a variável é temporária
     * 
     * @return Variavel - Ponteiro para a variável criada
     */

    Variavel* criarVariavel(string nome, string apelido, string tipo, bool temporaria = false) {
        for (int i = 0; i < tabelaSimbolos.size(); i++) {
            if (tabelaSimbolos[i]->getApelido() == apelido) {
                yyerror("Variável " + nome + " já foi declarada");
            }
        }

        string apelidoEfetivo = temporaria ? "§" + apelido : apelido;

        Variavel *variavel = new Variavel(nome, apelidoEfetivo, tipo);
        tabelaSimbolos.push_back(variavel);
        return variavel;
    }

    /**
     * Cria uma variável auxiliar que definirá o tamanho da string
     * 
     * @param label - Nome da célula de memória que armazenará a variável
     * @param tamanho - Tamanho da string
     * 
     * @return string - Código intermediário gerado
     */

    string criarString(string label, string tamanho) {
        Variavel* variavel = criarVariavel(label + "_size", label + "_size", "int", true);
        return variavel->getNome() + " = " + tamanho + ";\n";
    }

    /**
     * Busca uma variável na tabela de símbolos pelo apelido
     * 
     * @param apelido - Apelido da variável
     * 
     * @return Variavel - Ponteiro para a variável encontrada
     */

    Variavel* buscarVariavel(string apelido) {
        for (int i = 0; i < tabelaSimbolos.size(); i++) {
            if (tabelaSimbolos[i]->getApelido() == apelido) {
                return tabelaSimbolos[i];
            }
        }

        return NULL;
    }
    
    string gerarTemporaria(bool temp = true) {
        if (temp) {
            return "t" + to_string(contadorVariavelTemporaria++);
        }

        return "v" + to_string(contadorVariavel++);
    }

    /**
     * Converter a variável 1 no tipo 2
     */

    string converter(const Atributo &atributo, string tipoDestino, string &translation) {
        if (atributo.tipo == tipoDestino) {
            return atributo.label;
        }

        string label = gerarTemporaria();
        Variavel *var = criarVariavel(label, label, tipoDestino, true);
        debug("Convertendo " + atributo.label + " de " + atributo.tipo + " para " + tipoDestino);

        if (atributo.tipo == "int") {
            if (tipoDestino == "float") {
                translation += label + " = " + "(float) " + atributo.label + ";\n";
            } else if (tipoDestino == "bool") {
                translation += label + " = " + atributo.label + " != 0;\n";
            }
        } else if (atributo.tipo == "float") {
            if (tipoDestino == "int") {
                translation += label + " = " + "(int) " + atributo.label + ";\n";
            } else if (tipoDestino == "bool") {
                translation += label + " = " + atributo.label + " != 0.0;\n";
            }
        }

        return label;
    }

    bool isNumerico(string tipo) {
        return tipo == "int" || tipo == "float";
    }

}