#pragma once

class AdditionalInfo{
    string token;
    Type type;
    list<Type> parameterList;            //with returnType // NULL means not a function
public:
    
    
    static Type getEnum(string s){
        map<string, Type>::iterator x = stringToType.find(s);
        if(x == stringToType.end())return Unknown;
        return x -> second;
    }
    AdditionalInfo(string token){
        type = Unknown;
        this -> token = token;
    }
    
    
    AdditionalInfo(string token, string typ){
        this -> token = token;
        type = getEnum(typ);
    }
    
    void addParam(string p){
        parameterList.push_back(getEnum(p));
    }
    
    
    
    string getToken(){
        return token;
    }
    
    Type getType(){
        return type;
    }
    
    void setToken(string s){
        token = s;
    }
    
    void setType(string s){
        type = getEnum(s);
    }
    
    void setType(Type t){
        type = t;
    }
    
    list<Type> getParameterList(){
        return parameterList;
    }
};
