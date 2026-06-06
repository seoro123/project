enum DiaryGenre {
  dailyComic('daily_comic'),
  serious('serious'),
  fantasyAction('fantasy_action'),
  healingRomance('healing_romance'),
  growth('growth'),
  hardDay('hard_day');

  const DiaryGenre(this.value);

  final String value;

  static DiaryGenre fromValue(String value) {
    return DiaryGenre.values.firstWhere(
      (DiaryGenre genre) => genre.value == value,
      orElse: () => DiaryGenre.dailyComic,
    );
  }
}
