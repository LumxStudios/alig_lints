import 'package:flutter/material.dart';

class Sample extends StatelessWidget {
  const Sample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // expect_lint: avoid-missing-controller
        const TextField(),
        // expect_lint: avoid-missing-controller
        TextFormField(),

        TextField(onChanged: (value) {}),
        // expect_lint: avoid-undisposed-instances
        TextField(controller: TextEditingController()),
        TextFormField(onSaved: (value) {}),
      ],
    );
  }
}
