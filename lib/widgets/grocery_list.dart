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
late Future<List<GroceryItem>>_loadedItems;

 @override
  void initState(){
    super.initState();
    _loadedItems =_loadItems();
  }

Future<List<GroceryItem>> _loadItems()async{
  final url = Uri.https('flutter-prep-664a7-default-rtdb.firebaseio.com','shopping_list.json');

    final response = await http.get(url);
  
    if(response.statusCode>=400){
          throw Exception('Failed to fetch grocery items. Please try again later.');   
     }

   if(response.body=='null'){
    return [];
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
    return loadedItems;
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
    return Scaffold(
      appBar: AppBar(
        title:const Text('Your Groceries'),
        actions:[
          IconButton(
            onPressed:addItem,
            icon:const Icon(Icons.add),
             ), 
          ],
      ),
      
      body:FutureBuilder(
        future:_loadedItems,
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
              return const Center(child: CircularProgressIndicator(),
            );
          }
          if(snapshot.hasError){
              return Center(child: Text(snapshot.error.toString()));
            }
          if(snapshot.data!.isEmpty){
            return const Center(child: Text('No items added yet.'),);
          }
          return ListView.builder(
          itemCount:snapshot.data!.length,
          itemBuilder:(ctx,index) => Dismissible(
          onDismissed:(direction){
            removeItem(snapshot.data![index]);
          },
          key:ValueKey (snapshot.data![index].id), 
          child: ListTile(
          title: Text(snapshot.data![index].name),
          leading: Container(
            width: 24,
            height: 24,
            color: snapshot.data![index].category.color,
           ), 
           trailing:Text(snapshot.data![index].quantity.toString()
           ),
          ),
         ),
        );
       },
      ),
    );
  }
}