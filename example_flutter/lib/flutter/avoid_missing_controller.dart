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
        TextField(controller: TextEditingController()),
        TextFormField(onSaved: (value) {}),
      ],
    );
  }
}
