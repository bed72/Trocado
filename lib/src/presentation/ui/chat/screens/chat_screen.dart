import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/ui/chat/notifiers/chat_intent.dart';
import 'package:trocado/src/presentation/ui/chat/notifiers/chat_notifier.dart';
import 'package:trocado/src/presentation/ui/chat/widgets/chat_empty_widget.dart';
import 'package:trocado/src/presentation/ui/chat/widgets/chat_messages_widget.dart';
import 'package:trocado/src/presentation/ui/chat/widgets/chat_text_field_widget.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: AppBarWidget(leading: GoBackWidget()),
      child: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(chatProvider);

          return Column(
            crossAxisAlignment: .start,
            children: [
              const Padding(
                padding: .symmetric(horizontal: 16.0, vertical: 24.0),
                child: ScreenHeaderWidget(
                  title: 'Chat',
                  description: 'Tire dúvidas sobre seus gastos e orçamentos.',
                ),
              ),
              Expanded(
                child: state.messages.isEmpty
                    ? const ChatEmptyWidget()
                    : ChatMessagesWidget(
                        messages: state.messages,
                        isPolling: state.status == .polling,
                      ),
              ),
              ChatTextFieldWidget(
                enabled: !state.isProcessing,
                onChanged: (value) => ref
                    .read(chatProvider.notifier)
                    .dispatch(MessageChanged(value)),
                onSend: () => ref
                    .read(chatProvider.notifier)
                    .dispatch(const SendPressed()),
              ),
            ],
          );
        },
      ),
    );
  }
}
