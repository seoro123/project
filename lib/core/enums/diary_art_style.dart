enum DiaryArtStyle {
  comicsLd('comics_ld'),
  comicsSd('comics_sd'),
  animeLd('anime_ld'),
  animeSd('anime_sd'),
  realistic3d('realistic_3d'),
  simple2d('simple_2d');

  const DiaryArtStyle(this.value);

  final String value;

  static DiaryArtStyle fromValue(String value) {
    return DiaryArtStyle.values.firstWhere(
      (DiaryArtStyle style) => style.value == value,
      orElse: () => DiaryArtStyle.comicsLd,
    );
  }
}
