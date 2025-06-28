import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension GoRouterExtension on GoRouter{
  void clearStackAndNavigate(BuildContext context, String location){
    while(context.canPop()){
      context.pop();
    }
    context.pushReplacement(location);
  }
}