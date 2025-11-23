import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';
import '../models/user_model.dart';

class ChildrenProvider with ChangeNotifier {
  List<ChildModel> _children = [];
  bool _isLoading = false;
  UserModel? _parent;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ChildModel> get children => _children;
  bool get isLoading => _isLoading;
  UserModel? get parent => _parent;

  Future<void> loadChildrenForParent(String parentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('children')
          .where('parentId', isEqualTo: parentId)
          .get();

      _children = snapshot.docs
          .map((doc) => ChildModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error loading children: $e');
      _children = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addChild(ChildModel child) async {
    try {
      // Check if this child is already linked to another parent
      DocumentSnapshot existingChild = await _firestore.collection('children').doc(child.childId).get();

      if (existingChild.exists) {
        // Child already exists, update the parent ID
        await _firestore.collection('children').doc(child.childId).update({
          'parentId': child.parentId,
          'linkedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new child
        await _firestore.collection('children').doc(child.childId).set({
          'childId': child.childId,
          'childName': child.childName,
          'parentId': child.parentId,
          'deviceId': child.deviceId,
          'deviceName': child.deviceName,
          'isActive': child.isActive,
          'createdAt': FieldValue.serverTimestamp(),
          'linkedAt': FieldValue.serverTimestamp(),
        });
      }

      // Refresh the list
      await loadChildrenForParent(child.parentId);
    } catch (e) {
      if (kDebugMode) print('Error adding child: $e');
      rethrow;
    }
  }

  Future<void> updateChild(ChildModel updatedChild) async {
    try {
      await _firestore
          .collection('children')
          .doc(updatedChild.childId) // Assuming childId is the document ID
          .update(updatedChild.toMap());
          
      // Refresh the list
      await loadChildrenForParent(updatedChild.parentId);
    } catch (e) {
      if (kDebugMode) print('Error updating child: $e');
      rethrow;
    }
  }

  Future<void> removeChild(String childId, String parentId) async {
    try {
      await _firestore.collection('children').doc(childId).delete();
      
      // Refresh the list
      await loadChildrenForParent(parentId);
    } catch (e) {
      if (kDebugMode) print('Error removing child: $e');
      rethrow;
    }
  }

  // Get a child by ID
  ChildModel? getChildById(String childId) {
    try {
      return _children.firstWhere((child) => child.childId == childId);
    } catch (e) {
      return null; // Return null if not found
    }
  }

  // Get parent information for a child
  Future<UserModel?> getParentForChild(String childId) async {
    try {
      // First find the child record to get the parentId
      DocumentSnapshot childDoc = await _firestore.collection('children').doc(childId).get();
      
      if (childDoc.exists) {
        final childData = childDoc.data() as Map<String, dynamic>;
        final parentId = childData['parentId'] as String?;
        
        if (parentId != null) {
          // Get parent user information
          DocumentSnapshot parentDoc = await _firestore.collection('users').doc(parentId).get();
          
          if (parentDoc.exists) {
            final parentData = parentDoc.data() as Map<String, dynamic>;
            _parent = UserModel.fromMap(parentData);
            notifyListeners();
            return _parent;
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting parent for child: $e');
      return null;
    }
  }

  // Get children linked to a parent
  Future<List<ChildModel>> getChildrenForParent(String parentId) async {
    await loadChildrenForParent(parentId);
    return _children;
  }

  // Clear parent data (useful when switching users)
  void clearParentData() {
    _parent = null;
    _children = [];
    notifyListeners();
  }
}