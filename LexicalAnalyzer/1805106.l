%option noyywrap
%option yylineno

%x CHAR_LITERAL
%x STRING_LITERAL
%x SINGLE_COMMENT
%x MULTI_COMMENT

%{
#include<iostream>
#include<fstream>
#include<string>
#include "SymbolTable.h"
using namespace std;

int error_count, line_count;

string temp, temp2;
ofstream logfile, tokenfile;
const int bucketSize = 7;

#define EN "\n\n"
SymbolTable symbols(bucketSize);

string toUp(string s){
    for(char &c : s)c = toupper(c);
    return s;
}

%}


KEYWORD (if|else|for|while|do|break|int|char|float|double|void|return|switch|case|default|continue)
%%



([ \t\n\r])+                {}

{KEYWORD}               { 
                            
                            logfile << "Line no " << yylineno << ": Token <" << toUp(yytext) << "> Lexeme " << yytext << " found" << EN;
                            
                            tokenfile << "<" << toUp(yytext) << "> "; 
                        }
[\']                    {
                            temp2.clear();
                            temp.clear();
                            line_count = yylineno;
                            BEGIN CHAR_LITERAL;
                        }



<CHAR_LITERAL>[\\](.)   {
                            temp2 += yytext;
                            switch(yytext[1]){
                                case 'n':
                                    temp += '\n';
                                    break;
                                case 't':
                                    temp += '\t';
                                    break;
                                case '\\':
                                    temp += '\\';
                                    break;
                                case '\'':
                                    temp += '\'';
                                    break;
                                case '\"':
                                    temp += '\"';
                                    break;
                                case 'a':
                                    temp += '\a';
                                    break;
                                case 'f':
                                    temp += '\f';
                                    break;
                                case 'r':
                                    temp += '\r';
                                    break;
                                case 'b':
                                    temp += '\b';
                                    break;
                                case 'v':
                                    temp += '\v';
                                    break;
                                case '0':
                                    temp += '\0';
                                    break;
                                default:
                                    temp += yytext[1];
                            }
                        }
                                                
<CHAR_LITERAL>[\']      {
                            if(temp.empty()){
                                logfile << "Error at line no " << yylineno << ": Empty character constant error ''" << EN;
                                error_count++;
                            }else if(temp.size() > 1){
                                logfile << "Error at line no " << yylineno << ": Multi character constant error '" << temp2 << "'" << EN;
                                error_count++;
                            }else{
                                logfile << "Line no " << yylineno << ": Token <CONST_CHAR> Lexeme '" << temp2 << "' found --> ";
                                logfile << "<CONST_CHAR, " << temp << ">" << EN;
                                tokenfile << "<CONST_CHAR, " << temp << "> ";
                                if(symbols.insert("'" + temp2 + "'", "CONST_CHAR"))
                                    symbols.printAllScopeTable(logfile);
                            }
                            BEGIN INITIAL;
                        }
<CHAR_LITERAL>[\n]      {
                            logfile << "Error at line no " << line_count << ": Unterminated character '" << temp2 << EN;
                            error_count++;
                            BEGIN INITIAL;
                        }
<CHAR_LITERAL><<EOF>>   {
                            logfile << "Error at line no " << line_count << ": Unterminated character '" << temp2 << EN;
                            error_count++;
                            BEGIN INITIAL;
                        }
<CHAR_LITERAL>.         {
                            temp2 += yytext;
                            temp += yytext;
                        }
                        
[+-]                    {
                            logfile << "Line no " << yylineno << ": Token <ADDOP> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<ADDOP, " << yytext << "> ";
                        }
                        
                        
[*/%]                   {
                            logfile << "Line no " << yylineno << ": Token <MULOP> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<MULOP, " << yytext << "> ";
                        }
                        
[+]{2}|[-]{2}           {
                            logfile << "Line no " << yylineno << ": Token <INCOP> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<INCOP, " << yytext << "> ";
                        }
                        
([><][=]?)|((!|=)[=])   {
                            logfile << "Line no " << yylineno << ": Token <RELOP> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<RELOP, " << yytext << "> ";
                        }
                    
                        
[=]                     {
                            logfile << "Line no " << yylineno << ": Token <ASSIGNOP> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<ASSIGNOP, " << yytext << "> ";
                        }
                                                
[&]{2}|[|]{2}           {
                            logfile << "Line no " << yylineno << ": Token <LOGICOP> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<LOGICOP, " << yytext << "> ";
                        }
                        
                                                
[!]                     {
                            logfile << "Line no " << yylineno << ": Token <NOT> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<NOT, " << yytext << "> ";
                        }
                        
                                                
[(]                     {
                            logfile << "Line no " << yylineno << ": Token <LPAREN> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<LPAREN, " << yytext << "> ";
                        }
                        
                                                
[)]                     {
                            logfile << "Line no " << yylineno << ": Token <RPAREN> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<RPAREN, " << yytext << "> ";
                        }
                        
                                                
[{]                     {
                            logfile << "Line no " << yylineno << ": Token <LCURL> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<LCURL, " << yytext << "> ";
                            symbols.enterScope();
                        }
                        
                                                
[}]                     {
                            logfile << "Line no " << yylineno << ": Token <RCURL> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<RCURL, " << yytext << "> ";
                            symbols.exitScope();
                        }
                        
    
[[]                     {
                            logfile << "Line no " << yylineno << ": Token <LTHIRD> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<LTHIRD, " << yytext << "> ";
                        }
                        
                                                
[]]                     {
                            logfile << "Line no " << yylineno << ": Token <RTHIRD> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<RTHIRD, " << yytext << "> ";
                        }
                        
                                                
[,]                     {
                            logfile << "Line no " << yylineno << ": Token <COMMA> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<COMMA, " << yytext << "> ";
                        }
                        
                                                
[;]                     {
                            logfile << "Line no " << yylineno << ": Token <SEMICOLON> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<SEMICOLON, " << yytext << "> ";
                        }
                        
[A-Za-z_][A-Za-z0-9_]*   {
                            logfile << "Line no " << yylineno << ": Token <ID> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<ID, " << yytext << "> ";
                            if(symbols.insert(yytext, "ID"))
                                symbols.printAllScopeTable(logfile);
                            //else{
                            //logfile << yytext << " already exists in current ScopeTable" << EN;
                            //}
                        }
[0-9]+                  {
                            logfile << "Line no " << yylineno << ": Token <CONST_INT> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<CONST_INT, " << yytext << "> ";
                            if(symbols.insert(yytext, "CONST_INT"))
                                symbols.printAllScopeTable(logfile);
                        }                        

(([0-9]+)([.][0-9]+)?(E[+-]?[0-9]+)?)|([.][0-9]+(E[+-]?[0-9]+)) {

                            logfile << "Line no " << yylineno << ": Token <CONST_FLOAT> Lexeme " << yytext << " found" << EN;
                            tokenfile << "<CONST_FLOAT, " << yytext << "> ";
                            if(symbols.insert(yytext, "CONST_FLOAT"))
                                symbols.printAllScopeTable(logfile);
                        }                
                        


(([0-9]*)[.]([0-9]*)(([.][0-9]*)+)(E[+-]?[0-9]+)?) {
                            
                            logfile << "Error at line no " << yylineno << ": Too many decimal points " << yytext << EN;
                            error_count++;
                        }                        
                        

                        
(([0-9]+)([.][0-9]+)?(E[+-]?([0-9]*)([.][0-9]*)+)+)|([.]([0-9]+)(E[+-]?([0-9]*)([.][0-9]*)+)+) {                        
                            
                            logfile << "Error at line no " << yylineno << ": Ill formated number " << yytext << EN;
                            error_count++;
                        }  
([0-9]+)[A-Za-z_][A-Za-z0-9_]* {
                            logfile << "Error at line no " << yylineno << ": Invalid prefix on ID or invalid suffix on Number " << yytext << EN;
                            error_count++;
                        }
                        
["]                     {
                            temp2.clear();
                            temp.clear();
                            line_count = yylineno;
                            BEGIN STRING_LITERAL;
                        }                        
                        
<STRING_LITERAL>[^\\^\"^\n]+ {
                            temp2 += yytext;
                            temp += yytext;
                        }
                        
<STRING_LITERAL>[\\][\r]?[\n]    {
                                temp2 += yytext;
                            }
<STRING_LITERAL>[\\](.) {
                            temp2 += yytext;
                            switch(yytext[1]){
                                case 'n':
                                    temp += '\n';
                                    break;
                                case 't':
                                    temp += '\t';
                                    break;
                                case '\\':
                                    temp += '\\';
                                    break;
                                case '\"':
                                    temp += '\"';
                                    break;
                                case '\'':
                                    temp += '\'';
                                    break;
                                case 'a':
                                    temp += '\a';
                                    break;
                                case 'f':
                                    temp += '\f';
                                    break;
                                case 'r':
                                    temp += '\r';
                                    break;
                                case 'b':
                                    temp += '\b';
                                    break;
                                case 'v':
                                    temp += '\v';
                                    break;
                                case '0':
                                    temp += '\0';
                                    break;
                                default:
                                    temp += yytext;
                            }
                        }
<STRING_LITERAL>[\n]    {
                            logfile << "Error at line no " << line_count << ": Unterminated string \"" << temp2 << EN;
                            error_count++;
                            BEGIN INITIAL;
                        }
<STRING_LITERAL><<EOF>> {
                            logfile << "Error at line no " << line_count << ": Unterminated string \"" << temp2 << EN;
                            error_count++;
                            BEGIN INITIAL;
                        }
<STRING_LITERAL>[\"]    {
                            logfile << "Line no " << line_count << ": Token <STRING> Lexeme \"" << temp2 << "\" found --> ";
                            logfile << "<STRING, \"" << temp << "\">" << EN;
                            tokenfile << "<STRING, \"" << temp << "\"> ";
                            BEGIN INITIAL;
                        }

[/][/]                {
                            temp2 = yytext;
                            line_count = yylineno;
                            BEGIN SINGLE_COMMENT;
                        }
<SINGLE_COMMENT>([\\][\r]?[\n]|.)+ {
                        
                            temp2 += yytext;
                        }
                        
<SINGLE_COMMENT>[\n] {
                        logfile << "Line no " << line_count << ": Token <COMMENT> Lexeme " << temp2 << " found" << EN;
                        BEGIN INITIAL;
                            
                    }
                        
<SINGLE_COMMENT><<EOF>> {
                        logfile << "Line no " << line_count << ": Token <COMMENT> Lexeme " << temp2 << " found" << EN;
                        BEGIN INITIAL;
                            
                    }

[/][*]              {
                        temp2 = yytext;
                        line_count = yylineno;
                        BEGIN MULTI_COMMENT;
                    }
                    
<MULTI_COMMENT>[^*] {
                        temp2 += yytext;
                    }
                    
<MULTI_COMMENT>[*][^/] {
                        temp2 += yytext;
                    }
                    
<MULTI_COMMENT>[*][/] {
                        temp2 += yytext;
                        logfile << "Line no " << line_count << ": Token <COMMENT> Lexeme " << temp2 << " found" << EN;
                        BEGIN INITIAL;
                            
                    }
<MULTI_COMMENT><<EOF>> {
                            logfile << "Error at line no " << line_count << ": Unterminated comment " << temp2 << EN;
                            error_count++;
                            BEGIN INITIAL;
                        }
<<EOF>>     {
                
                symbols.printAllScopeTable(logfile);

                logfile << "Total Lines: " << yylineno << "\n";
                logfile << "Total Errors: " << error_count << "\n";
                return 0;
            }

.                   {
                        logfile << "Error at line no " << yylineno << ": Unrecognized character " << yytext << EN;
                        error_count++;
                    }
            

%%

                          
int main(int argc,char *argv[]){

	if(argc != 2){
        yyin = fopen("in.txt", "r");
	}else{
        yyin = fopen(argv[1], "r");
    }
	yylineno = 1;
    
    logfile.open("log.txt", ios::out);
    tokenfile.open("token.txt", ios::out);
    
	if(yyin == NULL || !logfile.is_open() || !tokenfile.is_open()){
		cout << "Cannot open specified file\n";
		return 0;
	}
	
    logfile << "\n";
    yylex();
    
	fclose(yyin);
	logfile.close();
    tokenfile.close();
    return 0;
}
