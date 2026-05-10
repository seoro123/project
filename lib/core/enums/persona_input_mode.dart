enum PersonaInputMode {
  prose('prose'),
  tags('tags');

  const PersonaInputMode(this.value);

  final String value;

  static PersonaInputMode fromValue(String value) {
    return PersonaInputMode.values.firstWhere(
      (PersonaInputMode mode) => mode.value == value,
      orElse: () => PersonaInputMode.prose,
    );
  }
}
