import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/ChatMessageModel.dart';
import '../utils/Constants.dart';
import 'BaseServices.dart';

class ChatMessageService extends BaseService {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;

  late CollectionReference rideChatRef;

  ChatMessageService() {
    ref = fireStore.collection(MESSAGES_COLLECTION);
    rideChatRef = fireStore.collection(RIDE_CHAT);
  }

  Query chatMessagesWithPagination({String? riderId, required String driverID, required int filter_msg}) {
    return ref!.doc("${riderId}_${driverID}").collection("chats").orderBy("createdAt", descending: true);
  }

  Query rideSpecificChatMessagesWithPagination({required String rideId}) {
    return rideChatRef.doc(rideId).collection("messages").orderBy("createdAt", descending: true);
  }

  Future<bool> isRideChatHistory({required String rideId}) async {
    QuerySnapshot<Map<String, dynamic>> b = await rideChatRef.doc(rideId).collection("messages").get();
    if (b.docs.isEmpty) {
      return false;
    }
    return true;
  }

  Future<DocumentReference> addMessage(ChatMessageModel data) async {
    var doc2 = await ref!.doc("${data.senderId}_${data.receiverId}").collection("chats").add(data.toJson());
    doc2.update({'id': doc2.id});
    return doc2;
  }

  Future<void> deleteSingleMessage({String? riderID, required String driverID, String? documentId}) async {
    try {
      final chatDocRef = ref!.doc("${riderID}_${driverID}").collection("chats").doc(documentId);
      await chatDocRef.update({'deleted': true});
    } on Exception catch (e) {
      log(e.toString());
      throw 'Something went wrong';
    }
  }

  Future<void> setUnReadStatusToTrue({required String riderID, required String driverID, String? documentId}) async {
    ref!.doc("${riderID}_${driverID}").collection("chats").where('senderId', isNotEqualTo: riderID).get().then((value) {
      value.docs.forEach((element) {
        element.reference.update({
          'isMessageRead': true,
        });
      });
    });

    return;
  }

  Future<bool> justDeleteChat({
    required String senderId,
    required String receiverId,
  }) async {
    print("Check CHAT ROOM Id:::${senderId}_${receiverId}");
    try {
      var documentPath = "${senderId}_${receiverId}";
      CollectionReference collectionRef = ref!.doc(documentPath).collection("chats");
      QuerySnapshot querySnapshot = await collectionRef.get();
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      await ref!.doc(documentPath).delete();
      return true;
    } catch (e, s) {
      print("FailDelete Operation::$e ::::$s");
      return false;
    }
  }

  Stream<int> getUnReadCount({String? senderId, required String receiverId, String? documentId}) {
    print("CHekYourUSErId::${senderId}:::$receiverId");
    return ref!
        .doc("${senderId}_${receiverId}")
        .collection("chats")
        .where('isMessageRead', isEqualTo: false)
        .where('receiverId', isEqualTo: senderId)
        .snapshots()
        .map(
          (event) => event.docs.length,
        )
        .handleError((e) {
      return e;
    });
  }
}
