import 'models/achievement.dart';

class AchievementRegistry {
  static const List<Achievement> all = [
    // Speed & Time
    Achievement(
      id: 'speed_1',
      title: 'Blink and Miss',
      description: 'Find an exact match in under 3 seconds.',
      category: AchievementCategory.speed,
    ),
    Achievement(
      id: 'speed_2',
      title: 'Buzzer Beater',
      description: 'Find an exact match with less than 1 second remaining.',
      category: AchievementCategory.speed,
    ),
    Achievement(
      id: 'speed_5',
      title: 'Hyper-Speed',
      description: 'Find an exact match in under 5 seconds during a Speed Demon round.',
      category: AchievementCategory.speed,
    ),
    Achievement(
      id: 'speed_6',
      title: 'Thinking Cap',
      description: 'Solve 5 rounds in a single match in under 15 seconds each.',
      category: AchievementCategory.speed,
      isHidden: false,
    ),

    // Precision & Constraint
    Achievement(
      id: 'precision_1',
      title: 'Minimalist',
      description: 'Find an exact match using exactly 2 numbers.',
      category: AchievementCategory.precision,
    ),
    Achievement(
      id: 'precision_2',
      title: 'The Architect',
      description: 'Find an exact match using all 6 numbers.',
      category: AchievementCategory.precision,
    ),
    Achievement(
      id: 'precision_3',
      title: 'No Additives',
      description: 'Find an exact match without using the "+" operator.',
      category: AchievementCategory.precision,
    ),
    Achievement(
      id: 'precision_4',
      title: 'Subtractive Thinking',
      description: 'Find an exact match using only the "-" operator.',
      category: AchievementCategory.precision,
    ),
    Achievement(
      id: 'precision_5',
      title: 'Prime Directive',
      description: 'Find an exact match where all intermediate results are prime numbers.',
      category: AchievementCategory.precision,
    ),
    Achievement(
      id: 'precision_6',
      title: 'Bracket Buster',
      description: 'Find an exact match using 3 or more levels of nested brackets.',
      category: AchievementCategory.precision,
    ),

    // Endurance & Grind
    Achievement(
      id: 'endurance_1',
      title: 'The Marathon',
      description: 'Reach Round 20 in Endless mode.',
      category: AchievementCategory.endurance,
      isHidden: false,
    ),
    Achievement(
      id: 'endurance_2',
      title: 'Centurion',
      description: 'Play 100 total matches.',
      category: AchievementCategory.endurance,
      isHidden: false,
    ),
    Achievement(
      id: 'endurance_3',
      title: 'Survivor',
      description: 'Win an Endless match after having only 1 life left for 5 rounds.',
      category: AchievementCategory.endurance,
    ),
    Achievement(
      id: 'endurance_4',
      title: 'Night Owl',
      description: 'Win a match between 12 AM and 4 AM.',
      category: AchievementCategory.endurance,
    ),
    Achievement(
      id: 'endurance_5',
      title: 'Daily Grind',
      description: 'Play Kalkra for 3 consecutive days.',
      category: AchievementCategory.endurance,
      isHidden: false,
    ),

    // Quirky & Easter Eggs
    Achievement(
      id: 'quirky_1',
      title: 'The Void',
      description: 'Submit an expression that equals 0.',
      category: AchievementCategory.quirky,
    ),
    Achievement(
      id: 'quirky_2',
      title: 'Mad Scientist',
      description: 'Try to divide by zero.',
      category: AchievementCategory.quirky,
    ),
    Achievement(
      id: 'quirky_3',
      title: 'Answer to Life',
      description: 'Submit an expression that equals exactly 42.',
      category: AchievementCategory.quirky,
    ),
    Achievement(
      id: 'quirky_4',
      title: 'Jackpot',
      description: 'Submit an expression that equals exactly 777.',
      category: AchievementCategory.quirky,
    ),
    Achievement(
      id: 'quirky_5',
      title: 'Identity Crisis',
      description: 'Submit an expression that is just a single number from the pool.',
      category: AchievementCategory.quirky,
    ),
    Achievement(
      id: 'quirky_6',
      title: 'Overachiever',
      description: 'Submit an expression that is exactly 1000 units away from the target.',
      category: AchievementCategory.quirky,
    ),

    // Multiplayer
    Achievement(
      id: 'multiplayer_1',
      title: 'Social Butterfly',
      description: 'Play a match with 4 or more players.',
      category: AchievementCategory.multiplayer,
      isHidden: false,
    ),
    Achievement(
      id: 'multiplayer_2',
      title: 'Giant Slayer',
      description: 'Beat a player with at least 200 more ELO than you.',
      category: AchievementCategory.multiplayer,
    ),
    Achievement(
      id: 'speed_7',
      title: 'Light Speed',
      description: 'Find an exact match in under 1.5 seconds.',
      category: AchievementCategory.speed,
    ),
    Achievement(
      id: 'speed_8',
      title: 'Consistent Pulse',
      description: 'Solve 3 rounds in a row with less than 0.5s difference in solve times.',
      category: AchievementCategory.speed,
    ),

    // Precision & Constraint
    Achievement(
      id: 'precision_7',
      title: 'Power of Two',
      description: 'Find an exact match using only 2s and 4s.',
      category: AchievementCategory.precision,
    ),
    Achievement(
      id: 'precision_8',
      title: 'Division Bell',
      description: 'Find an exact match using at least three "/" operations.',
      category: AchievementCategory.precision,
    ),
    Achievement(
      id: 'precision_9',
      title: 'Symmetry',
      description: 'Submit a palindromic expression (e.g., 1 + 2 + 1).',
      category: AchievementCategory.precision,
    ),
    Achievement(
      id: 'precision_10',
      title: 'Perfect 10',
      description: 'Win 10 rounds with exactly 0 proximity.',
      category: AchievementCategory.precision,
      isHidden: false,
    ),

    // Endurance & Grind
    Achievement(id: 'win_1', title: 'First Blood', description: 'Win your first match.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'win_10', title: 'Seasoned', description: 'Win 10 matches.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'win_50', title: 'Veteran', description: 'Win 50 matches.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'win_100', title: 'Champion', description: 'Win 100 matches.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'win_500', title: 'Legend', description: 'Win 500 matches.', category: AchievementCategory.endurance, isHidden: false),
    
    Achievement(id: 'elo_1300', title: 'Bronze Tier', description: 'Reach 1300 ELO.', category: AchievementCategory.multiplayer, isHidden: false),
    Achievement(id: 'elo_1400', title: 'Silver Tier', description: 'Reach 1400 ELO.', category: AchievementCategory.multiplayer, isHidden: false),
    Achievement(id: 'elo_1500', title: 'Gold Tier', description: 'Reach 1500 ELO.', category: AchievementCategory.multiplayer, isHidden: false),
    Achievement(id: 'elo_1600', title: 'Platinum Tier', description: 'Reach 1600 ELO.', category: AchievementCategory.multiplayer, isHidden: false),
    Achievement(id: 'elo_1800', title: 'Diamond Tier', description: 'Reach 1800 ELO.', category: AchievementCategory.multiplayer, isHidden: false),
    Achievement(id: 'elo_2000', title: 'Master Tier', description: 'Reach 2000 ELO.', category: AchievementCategory.multiplayer, isHidden: false),
    Achievement(id: 'elo_2500', title: 'Kalkra God', description: 'Reach 2500 ELO.', category: AchievementCategory.multiplayer, isHidden: false),

    // Quirky & Easter Eggs
    Achievement(
      id: 'quirky_7',
      title: 'Binary Code',
      description: 'Win a round using only 1s and 0s in your expression.',
      category: AchievementCategory.quirky,
    ),
    Achievement(
      id: 'quirky_8',
      title: 'The Developer',
      description: 'Submit "666" as your expression value.',
      category: AchievementCategory.quirky,
    ),
    Achievement(
      id: 'quirky_9',
      title: 'Pi Day',
      description: 'Submit an expression that equals 314.',
      category: AchievementCategory.quirky,
    ),
    Achievement(id: 'pts_1k', title: 'Novice Calculator', description: 'Accumulate 1,000 total career points.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'pts_10k', title: 'Advanced Calculator', description: 'Accumulate 10,000 total career points.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'pts_100k', title: 'Grand Calculator', description: 'Accumulate 100,000 total career points.', category: AchievementCategory.endurance),
    Achievement(id: 'pts_1m', title: 'The Human Computer', description: 'Accumulate 1,000,000 total career points.', category: AchievementCategory.endurance),

    Achievement(id: 'exact_1', title: 'Sniper', description: 'Get 1 exact match.', category: AchievementCategory.precision, isHidden: false),
    Achievement(id: 'exact_10', title: 'Marksman', description: 'Get 10 total exact matches.', category: AchievementCategory.precision, isHidden: false),
    Achievement(id: 'exact_50', title: 'Sharpshooter', description: 'Get 50 total exact matches.', category: AchievementCategory.precision, isHidden: false),
    Achievement(id: 'exact_100', title: 'Eagle Eye', description: 'Get 100 total exact matches.', category: AchievementCategory.precision),
    Achievement(id: 'exact_500', title: 'Deadshot', description: 'Get 500 total exact matches.', category: AchievementCategory.precision),
    Achievement(id: 'exact_1000', title: 'Aim Bot', description: 'Get 1,000 total exact matches.', category: AchievementCategory.precision),

    Achievement(id: 'streak_3', title: 'On Fire', description: 'Get 3 exact matches in a row.', category: AchievementCategory.speed, isHidden: false),
    Achievement(id: 'streak_5', title: 'Unstoppable', description: 'Get 5 exact matches in a row.', category: AchievementCategory.speed),
    Achievement(id: 'streak_10', title: 'Godlike', description: 'Get 10 exact matches in a row.', category: AchievementCategory.speed),
    
    Achievement(id: 'nums_even', title: 'Even Steven', description: 'Find an exact match using only even numbers.', category: AchievementCategory.precision),
    Achievement(id: 'nums_odd', title: 'Odd One Out', description: 'Find an exact match using only odd numbers.', category: AchievementCategory.precision),
    Achievement(id: 'nums_asc', title: 'Ascending Order', description: 'Use numbers in strictly increasing order in your expression.', category: AchievementCategory.quirky),
    Achievement(id: 'nums_desc', title: 'Descending Order', description: 'Use numbers in strictly decreasing order in your expression.', category: AchievementCategory.quirky),

    Achievement(id: 'round_10', title: 'Double Digits', description: 'Reach Round 10 in a single match.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'round_20', title: 'Scoreboard Leader', description: 'Reach Round 20 in a single match.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'round_50', title: 'Endless Echo', description: 'Reach Round 50 in Endless mode.', category: AchievementCategory.endurance),

    Achievement(id: 'action_clear', title: 'Fresh Start', description: 'Clear your expression 100 times.', category: AchievementCategory.quirky, isHidden: false),
    Achievement(id: 'action_backspace', title: 'Second Thoughts', description: 'Use backspace 500 times.', category: AchievementCategory.quirky, isHidden: false),
    Achievement(id: 'action_theme', title: 'Fashionista', description: 'Change your visual theme 10 times.', category: AchievementCategory.quirky, isHidden: false),
    
    Achievement(id: 'time_early', title: 'Early Bird', description: 'Win a match before 8 AM.', category: AchievementCategory.endurance),
    Achievement(id: 'time_lunch', title: 'Lunch Break', description: 'Play a match between 12 PM and 1 PM.', category: AchievementCategory.endurance, isHidden: false),
    
    // Fillers to hit 100+ (Variations of existing themes)
    Achievement(id: 'win_2', title: 'Double Win', description: 'Win 2 matches.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'win_5', title: 'High Five', description: 'Win 5 matches.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'win_25', title: 'Quarter Century', description: 'Win 25 matches.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'win_250', title: 'Major Player', description: 'Win 250 matches.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'win_1000', title: 'The Ultimate Champion', description: 'Win 1,000 matches.', category: AchievementCategory.endurance),

    Achievement(id: 'elo_1350', title: 'Bronze II', description: 'Reach 1350 ELO.', category: AchievementCategory.multiplayer),
    Achievement(id: 'elo_1450', title: 'Silver II', description: 'Reach 1450 ELO.', category: AchievementCategory.multiplayer),
    Achievement(id: 'elo_1550', title: 'Gold II', description: 'Reach 1550 ELO.', category: AchievementCategory.multiplayer),
    Achievement(id: 'elo_1650', title: 'Platinum II', description: 'Reach 1650 ELO.', category: AchievementCategory.multiplayer),
    Achievement(id: 'elo_1750', title: 'Platinum III', description: 'Reach 1750 ELO.', category: AchievementCategory.multiplayer),
    Achievement(id: 'elo_1900', title: 'Diamond II', description: 'Reach 1900 ELO.', category: AchievementCategory.multiplayer),
    Achievement(id: 'elo_2100', title: 'Grandmaster', description: 'Reach 2100 ELO.', category: AchievementCategory.multiplayer),
    Achievement(id: 'elo_3000', title: 'The Singularity', description: 'Reach 3000 ELO.', category: AchievementCategory.multiplayer),

    Achievement(id: 'exact_25', title: 'Elite Marksman', description: 'Get 25 total exact matches.', category: AchievementCategory.precision, isHidden: false),
    Achievement(id: 'exact_75', title: 'Deadeye', description: 'Get 75 total exact matches.', category: AchievementCategory.precision, isHidden: false),
    Achievement(id: 'exact_250', title: 'True Sniper', description: 'Get 250 total exact matches.', category: AchievementCategory.precision, isHidden: false),
    
    Achievement(id: 'speed_deep_1', title: 'Sub-Second', description: 'Find an exact match in under 1.0 second.', category: AchievementCategory.speed),
    Achievement(id: 'op_plus_100', title: 'Addict', description: 'Use the "+" operator 100 times.', category: AchievementCategory.quirky, isHidden: false),
    Achievement(id: 'op_minus_100', title: 'Subtracter', description: 'Use the "-" operator 100 times.', category: AchievementCategory.quirky, isHidden: false),
    Achievement(id: 'op_times_100', title: 'Multiplier', description: 'Use the "*" operator 100 times.', category: AchievementCategory.quirky, isHidden: false),
    Achievement(id: 'op_divide_100', title: 'Divider', description: 'Use the "/" operator 100 times.', category: AchievementCategory.quirky, isHidden: false),
    
    Achievement(id: 'nums_primes', title: 'Prime Time', description: 'Find an exact match using only prime numbers from the pool.', category: AchievementCategory.precision),
    Achievement(id: 'nums_squares', title: 'Perfect Square', description: 'Find an exact match using only perfect squares.', category: AchievementCategory.precision),
    
    Achievement(id: 'career_1yr', title: 'Anniversary', description: 'Play Kalkra 1 year after your first match.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'career_100hr', title: 'Kalkra Addict', description: 'Spend 100 hours in-game.', category: AchievementCategory.endurance),
    
    Achievement(id: 'multi_streak_3', title: 'Arena King', description: 'Win 3 multiplayer matches in a row.', category: AchievementCategory.multiplayer, isHidden: false),
    Achievement(id: 'multi_streak_10', title: 'Arena Emperor', description: 'Win 10 multiplayer matches in a row.', category: AchievementCategory.multiplayer),
    
    Achievement(id: 'target_1', title: 'The Beginning', description: 'Submit an expression that equals 1.', category: AchievementCategory.quirky, isHidden: false),
    Achievement(id: 'target_999', title: 'The Peak', description: 'Submit an expression that equals 999.', category: AchievementCategory.quirky, isHidden: false),
    
    Achievement(id: 'sol_100', title: 'Solution Seeker', description: 'Submit 100 valid expressions.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'sol_1000', title: 'Math Professor', description: 'Submit 1,000 valid expressions.', category: AchievementCategory.endurance, isHidden: false),
    Achievement(id: 'sol_10000', title: 'The Calculator Reborn', description: 'Submit 10,000 valid expressions.', category: AchievementCategory.endurance),
    
    Achievement(id: 'exact_near_miss', title: 'Heartbreak', description: 'Get a proximity of 1 in 10 consecutive rounds.', category: AchievementCategory.quirky),
    Achievement(id: 'exact_first_try', title: 'Instinct', description: 'Get an exact match on your first submission of the day.', category: AchievementCategory.speed, isHidden: false),
    
    Achievement(id: 'secret_dev', title: 'Binary God', description: 'Unlock all other achievements.', category: AchievementCategory.quirky),
  ];
  
  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
