#pragma once

class AdditionalInfo{
    string token;
    Type type;
    int address;
    list<Type> parameterList;            //with returnType // NULL means not a function
    list<int> l[2];                 //lists for backpatching
    string label;
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
    
    
    AdditionalInfo(string token, string typ, int address){
        this -> token = token;
        type = getEnum(typ);
        this -> address = address;
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
    int getAddress(){
        return address;
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
    
    void setAddress(int address){
        this -> address = address;
    }
    
    list<Type> getParameterList(){
        return parameterList;
    }
    
    list<int> getList(int i){
        return l[i];
    }
    
    list<int>& getRefList(int i){
        return l[i];
    }
    
    void addList(int i, list<int> &l2){
        while(!l2.empty())l[i].push_back(l2.front()), l2.pop_front();
    }
    
    void addListElement(int i, int val){
        l[i].push_back(val);
    }
    
    string getLabel(){
        return label;
    }
    
    void setLabel(string label){
        this -> label = label;
    }
    
};
