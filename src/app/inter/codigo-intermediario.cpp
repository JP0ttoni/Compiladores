/* Compilador JSM */

#include <iostream>
#include <string.h>
#include <stdio.h>

#define bool int
#define true 1
#define false 0

using namespace std;

/* Prototipos das Funções Utilitárias */

int calcularTamanhoString(char *str);

char* concatenarString(char *s1, int n1, char *s2, int n2);
char* copiarString(char *str, int tamanho);

char* intToString(int n);
char* floatToString(float n);

char* lerEntrada();

/*-=-*/

/* Implementação das funções */

int calcularTamanhoString(char *str) {
    int i = 0;
    int flag;

inicioWhile:
    flag = str[i] != '\0';
    if (!flag) goto fimWhile;
    i++;
    goto inicioWhile;
fimWhile:

    return i;
}

char* concatenarString(char *s1, int n1, char *s2, int n2) {
    char *result = (char*) malloc(n1 + n2);

    int indice;
    int indiceAtual;

    int flag;

    indice = 0;
    indiceAtual = 0;

inicioWhile:
    flag = indice < n1;
    if (!flag) goto fimWhile;
    result[indiceAtual] = s1[indice];
    indice++;
    indiceAtual++;
    goto inicioWhile;
fimWhile:

inicioWhile2:
    flag = indice < n2;
    if (!flag) goto fimWhile2;
    result[indiceAtual] = s2[indice];
    indice++;
    indiceAtual++;
    goto inicioWhile2;
fimWhile2:

    return result;
}

char* copiarString(char *str, int tamanho) {
    char *result = (char*) malloc(tamanho);

    int index = 0;
    int whileFlag;
    
inicioWhile:
    whileFlag = index < tamanho;
    if (!whileFlag) goto fimWhile;
    result[index] = str[index];
    index++;
    goto inicioWhile;
fimWhile:

    return result;
}

char* intToString(int n) {
    char *result;
    result = (char*) malloc(12);
    sprintf(result, "%d", n);
    return result;
}

char* floatToString(float n) {
    char *result;
    result = (char*) malloc(12);
    sprintf(result, "%.8f", n);
    return result;
}

// AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
char* lerEntrada() {
    int tamanho;
    int capacidade;
    char caractere;

    int whileFlag;
    int ifFlag;

    int t1;

    tamanho = 0;
    capacidade = 12;
    caractere = 0;
    char* charPtr = (char*) malloc(capacidade);

iniciarWhile:
    whileFlag = cin.get(caractere) && caractere != '\n';
    if (!whileFlag) goto fimWhile;

    t1 = tamanho + 1;
    ifFlag = t1 >= capacidade;
    if (!ifFlag) goto fimIf;
    capacidade = capacidade * 2;
    charPtr = (char*) realloc(charPtr, capacidade);
fimIf:
    charPtr[tamanho] = caractere;
    tamanho++;
    goto iniciarWhile;
fimWhile:

    charPtr[tamanho] = '\0';

    return charPtr;
}