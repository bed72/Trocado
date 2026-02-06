// import 'package:flutter/widgets.dart';

// import 'package:trocado/src/data/dtos/balance_dto.dart';

// import 'package:trocado/src/presentation/widgets/home/balance/balance_widget.dart';
// import 'package:trocado/src/presentation/widgets/home/transaction/transaction_widget.dart';
// import 'package:trocado/src/presentation/widgets/skeletons/skeleton_widget.dart';

// class HomeTransactionLoadingWidget extends StatelessWidget {
//   const HomeTransactionLoadingWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SliverToBoxAdapter(
//       child: SkeletonWidget(
//         child: Column(
//           children: .generate(
//             10,
//             (_) => TransactionWidget(
//               model: .empty(),
//               onPress: (_) {},
//               onDelete: (_) {},
//               format: (_) => '',
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class HomeBalanceLoadingWidget extends StatelessWidget {
//   const HomeBalanceLoadingWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SkeletonWidget(
//       child: Column(
//         spacing: 16.0,
//         children: [
//           BalanceWidget(
//             isSelected: false,
//             onPress: (value) {},
//             model: BalanceDto.empty(label: 'Total', amount: 1.000),
//           ),
//           Row(
//             spacing: 16.0,
//             children: [
//               Expanded(
//                 child: BalanceWidget(
//                   isSelected: false,
//                   onPress: (value) {},
//                   model: BalanceDto.empty(
//                     type: .income,
//                     label: 'Receita',
//                     amount: 100.000,
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: BalanceWidget(
//                   isSelected: false,
//                   onPress: (value) {},
//                   model: BalanceDto.empty(
//                     amount: 1.000,
//                     type: .expense,
//                     label: 'Despesa',
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
