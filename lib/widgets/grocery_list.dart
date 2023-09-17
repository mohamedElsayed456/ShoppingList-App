import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget{
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList>{

List<GroceryItem>groceryItems=[];

var isloading = true;
String? _error;

 @override
  void initState(){
    super.initState();
    loadItems();
  }

void loadItems()async{
  final url = Uri.https('flutter-prep-664a7-default-rtdb.firebaseio','shopping_list.json');

  try{

    final response = await http.get(url);
  
    if(response.statusCode>=400){
    setState(() {
       _error='Failed to fetch data,Please try again later';
    });
   }

   if(response.body=='null'){
    setState(() {
      isloading=false;
    });
    return;
   }

  final Map<String,dynamic> listData= json.decode(response.body);
  final List<GroceryItem>loadedItems=[];
  
  for(final item in listData.entries){
    final category = categories.entries.firstWhere(
      (catItem) => catItem.value.title==item.value['category']).value;
    loadedItems.add(
      GroceryItem(
        id:item.key,
        name:item.value['name'],
        quantity:item.value['quantity'],
        category:category,
        )
      );
    }
    setState(() {
       groceryItems = loadedItems;
       isloading=false;
    });
  }catch(error){
   setState((){
       _error ='something went wrong! Please try again later';
    });
  }
  
   
}
void addItem()async{
 final newItem = await Navigator.of(context).push<GroceryItem>(
  MaterialPageRoute(builder: (ctx)=>const NewItem()
    ),
   );  

    if(newItem==null){
      return;
    }  
    setState(() {
      groceryItems.add(newItem);
    });
  }

   void removeItem(GroceryItem item)async{
    final index=groceryItems.indexOf(item);
     setState(() {
       groceryItems.remove(item);
    });
    final url = Uri.https('flutter-prep-664a7-default-rtdb.firebaseio.com','shopping_list/${item.id}.json');
      final response=await http.delete(url);
     
      if(response.statusCode >= 400){
       setState(() {
       groceryItems.insert(index,item);
        });
      }
    
   }

  @override
  Widget build(BuildContext context){

     Widget content =const Center(child: Text('No items added yet.'),);

     if(isloading){
      content = const Center(child: CircularProgressIndicator(),);
     }

     if(groceryItems.isNotEmpty){
      content = ListView.builder(
        itemCount:groceryItems.length,
        itemBuilder:(ctx,index) => Dismissible(
          onDismissed:(direction){
            removeItem(groceryItems[index]);
          },
          key:ValueKey (groceryItems[index].id), 
          child: ListTile(
          title: Text(groceryItems[index].name),
          leading: Container(
            width: 24,
            height: 24,
            color: groceryItems[index].category.color,
           ), 
           trailing:Text(groceryItems[index].quantity.toString()
           ),
          ),
         ),
        );
      }

     if(_error!=null){
      content = Center(child: Text(_error!));
     }

    return Scaffold(
      appBar: AppBar(
        title:const Text('Your Groceries'),
        actions:[
          IconButton(
            onPressed:addItem,
            icon:const Icon(Icons.add),
             )
        ],
      ),
      
      body:content,
    );
  }
}