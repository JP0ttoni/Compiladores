%{
#include <string>
%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]
UNDERLINE "_"

ALFANUMERICO ({LETRA}|{DIGITO}|{UNDERLINE})

DELIM {ESPACO}+

INTEIRO ({DIGITO})+
REAL (((({DIGITO}+)|({DIGITO}*\.{DIGITO}+))([eE][-+]?{DIGITO}+)?))

CHAR \'({ALFANUMERICO})\'
STRING \"(\\.|[^"\\])*\"
ID ({LETRA}|{UNDERLINE})({ALFANUMERICO})*

TIPOS "int"|"float"|"bool"|"char"|"void"

COMENTARIO "%%".*

%%

{DELIM} 	    {                                           }
{COMENTARIO}    {                                           }
"\n"		    { adicionarLinha();                         }
  
"var"           { return TK_VAR;                            }
"as"            { return TK_AS;                             }

"if"            { return TK_IF;                             }
"else"          { return TK_ELSE;                           }

"do"            { return TK_DO;                             }
"while"         { return TK_WHILE;                          }
"for"           { return TK_FOR;                            }

"switch"        { return TK_SWITCH;                         }
"case"          { return TK_CASE;                           }
"default"       { return TK_DEFAULT;                        }

"break"         { return TK_BREAK;                          }
"continue"      { return TK_CONTINUE;                       }

"print"         { return TK_PRINT;                          }
"println"       { return TK_PRINTLN;                        }
"scanf"         { return TK_SCANF;                          }
"size"          { return TK_SIZE;                           }
"toString"      { return TK_TOSTRING;                       }

"return"        { return TK_RETURN;                         }

"&&"            { return TK_AND;                            }
"and"           { return TK_AND;                            }
"||"            { return TK_OR;                             }
"or"            { return TK_OR;                             }
"!"             { return TK_NOT;                            }
"not"           { return TK_NOT;                            }

"=="            { return TK_IGUAL;                          }
"!="            { return TK_DIFERENTE;                      }
">"             { return TK_MAIOR;                          }
"<"             { return TK_MENOR;                          }
">="            { return TK_MAIOR_IGUAL;                    }
"<="            { return TK_MENOR_IGUAL;                    }

"str"           { yylval.label = "String"; return TK_TIPO;  }
"string"        { yylval.label = "String"; return TK_TIPO;  }
{TIPOS}         { yylval.label = yytext; return TK_TIPO;    }

"--"            { return TK_MENOS_MENOS;                    }
"++"            { return TK_MAIS_MAIS;                      }
"//"            { return TK_DIV;                            }
[+\-*/|\"]      { return *yytext;                           }
[(){}[\]]       { return *yytext;                           }
[;,~:=%]        { return *yytext;                           }

{CHAR}          { yylval.label = yytext; return TK_CHAR;    }
{STRING}        { yylval.label = yytext; return TK_STRING;  }
{INTEIRO}		{ yylval.label = yytext; return TK_INTEIRO; }
{REAL}          { yylval.label = yytext; return TK_REAL;    }

"true"          { yylval.label = "true"; return TK_TRUE;    }
"false"         { yylval.label = "false"; return TK_FALSE;  }

{ID}		    { yylval.label = yytext; return TK_ID;       }
    
.			    { *yytext;                                   }
    
%%