enum WebtoonFormat {
  cardSlide('card_slide'),
  imageFocus('image_focus'),
  qaSlide('qa_slide'),
  reactionFocus('reaction_focus');

  const WebtoonFormat(this.value);

  final String value;

  static WebtoonFormat fromValue(String value) {
    return WebtoonFormat.values.firstWhere(
      (WebtoonFormat format) => format.value == value,
      orElse: () => WebtoonFormat.cardSlide,
    );
  }
}
