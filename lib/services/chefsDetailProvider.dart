import 'dart:async';
import 'package:maps/diners/storecomponents/store.dart';
import 'package:maps/models/itemListingModel.dart';
import 'package:maps/chefs/chef.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerDetailsProvider extends ChangeNotifier {
  bool isDataLoaded = false;
  Stream<QuerySnapshot> ordersStream,availableItemStream;
  FirebaseUser user;
  Seller seller;
  Store store;

  SellerDetailsProvider(){ 
    init();
  }


  init()async{
   
    await _getUser();
    await _initUserDetails();
    _initOrdersStream();

    isDataLoaded= true;
    notifyListeners();
  }

  _initUserDetails()async{
    var userDetails = (await Firestore.instance.collection('chefs').document(user.uid).get()).data;
    var storeDetails = (await Firestore.instance.collection('stores').document(userDetails['storeId']).get()).data;

     this.seller = Seller(
      name: userDetails['name'],
      phno2: userDetails['phno2'],
      phno1: userDetails['phno1'],
      storeId: userDetails['storeId'],
      uid: userDetails['uid'],

    );
    this.store = Store(
      location: List<double>.from( storeDetails['location']),
      description: storeDetails['description'],
      id: storeDetails['id'],
      name:storeDetails['name'],
      contact: storeDetails['phno'],
      
    ); 

  }

  _initOrdersStream(){
    ordersStream = Firestore.instance.collection('chefs').document(user.uid).collection('orders').snapshots();
  }

  getAvailableItemStream(int category){
    String storeId = this.seller.storeId;
    availableItemStream = Firestore.instance.collection('stores').document(storeId).collection(getCollectionNameFromCategory(category: category)).snapshots();
    print(getCollectionNameFromCategory(category: category));
    return availableItemStream;
  }

  _getUser()async{
    user = await FirebaseAuth.instance.currentUser();
  }
  
  addToAvailableItems({ItemListingModel itemListingModel,int category}){
    String collectionName;
    switch(category){
      case 1:collectionName = 'Breakfast';
              break;
      case 2:collectionName = 'Brunch';
              break;
      case 3: collectionName = 'Lunch';
              break;
      case 4: collectionName = 'Dinner';
              break;
      default : collectionName = '';
              break;

    }
     if(collectionName==''){
      print('select from choices 1 to 4');
    }
    
    Firestore.instance.collection('stores').document(seller.storeId).collection(collectionName).add({
      'itemName':itemListingModel.itemName,
      'price':itemListingModel.itemPrice
    });
  }
  
  getCollectionNameFromCategory({@required int category}){
    String collectionName;
      switch(category){
        case 1:collectionName = 'Breakfast';
                break;
        case 2:collectionName = 'Brunch';
                break;
        case 3: collectionName = 'Lunch';
                break;
        case 4: collectionName = 'Dinner';
                break;
        default : collectionName = '';
                break;

      }
       if(collectionName==''){
      print('select from choices 1 to 4');
    }
      return collectionName;
    }

  removeAvailableItem({ItemListingModel itemListingModel,int category})async {
    String collectionName;
    switch(category){
      case 1:collectionName = 'Breakfast';
              break;
      case 2:collectionName = 'Brunch';
              break;
      case 3: collectionName = 'Lunch';
              break;
      case 4: collectionName = 'Dinner';
              break;
      default : collectionName = '';
              break;

    }
   
    var docs =await Firestore.instance.collection('stores').document(seller.storeId).collection(collectionName)
      .where('itemName',isEqualTo: itemListingModel.itemName).getDocuments();
      
    for (DocumentSnapshot ds in docs.documents){
      ds.reference.delete();
    }
  }
}
