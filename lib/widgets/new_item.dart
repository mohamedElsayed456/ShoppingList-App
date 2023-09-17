import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/categorymodel.dart';
import 'package:shopping_list_app/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem>{
final formkey=GlobalKey<FormState>();
var enteredName='';
var enteredQuantity=1;
var selectedCategory=categories[Categories.vegetables]!;
var isSending = false;

void saveItem()async{
     if(formkey.currentState!.validate()){
       formkey.currentState!.save();

       setState(() {
         isSending = true;
       });

       final url = Uri.https('flutter-prep-664a7-default-rtdb.firebaseio.com','shopping_list.json');
       final response = await http.post(
          url,
          headers: {
            'Content-Type' : 'application/json',
          },
          body:json.encode(
           {
             'name':enteredName,
             'quantity':enteredQuantity,
             'category':selectedCategory.title,
           }
          ),
        );
        final Map<String,dynamic> resData = json.decode(response.body);

        if(!context.mounted){
          return;
        }

       Navigator.of(context).pop(
        GroceryItem(
          id: resData['name'],
          name: enteredName,
          quantity:enteredQuantity,
          category:selectedCategory,
        ),
       );
     };
     
}

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title:const Text('Add a new item'),
      ),
      body:Padding(
        padding:const EdgeInsets.all(12),
        child:Form(
          key: formkey,
          child:Column(
            children:[
              TextFormField (
                keyboardType: TextInputType.name,
                maxLength: 50,
                decoration:const InputDecoration(
                  label: Text('Name'),
                ),
                validator:(value){
                 if(value==null || value.isEmpty || value.trim().length<=1 || value.trim().length>50){
                     return 'Must be between 1 and 50 characters';
                 }
                 return null;
                },
                onSaved: (value){
                 enteredName=value!;
                },
              ),
              const SizedBox(height:10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children:[
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration:const InputDecoration(
                        label: Text('quantity')
                      ),
                      initialValue:enteredQuantity.toString(),
                      validator:(value){
                      if(
                        value==null 
                        || value.isEmpty
                        || int.tryParse(value)==null 
                        || int.tryParse(value)!<= 0
                        )
                      {
                        return 'Must be a valid , positive number';
                    }
                        return null;
                   },
                   onSaved:(value){
                    enteredQuantity=int.parse(value!);
                   },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: selectedCategory,
                      items:[
                        for(final category in categories.entries)
                        DropdownMenuItem(
                          value: category.value,
                          child:Row(
                            children:[
                              Container(
                                width: 16,
                                height: 16,
                                color: category.value.color,
                              ),
                             const SizedBox(width: 6,),
                             Text(category.value.title),
                            ],
                           ),
                          ),
                      ],
                      onChanged:(value){
                        setState((){
                          selectedCategory=value!;
                        }
                       );  
                      }
                    ),
                  ),
                ],
              ),
               const SizedBox(height: 12,),
               Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children:[
                  TextButton(
                    onPressed: isSending ? null: (){
                      formkey.currentState!.reset();                   
                       },
                     child:const Text('Reset'),
                     ),
                  ElevatedButton(
                    onPressed:isSending ? null: saveItem, 
                    child: isSending? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(),
                    ) : const Text('Add Item'),
                  )
                ],
               )
            ],
          ),
        ),
      ),
    );
  }
}