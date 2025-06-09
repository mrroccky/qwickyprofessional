// lib/widgets/field_boxes.dart
import 'package:flutter/material.dart';
import 'package:qwickyprofessional/widgets/colors.dart';

class FieldBoxes extends StatelessWidget {
  final TextEditingController? controller1;
  final TextEditingController? controller2;
  final String label1;
  final String? label2;
  final IconData? icon1;
  final IconData? icon2;
  final String? Function(String?)? validator1;
  final String? Function(String?)? validator2;
  final TextInputType? keyboardType1;
  final TextInputType? keyboardType2;
  final bool isDoubleField;
  final int? maxLines1;
  final int? maxLines2;
  final Widget? suffixIcon1;
  final bool obscureText1;
  final bool isDropdown1;
  final List<String>? dropdownItems1;
  final String? dropdownValue1;
  final ValueChanged<String?>? onDropdownChanged1;
  final String? Function(String?)? dropdownValidator1;
  final bool readOnly1;
  final bool readOnly2;

  const FieldBoxes({
    super.key,
    this.controller1,
    this.controller2,
    required this.label1,
    this.label2,
    this.icon1,
    this.icon2,
    this.validator1,
    this.validator2,
    this.keyboardType1,
    this.keyboardType2,
    this.isDoubleField = false,
    this.maxLines1 = 1,
    this.maxLines2 = 1,
    this.suffixIcon1,
    this.obscureText1 = false,
    this.isDropdown1 = false,
    this.dropdownItems1,
    this.dropdownValue1,
    this.onDropdownChanged1,
    this.dropdownValidator1,
    this.readOnly1 = false,
    this.readOnly2 = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    if (isDoubleField) {
      return Padding(
        padding: EdgeInsets.only(left: height * 0.02, right: height * 0.02),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildField(
                context,
                controller: controller1,
                label: label1,
                icon: icon1,
                validator: validator1,
                keyboardType: keyboardType1,
                maxLines: maxLines1,
                suffixIcon: suffixIcon1,
                obscureText: obscureText1,
                isDropdown: isDropdown1,
                dropdownItems: dropdownItems1,
                dropdownValue: dropdownValue1,
                onDropdownChanged: onDropdownChanged1,
                dropdownValidator: dropdownValidator1,
                readOnly: readOnly1,
              ),
            ),
            SizedBox(width: height * 0.02),
            Expanded(
              flex: 1,
              child: _buildField(
                context,
                controller: controller2,
                label: label2 ?? '',
                icon: icon2,
                validator: validator2,
                keyboardType: keyboardType2,
                maxLines: maxLines2,
                readOnly: readOnly2,
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(left: height * 0.02, right: height * 0.02),
        child: _buildField(
          context,
          controller: controller1,
          label: label1,
          icon: icon1,
          validator: validator1,
          keyboardType: keyboardType1,
          maxLines: maxLines1,
          suffixIcon: suffixIcon1,
          obscureText: obscureText1,
          isDropdown: isDropdown1,
          dropdownItems: dropdownItems1,
          dropdownValue: dropdownValue1,
          onDropdownChanged: onDropdownChanged1,
          dropdownValidator: dropdownValidator1,
          readOnly: readOnly1,
        ),
      );
    }
  }

  Widget _buildField(
    BuildContext context, {
    TextEditingController? controller,
    required String label,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
    Widget? suffixIcon,
    bool obscureText = false,
    bool isDropdown = false,
    List<String>? dropdownItems,
    String? dropdownValue,
    ValueChanged<String?>? onDropdownChanged,
    String? Function(String?)? dropdownValidator,
    bool readOnly = false,
  }) {
    final inputDecoration = InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.black) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderColor),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: label.contains('(optional)')
          ? TextStyle(color: AppColors.borderColor)
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    );

    if (isDropdown) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            constraints: const BoxConstraints(minHeight: 48),
            child: DropdownButtonFormField<String>(
              value: dropdownValue,
              decoration: inputDecoration,
              items: dropdownItems?.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth - 80),
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.02,
                        height: 1.4,
                      ),
                      strutStyle: StrutStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.02,
                        height: 1.4,
                        leading: 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: readOnly ? null : onDropdownChanged,
              validator: dropdownValidator,
              selectedItemBuilder: (context) {
                return dropdownItems!.map((item) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth - 80),
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.02,
                        height: 1.4,
                      ),
                      strutStyle: StrutStyle(
                        fontSize: MediaQuery.of(context).size.height * 0.02,
                        height: 1.4,
                        leading: 0.5,
                      ),
                    ),
                  );
                }).toList();
              },
              menuMaxHeight: 200,
              isExpanded: true,
            ),
          );
        },
      );
    }

    return TextFormField(
      controller: controller,
      decoration: inputDecoration,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      readOnly: readOnly,
    );
  }
}