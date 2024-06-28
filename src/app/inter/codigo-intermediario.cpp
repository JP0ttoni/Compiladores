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
char* concat(char *s1, int n1, char *s2, int n2);

/*-=-*/

/* Implementação das funções */

int calcularTamanhoString(char *str) {
    int i = 0;
    while (str[i] != '\0') {
        i++;
    }
    return i;
}

char* concat(char *s1, int n1, char *s2, int n2) {
    char *result = (char*) malloc(n1 + n2 + 1);

    if (result == NULL) {
        cout << "Erro ao alocar memória para concatenação de strings" << endl;
        exit(1);
    }
    
    strcpy(result, s1);
    strcat(result, s2);
    return result;
}