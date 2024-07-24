#include <string>
#include <vector>
#include <list>
#include <fstream>
#include <sstream>
#include <iostream>

using namespace std;

#pragma once
namespace compilador {

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

    vector<string> fatiaString(string str, string del);
    string formataCodigo(string code);

    typedef struct {
        string label;
        string tipo;
        string traducao;
        int* dimensoes;
        int tamanho;        
    } Atributo;

    bool isArray(int* dimensoes) {
        return dimensoes != NULL;
    }

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
            int* dimensoes;
            int tamanho;
        public:
            Variavel(string nome, string apelido, string tipo, int* dimensoes = NULL, int tamanho = 0) {
                this->nome = nome;
                this->apelido = apelido;
                this->tipo = tipo;
                this->dimensoes = dimensoes;
                this->tamanho = tamanho;
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

            bool isArray() {
                return this->dimensoes != NULL;
            }

            int* getDimensoes() {
                return this->dimensoes;
            }

            int getTamanho() {
                return this->tamanho;
            }
    };

    class Label {
        private:
            string label;
            string traducao;
        public:
            Label(string label, string traducao) {
                this->label = label;
                this->traducao = traducao;
            }

            string getLabel() {
                return this->label;
            }

            string getTraducao() {
                return this->traducao;
            }
    };

    class Array {
        private:
            string tipo;
            list<Label*> labels;
            list<Array*> childs;
        public:
            Array() {
                this->tipo = "void";
                this->labels = list<Label*>();
                this->childs = list<Array*>();
            }

            void setTipo(string tipo) {
                this->tipo = tipo;
            }

            void adicionarLabel(string label, string traducao) {
                if (this->childs.size() > 0) {
                    yyerror("Uma nova label foi adicionado em um array de arrays, esperava-se um array de labels.");
                }

                debug("Adicionando label ao array");
                this->labels.push_back(new Label(label, traducao));
            }

            void adicionarChild(Array* child) {
                if (this->labels.size() > 0) {
                    yyerror("Uma nova sub-array foi adicionado em uma array de labels, esperava-se um novo elemento.");
                }

                // verifica se a quantidade de child é igual com os outros

                for (Array* array : this->childs) {
                    if (array->labels.size() != child->labels.size()) {
                        yyerror("Uma nova sub-array foi adicionada com quantidade " + to_string(child->labels.size()) + " diferente de " + to_string(array->labels.size()));
                    } else if (array->childs.size() != child->childs.size()) {
                        yyerror("Uma nova sub-array foi adicionada com quantidade " + to_string(child->childs.size()) + " diferente de " + to_string(array->childs.size()));
                    }
                }

                debug("Adicionando child ao array");
                this->childs.push_back(child);
            }

            bool isTipoCompativel(string tipo) {
                if (this->tipo == "void") {
                    this->tipo = tipo;
                    return true;
                }

                return this->tipo == tipo;
            }

            string getTipo() {
                return this->tipo;
            }

            list<Label*> getLabels() {
                return this->labels;
            }

            list<Array*> getChilds() {
                return this->childs;
            }

            string getTraducao() {
                string traducao = "";

                if (this->tipo == "void") {
                    return traducao;
                }

                if (this->labels.size() > 0) {
                    for (Label* label : this->labels) {
                        traducao += label->getTraducao();
                    }

                    return traducao;
                }

                for (Array* child : this->childs) {
                    traducao += child->getTraducao();
                }

                return traducao;
            }

            vector<string> getRealLabels() {
                vector<string> labels;

                if (this->tipo == "void") {
                    return labels;
                }

                if (this->labels.size() > 0) {
                    for (Label* label : this->labels) {
                        labels.push_back(label->getLabel());
                    }

                    return labels;
                }

                for (Array* child : this->childs) {
                    for (string label : child->getRealLabels()) {
                        labels.push_back(label);
                    }
                }

                return labels;
            }

            int getTamanhoTotal() {
                if (this->tipo == "void") {
                    return 0;
                }

                if (this->labels.size() > 0) {
                    return this->labels.size();
                }

                return this->childs.size() * this->childs.front()->getTamanhoTotal();
            }

            int getAlturaMaxima() {
                if (this->tipo == "void") {
                    return 0;
                }

                if (this->labels.size() > 0) {
                    return 1;
                }

                return this->childs.front()->getAlturaMaxima() + 1;
            }

            /**
             * Retorna o tamanho das dimensões do array, sendo cada elemento do array o tamanho de uma dimensão
             * 
             * @example Em um array [[1,2,3], [1,2,3]] o retorno seria [2,3]
             * @example Em um array [[1,2,3], [[1,2,3], [1,2,3]]] o retorno seria [2,2,3]
             * @example Em um array [[1,2,3], [[1,2,3], [1,2,3], [1,2,3]]] o retorno seria [2,3,3]
             * 
             * @return int* - Array de inteiros com o tamanho das dimensões
             */

            pair<int*, int> getTamanhoDimensoes() {
                pair<int*, int> result;

                result.first = new int[getAlturaMaxima()];
                result.second = 0;

                if (this->childs.size() > 0) {
                    result.first[result.second++] = this->childs.size();
                    list<Array*> pilhaChilds;

                    pilhaChilds.push_back(this->childs.front());

                    while (pilhaChilds.size() > 0) {
                        Array* child = pilhaChilds.front();
                        pilhaChilds.pop_front();

                        if (child->getTipo() == "void") {
                            result.first[result.second++] = 0;
                            return result;
                        }

                        if (child->labels.size() > 0) {
                            result.first[result.second++] = child->labels.size();
                            break;
                        }

                        result.first[result.second++] = child->childs.size();
                        Array* firstChildOfChild = child->childs.front();
                        pilhaChilds.push_back(firstChildOfChild);
                    }
                } else {
                    result.first[result.second++] = this->labels.size();
                }

                return result;
            }
    };

    list<Array*> pilhaArrays;

    Array* criarArray() {
        Array *array = new Array();
        pilhaArrays.push_back(array);
        return array;        
    }

    Array* topoArray() {
        return pilhaArrays.back();
    }

    int getPilhaArraySize() {
        return pilhaArrays.size();
    }

    Array* removerArray() {
        Array *array = pilhaArrays.back();
        pilhaArrays.pop_back();
        return array;
    }

    Variavel* criarVariavel(string nome, string apelido, string tipo, bool temporaria = false);
    Variavel* criarArray(string nome, string apelido, string tipo, bool temporaria = false, int* dimensoes = NULL, int tamanho = 0);

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

            bool hasVariavel(string apelido) {
                for (list<Variavel*>::iterator it = this->variaveis.begin(); it != this->variaveis.end(); ++it) {
                    if ((*it)->getApelido() == apelido) {
                        return true;
                    }
                }

                return false;
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
                if (hasVariavel(apelido)) {
                    yyerror("Variável " + apelido + " já foi declarada");
                }

                debug("Criando variável " + nome + " do tipo " + tipo + " com apelido " + apelido);

                Variavel *variavel = new Variavel(nome, apelido, tipo);
                this->variaveis.push_back(variavel);
                return variavel;
            }

            /**
             * Criar uma variável do tipo array
             * 
             * @param nome - Nome da variável
             * @param apelido - Apelido da variável
             * @param tipo - Tipo da variável
             * @param dimensoes - Dimensões do array
             * 
             * @return Variavel - Ponteiro para a variável criada
             */

            Variavel* criarArray(string nome, string apelido, string tipo, int* dimensoes, int tamanho) {
                if (hasVariavel(apelido)) {
                    yyerror("Variável " + apelido + " já foi declarada");
                }

                debug("Criando array " + nome + " do tipo " + tipo + " com apelido " + apelido + " e tamanho " + to_string(tamanho));

                Variavel *variavel = new Variavel(nome, apelido, tipo, dimensoes, tamanho);
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

            Variavel* buscarVariavel(string apelido, bool porApelido = false) {
                for (list<Variavel*>::iterator it = this->variaveis.begin(); it != this->variaveis.end(); ++it) {
                    if ((*it)->getApelido() == apelido) {
                        return *it;
                    } else if (porApelido && (*it)->getApelido() == "#" + apelido) {
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
            if (variavel->isArray()) {
                traducao += variavel->getTipo() + "* " + variavel->getNome() + ";\n";
            } else {
                traducao += variavel->getTipo() + " " + variavel->getNome() + ";\n";
            }
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
     * Criar uma variável do tipo array
     * 
     * @param nome - Nome da variável
     * @param apelido - Apelido da variável
     * @param tipo - Tipo da variável
     * @param dimensoes - Dimensões do array
     * 
     * @return Variavel - Ponteiro para a variável criada
     */

    Variavel* criarArray(string nome, string apelido, string tipo, bool temporaria, int* dimensoes, int tamanho) {
        string apelidoReal = temporaria ? "#" + apelido : apelido;
        Contexto* contexto = pilhaContextos.back();
        Variavel* variavel = contexto->criarArray(nome, apelidoReal, tipo, dimensoes, tamanho);
        tabelaSimbolosVariaveis.push_back(variavel);
        return variavel;
    }

    /**
     * Dado um array de dimensões e um array de índices, retorna o índice do array
     * 
     * @param dimensoes - Array de dimensões
     * @param indices - Array de índices
     * @param n - Tamanho dos arrays de dimensões e índices
     * 
     * @return int - Índice do array
     */

    int calcularPosicaoArray(int* dimensoes, int* indices, int n) {
        int index = 0;
        int multiplicador = 1;

        for (int i = n - 1; i >= 0; i--) {
            index += multiplicador * indices[i];
            multiplicador *= dimensoes[i];
        }

        // calcula o tamanho total

        int tamanhoTotal = 1;

        for (int i = 0; i < n; i++) {
            tamanhoTotal *= dimensoes[i];
        }

        if (index < 0) {
            yyerror("índice do array fora da faixa (valor mínimo: 0)");
        }

        if (index >= tamanhoTotal) {
            yyerror("Índice do array fora da faixa (valor máximo: " + to_string(tamanhoTotal) + ")");
        }

        return index;
    }

    /**
     * Busca uma variável na tabela de símbolos pelo apelido
     * 
     * @param apelido - Apelido da variável
     * 
     * @return Variavel - Ponteiro para a variável encontrada
     */

    Variavel* buscarVariavel(string apelido, bool porApelido = false) {
        Funcao* funcao = getFuncaoDefinindo();

        if (funcao != NULL) {
            Parametro* parametro = funcao->getParametroByName(apelido);

            if (parametro != NULL) {
                Variavel* fakeVariavel = new Variavel(parametro->getNome(), apelido, parametro->getTipo());
                return fakeVariavel;
            }
        }

        for (list<Contexto*>::reverse_iterator it = pilhaContextos.rbegin(); it != pilhaContextos.rend(); ++it) {
            Variavel *variavel = (*it)->buscarVariavel(apelido, porApelido);

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

        if (atributo.tamanho == 0) {
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
        } else {
            yyerror("Conversão de arrays não suportada");
        }

        return label;
    }

    bool isNumerico(string tipo) {
        return tipo == INT_TIPO || tipo == FLOAT_TIPO;
    }

    vector<string> fatiaString(string str, string del) {
        size_t pos_start = 0, pos_end, delim_len = del.length();
        string token;
        vector<string> res;

        while ((pos_end = str.find(del, pos_start)) != string::npos) {
            token = str.substr (pos_start, pos_end - pos_start);
            pos_start = pos_end + delim_len;
            res.push_back (token);
        }

        res.push_back (str.substr (pos_start));
        return res;
    }

    string formataCodigo(string code) {
        vector<string> lines = fatiaString(code, "\n");
        string identedCode = "";

        for (int i = 0; i < lines.size(); i++) {
            identedCode += "\t" + lines[i] + "\n";
        }

        return identedCode;
    }

}