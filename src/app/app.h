#include <string>
#include <vector>
#include <list>
#include <fstream>
#include <sstream>

#include "bison.h"

using namespace bison;

#pragma once
namespace app {

    const string STRING_TIPO = "String";
    const string CHAR_TIPO = "char";
    const string INT_TIPO = "int";
    const string FLOAT_TIPO = "float";
    const string BOOL_TIPO = "bool";

    bool isDebugMode = false;
    bool isSimplified = false;

    int contadorVariavel = 1;
    int contadorFuncao = 1;
    int contadorVariavelTemporaria = 1;
    int contadorLabel = 1;

    int contadorLinha = 1;

    typedef struct {
        string label;
        string tipo;
        string traducao;
    } Atributo;

    void adicionarLinha() {
        contadorLinha++;
    }

    int getLinhaAtual() {
        return contadorLinha;
    }

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

    void yyerror(string mensagem, string codigoErro = "Erro de sintaxe") {
        cout << codigoErro << ": " << mensagem << " (linha: " << getLinhaAtual() << ")" << endl;
        exit(1);
    }

    string gerarTemporaria(bool temp = true) {
        if (temp) {
            return "t" + to_string(contadorVariavelTemporaria++);
        }

        return "v" + to_string(contadorVariavel++);
    }

    string gerarFuncaoTemporaria() {
        return "f" + to_string(contadorFuncao++);
    }

    string gerarLabel() {
        return "l" + to_string(contadorLabel++);
    }

    class Parametro {
        private:
            string nome;
            string apelido;
            string tipo;
        public:
            Parametro(string nome, string apelido, string tipo) {
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

    class Funcao {
        private:
            string nome;
            string apelido;
            string retorno;
            string traducao;
            list<Parametro*> parametros;
        public:
            Funcao(string nome, string retorno) {
                this->nome = gerarFuncaoTemporaria();
                this->apelido = nome;
                this->retorno = retorno;
                this->parametros = list<Parametro*>();
            }

            void setTraducao(string traducao) {
                this->traducao = traducao;
            }

            string getNome() {
                return this->nome;
            }

            string getApelido() {
                return this->apelido;
            }

            string getRetorno() {
                return this->retorno;
            }

            string getTraducao() {
                return this->traducao;
            }

            Parametro* adicionarParametro(string apelido, string tipo) {
                string nome = "param" + to_string(this->parametros.size() + 1);
                Parametro *parametro = new Parametro(nome, apelido, tipo);

                for (Parametro *p : this->parametros) {
                    if (p->getApelido() == parametro->getApelido()) {
                        yyerror("Parâmetro " + parametro->getApelido() + " já foi declarado");
                    }
                }

                this->parametros.push_back(parametro);
                return parametro;
            }

            Parametro* getParametroByName(string nome) {
                for (Parametro *p : this->parametros) {
                    if (p->getApelido() == nome) {
                        return p;
                    }
                }

                return NULL;
            }

            bool compare(string apelido, list<string> argumentos) {
                if (this->apelido != apelido) {
                    return false;
                }

                if (this->parametros.size() != argumentos.size()) {
                    return false;
                }

                list<Parametro*>::iterator it = this->parametros.begin();

                for (string argumento : argumentos) {
                    if ((*it)->getTipo() != argumento) {
                        return false;
                    }

                    it++;
                }

                return true;
            }

            list<Parametro*> getParametros() {
                return this->parametros;
            }
    };

    Funcao* getFuncaoDefinindo();

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

    Variavel* criarVariavel(string nome, string apelido, string tipo, bool temporaria = false);

    class Contexto {
        private:
            list<Variavel*> variaveis;
            bool hasLastReturn = false;
        public:
            Contexto() {
                this->variaveis = list<Variavel*>();
            }

            void setHasReturn(bool hasReturn) {
                this->hasLastReturn = hasReturn;
            }

            bool hasReturn() {
                return this->hasLastReturn;
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
                        yyerror("Variável " + apelido + " já foi declarada");
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

    class BreakContinue {
        private:
            string inicioLabel;
            string fimLabel;
        public:
            BreakContinue(string inicioLabel, string fimLabel) {
                this->inicioLabel = inicioLabel;
                this->fimLabel = fimLabel;
            }

            string getInicioLabel() {
                return this->inicioLabel;
            }

            string getFimLabel() {
                return this->fimLabel;
            }
    };

    class Case {
        private:
            string label;
            string traducaoComando;
        public:
            Case(string label, string traducaoComando) {
                this->label = label;
                this->traducaoComando = traducaoComando;
            }

            string getLabel() {
                return this->label;
            }

            string getTraducaoComando() {
                return this->traducaoComando;
            }

            bool isDefault() {
                return this->label == "default";
            }
    };

    class Switch {
        private:
            string label;
            string tipo;
            string fimLabel;
            list<Case*> cases;
        public:
            Switch(string label, string tipo, string fimLabel) {
                this->label = label;
                this->tipo = tipo;
                this->fimLabel = fimLabel;
                this->cases = list<Case*>();
            }

            string getLabel() {
                return this->label;
            }

            string getTipo() {
                return this->tipo;
            }

            string getFimLabel() {
                return this->fimLabel;
            }

            string criarSwitchTable() {
                string traducaoExpressoes = "";
                string switchTable = "";
                string traducaoDefault = "";
                string label = gerarTemporaria();
                string flagLabel = gerarTemporaria();

                criarVariavel(label, label, this->tipo);
                criarVariavel(flagLabel, flagLabel, BOOL_TIPO);

                string traducao = "";

                if (isDebugMode)
			        traducao += "\n/* Inicio Switch Case Table */\n\n";

                for (list<Case*>::iterator it = this->cases.begin(); it != this->cases.end(); ++it) {
                    if ((*it)->isDefault()) {
                        if (isDebugMode) {
                            traducaoDefault += "/* Caso Default */\n\n";
                        }
                        traducaoDefault += (*it)->getTraducaoComando();
                        continue;
                    }
                    
                    string gotoLabel = gerarLabel();

                    if (this->tipo == STRING_TIPO) {
                        string stringReal = fatiaString((*it)->getLabel(), "\"")[1];
                        string stringValor = "\"" + stringReal + "\""; 

                        traducaoExpressoes += label + ".str = (char*) malloc(" + to_string(stringReal.size()) + ");\n";

                        for (int i = 0; i < stringReal.size(); i++) {
                            traducaoExpressoes += label + "[" + to_string(i) + "] = '" + stringReal[i] + "';\n";
                        }

                        traducaoExpressoes += flagLabel + " = igualdadeStrings(" + label + ", " + getLabel() + ");\n";
                    } else {
                        traducaoExpressoes += label + " = " + (*it)->getLabel() + ";\n";
                        traducaoExpressoes += flagLabel + " = " + label + " == " + getLabel() + ";\n";
                    }

                    traducaoExpressoes += "if (" + flagLabel + ") goto " + gotoLabel + ";\n";
                    
                    switchTable += gotoLabel + ":\n";

                    if (!empty((*it)->getTraducaoComando())) {
                        switchTable += (*it)->getTraducaoComando() + "\n";
                    }
                }

                traducao += traducaoExpressoes + "\n" + switchTable + traducaoDefault;

                if (isDebugMode)
                    traducao += "\n/* Fim Switch Case Table */\n\n";

                return traducao;
            }

            Case* adicionarCaso(string label, string traducaoComando) {
                Case *caso = new Case(label, traducaoComando);

                for (list<Case*>::iterator it = this->cases.begin(); it != this->cases.end(); ++it) {
                    if ((*it)->getLabel() == caso->getLabel()) {
                        if (caso->isDefault()) {
                            yyerror("Case default já foi declarado");
                        } else {
                            yyerror("Case " + caso->getLabel() + " já foi declarado");
                        }
                    }
                }

                this->cases.push_back(caso);
                return caso;
            }

            Case* adicionarDefault(string traducaoComando) {
                return this->adicionarCaso("default", traducaoComando);
            }

            list<Case*> getCases() {
                return this->cases;
            }
    };

    list<Contexto*> pilhaContextos;
    list<BreakContinue*> pilhaBreakContinue;
    list<Switch*> pilhaSwitch;

    list<Variavel*> tabelaSimbolosVariaveis;
    list<Funcao*> tabelaSimbolosFuncoes; 

    Funcao* funcaoDefinindo = NULL;

    Funcao* criarDefinicaoFuncao(string nome, string retorno) {
        if (funcaoDefinindo != NULL) {
            yyerror("Não é possível criar funções aninhadas");
        }

        funcaoDefinindo = new Funcao(nome, retorno);
        return funcaoDefinindo;
    }

    Funcao* criarFuncao(Funcao *funcao) {
        list<string> argumentos;

        // começa pelo primeiro argumento

        list<Parametro*> parametros = funcao->getParametros();

        for (Parametro *parametro : parametros) {
            argumentos.push_back(parametro->getTipo());
        }

        for (Funcao *f : tabelaSimbolosFuncoes) {
            if (f->compare(funcao->getApelido(), argumentos)) {
                yyerror("A função com nome " + funcao->getApelido() + " já foi declarada");
            }
        }

        tabelaSimbolosFuncoes.push_back(funcao);
        return funcao;
    }

    void removeDefinicaoFuncao() {
        funcaoDefinindo = NULL;
    }

    Funcao* getFuncaoDefinindo() {
        return funcaoDefinindo;
    }

    Contexto* criarContexto() {
        debug("Criando novo contexto e colocando no topo da pilha");
        Contexto *contexto = new Contexto();
        pilhaContextos.push_back(contexto);
        return contexto;
    }

    Contexto* topoContexto() {
        return pilhaContextos.back();
    }

    void removerContexto() {
        debug("Removendo contexto do topo da pilha");
        pilhaContextos.pop_back();
    }

    Switch* criarSwitch(string label, string tipo, string fimLabel) {
        Switch *curSwitch = new Switch(label, tipo, fimLabel);
        pilhaSwitch.push_back(curSwitch);
        return curSwitch;
    }

    Switch* topoSwitch() {
        return pilhaSwitch.back();
    }

    void removerSwitch() {
        pilhaSwitch.pop_back();
    }

    void adicionarBreakContinue(string inicioLabel, string fimLabel) {
        BreakContinue *breakContinue = new BreakContinue(inicioLabel, fimLabel);
        pilhaBreakContinue.push_back(breakContinue);
    }

    BreakContinue* topoBreakContinue() {
        return pilhaBreakContinue.back();
    }

    BreakContinue* topoContinue() {
        for (list<BreakContinue*>::reverse_iterator it = pilhaBreakContinue.rbegin(); it != pilhaBreakContinue.rend(); ++it) {
            if ((*it)->getInicioLabel() != "") {
                return *it;
            }
        }

        return NULL;
    }

    BreakContinue* removerBreakContinue() {
        BreakContinue *breakContinue = pilhaBreakContinue.back();
        pilhaBreakContinue.pop_back();
        return breakContinue;
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
        
        for (Variavel *variavel : tabelaSimbolosVariaveis) {
            traducao += variavel->getTipo() + " " + variavel->getNome() + ";\n";
        }

        for (Funcao *funcao : tabelaSimbolosFuncoes) {
            traducao += "\n/* Função " + funcao->getNome() + " */\n\n";
            traducao += funcao->getRetorno() + " " + funcao->getNome() + "(";

            list<Parametro*> parametros = funcao->getParametros();
            list<Parametro*>::iterator it = parametros.begin();

            if (it != parametros.end()) {
                traducao += (*it)->getTipo() + " " + (*it)->getNome();
                it++;
            }

            for (; it != parametros.end(); ++it) {
                traducao += ", " + (*it)->getTipo() + " " + (*it)->getNome();
            }

            traducao += ") {\n" + formataCodigo(funcao->getTraducao()) + "}\n";
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

    Variavel* criarVariavel(string nome, string apelido, string tipo, bool temporaria) {
        string apelidoReal = temporaria ? "#" + apelido : apelido;
        Contexto* contexto = pilhaContextos.back();
        Variavel* variavel = contexto->criarVariavel(nome, apelidoReal, tipo);
        tabelaSimbolosVariaveis.push_back(variavel);
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
        Funcao* funcao = getFuncaoDefinindo();

        if (funcao != NULL) {
            Parametro* parametro = funcao->getParametroByName(apelido);

            if (parametro != NULL) {
                Variavel* fakeVariavel = new Variavel(parametro->getNome(), apelido, parametro->getTipo());
                return fakeVariavel;
            }
        }

        for (list<Contexto*>::reverse_iterator it = pilhaContextos.rbegin(); it != pilhaContextos.rend(); ++it) {
            Variavel *variavel = (*it)->buscarVariavel(apelido);

            if (variavel != NULL) {
                return variavel;
            }
        }

        return NULL;
    }

    /**
     * Busca uma função na tabela de símbolos pelo apelido
     * 
     * @param apelido - Apelido da função
     * 
     * @return Funcao - Ponteiro para a função encontrada
     */

    Funcao* buscarFuncao(string apelido, list<string> argumentos) {
        for (Funcao *funcao : tabelaSimbolosFuncoes) {
            if (funcao->compare(apelido, argumentos)) {
                return funcao;
            }
        }

        return NULL;
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

        if (atributo.tipo == INT_TIPO) {
            if (tipoDestino == FLOAT_TIPO) {
                translation += label + " = " + "(float) " + atributo.label + ";\n";
            } else if (tipoDestino == BOOL_TIPO) {
                translation += label + " = " + atributo.label + " != 0;\n";
            } else if (tipoDestino == STRING_TIPO) {
                translation += label + " = intToString(" + atributo.label + ");\n";
            } else {
                yyerror("Conversão de " + atributo.tipo + " para " + tipoDestino + " não suportada");
            }
        } else if (atributo.tipo == FLOAT_TIPO) {
            if (tipoDestino == INT_TIPO) {
                translation += label + " = " + "(int) " + atributo.label + ";\n";
            } else if (tipoDestino == BOOL_TIPO) {
                translation += label + " = " + atributo.label + " != 0.0;\n";
            } else if (tipoDestino == STRING_TIPO) {
                translation += label + " = floatToString(" + atributo.label + ");\n";
            } else {
                yyerror("Conversão de " + atributo.tipo + " para " + tipoDestino + " não suportada");
            }
        } else if (atributo.tipo == BOOL_TIPO) {
            if (tipoDestino == STRING_TIPO) {
                translation += label + " = boolToString(" + atributo.label + ");\n";
            } else {
                yyerror("Conversão de " + atributo.tipo + " para " + tipoDestino + " não suportada");
            }
        } else if (atributo.tipo == CHAR_TIPO) {
            if (tipoDestino == STRING_TIPO) {
                translation += label + " = charToString(" + atributo.label + ");\n";
            } else {
                yyerror("Conversão de " + atributo.tipo + " para " + tipoDestino + " não suportada");
            }
        } else {
            yyerror("Conversão de " + atributo.tipo + " para " + tipoDestino + " não suportada");
        }

        return label;
    }

    bool isNumerico(string tipo) {
        return tipo == INT_TIPO || tipo == FLOAT_TIPO;
    }

}