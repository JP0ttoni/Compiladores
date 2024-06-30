#include <string>
#include <vector>
#include <list>
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
    int contadorLabel = 1;

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

    class Contexto {
        private:
            list<Variavel*> variaveis;
        public:
            Contexto() {
                this->variaveis = list<Variavel*>();
            }

            /**
             * Cria uma variável na tabela de símbolos
             * 
             * @param nome - Nome da variável
             * @param apelido - Apelido da variável
             * @param tipo - Tipo da variável
             * 
             * @return Variavel - Ponteiro para a variável criada
             */

            Variavel* criarVariavel(string nome, string apelido, string tipo) {
                for (list<Variavel*>::iterator it = this->variaveis.begin(); it != this->variaveis.end(); ++it) {
                    if ((*it)->getApelido() == apelido) {
                        yyerror("Variável asdasd " + nome + " já foi declarada");
                    }
                }

                debug("Criando variável " + nome + " do tipo " + tipo + " com apelido " + apelido);

                Variavel *variavel = new Variavel(nome, apelido, tipo);
                this->variaveis.push_back(variavel);
                return variavel;
            }

            /**
             * Busca uma variável na tabela de símbolos pelo apelido
             * 
             * @param apelido - Apelido da variável
             * 
             * @return Variavel - Ponteiro para a variável encontrada
             */

            Variavel* buscarVariavel(string apelido) {
                for (list<Variavel*>::iterator it = this->variaveis.begin(); it != this->variaveis.end(); ++it) {
                    if ((*it)->getApelido() == apelido) {
                        return *it;
                    }
                }

                return NULL;
            }
    };

    list<Contexto*> pilhaContextos;
    vector<Variavel*> tabelaSimbolos;

    Contexto* criarContexto() {
        Contexto *contexto = new Contexto();
        pilhaContextos.push_back(contexto);
        return contexto;
    }

    void removerContexto() {
        pilhaContextos.pop_back();
    }

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
        Contexto* contexto = pilhaContextos.back();
        Variavel* variavel = contexto->criarVariavel(nome, apelido, tipo);
        tabelaSimbolos.push_back(variavel);
        return variavel;
    }

    /**
     * Busca uma variável na tabela de símbolos pelo apelido
     * 
     * @param apelido - Apelido da variável
     * 
     * @return Variavel - Ponteiro para a variável encontrada
     */

    Variavel* buscarVariavel(string apelido) {
        for (list<Contexto*>::reverse_iterator it = pilhaContextos.rbegin(); it != pilhaContextos.rend(); ++it) {
            Variavel *variavel = (*it)->buscarVariavel(apelido);

            if (variavel != NULL) {
                return variavel;
            }
        }

        return NULL;
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
        Variavel* variavel = buscarVariavel("$" + label + "_size");

        if (variavel == NULL) {
            variavel = criarVariavel(label + "_size", "$" + label + "_size", "int");
            debug("Criando string " + label + ".");
        }

        return variavel->getNome() + " = " + tamanho + ";\n";
    }
    
    string gerarTemporaria(bool temp = true) {
        if (temp) {
            return "t" + to_string(contadorVariavelTemporaria++);
        }

        return "v" + to_string(contadorVariavel++);
    }

    string gerarLabel() {
        return "label" + to_string(contadorLabel++);
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
            } else if (tipoDestino == "char*") {
                translation += label + " = " + "intToString(" + atributo.label + ");\n";
                translation += criarString(label, "calcularTamanhoString(" + label + ")");
            } else {
                yyerror("Conversão de " + atributo.tipo + " para " + tipoDestino + " não suportada");
            }
        } else if (atributo.tipo == "float") {
            if (tipoDestino == "int") {
                translation += label + " = " + "(int) " + atributo.label + ";\n";
            } else if (tipoDestino == "bool") {
                translation += label + " = " + atributo.label + " != 0.0;\n";
            } else if (tipoDestino == "char*") {
                translation += label + " = " + "floatToString(" + atributo.label + ");\n";
                translation += criarString(label, "calcularTamanhoString(" + label + ")");
            } else {
                yyerror("Conversão de " + atributo.tipo + " para " + tipoDestino + " não suportada");
            }
        } else {
            yyerror("Conversão de " + atributo.tipo + " para " + tipoDestino + " não suportada");
        }

        return label;
    }

    bool isNumerico(string tipo) {
        return tipo == "int" || tipo == "float";
    }

}