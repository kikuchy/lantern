class ArgumentParser {
  final String description;
  final List<Argument> arguments = [];

  ArgumentParser({this.description});

  void add(Argument argument) {
    arguments.add(argument);
  }

  void addRequired(String name, {String help}) {
    arguments.add(RequiredArgument(name, help: help));
  }

  void addOptional(
    String name, {
    String help,
    bool required = false,
    String shortenForm,
    String defaultValue,
  }) {
    arguments.add(OptionalArgument(name,
        help: help,
        required: required,
        shortenForm: shortenForm,
        defaultValue: defaultValue));
  }

  ArgumentParseResult parse(List<String> args) {
    final orderSensitives = arguments.where((a) => a.orderSensitive);
    // todo
  }

  String help() {}
}

class ArgumentParseResult {}

abstract class Argument {
  final String name;
  final String help;
  final bool required;
  final bool orderSensitive;

  Argument(
    this.name,
    this.orderSensitive, {
    this.help,
    this.required = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Argument &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          help == other.help &&
          required == other.required &&
          orderSensitive == other.orderSensitive;

  @override
  int get hashCode =>
      name.hashCode ^
      help.hashCode ^
      required.hashCode ^
      orderSensitive.hashCode;
}

class RequiredArgument extends Argument {
  RequiredArgument(
    String name, {
    String help,
  }) : super(
          name,
          true,
          help: help,
          required: true,
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is RequiredArgument &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => super.hashCode;
}

class OptionalArgument extends Argument {
  final String shortenForm;
  final String defaultValue;

  OptionalArgument(String name,
      {String help, bool required = false, this.shortenForm, this.defaultValue})
      : super(name, false, help: help, required: required);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is OptionalArgument &&
          runtimeType == other.runtimeType &&
          shortenForm == other.shortenForm &&
          defaultValue == other.defaultValue;

  @override
  int get hashCode =>
      super.hashCode ^ shortenForm.hashCode ^ defaultValue.hashCode;
}
